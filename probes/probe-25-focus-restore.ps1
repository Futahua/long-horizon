# probe-25-focus-restore.ps1
#
# EXPERIMENT 25 — can we put focus BACK on a specific window on demand, and what
# does the answer actually look like?
#
# The overlay must take focus to accept typing and must give it back exactly.
# Windows' foreground lock decides this, and the rules differ by who is in front,
# so the only useful answer comes from running it.
#
# Method: launch three different foreground applications (Notepad, Chrome, and a
# Papers-owned window), make each the foreground window, then ask the SHIPPING
# window helper to raise a recorded target and observe where focus lands. The
# helper is the only native foreground path Papers owns today.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$CLIENT = Join-Path $PSScriptRoot 'helper-client.mjs'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

# A foreground observer: one reading per invocation, at a known instant.
$observerPath = Join-Path $PSScriptRoot '_fg-observer.ps1'
@'
Add-Type -TypeDefinition @"
using System; using System.Text; using System.Runtime.InteropServices;
public class FgObs {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern uint GetWindowThreadProcessId(IntPtr h, out uint p);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
}
"@
$h = [FgObs]::GetForegroundWindow()
$t = New-Object System.Text.StringBuilder 512; [void][FgObs]::GetWindowTextW($h, $t, $t.Capacity)
$c = New-Object System.Text.StringBuilder 256; [void][FgObs]::GetClassNameW($h, $c, $c.Capacity)
$p = [uint32]0; [void][FgObs]::GetWindowThreadProcessId($h, [ref]$p)
$proc = try { (Get-Process -Id ([int]$p) -ErrorAction Stop).ProcessName } catch { '<gone>' }
"fg_pid=$p fg_proc=$proc fg_class=$($c.ToString()) fg_hwnd=$('0x{0:X}' -f $h.ToInt64()) fg_title=$($t.ToString())"
'@ | Set-Content -Path $observerPath -Encoding utf8

function Get-Foreground {
  $out = & $PS51 -NoProfile -NonInteractive -File $observerPath 2>&1 | Out-String
  return $out.Trim()
}

function Get-HelperList {
  $out = & node $CLIENT $HELPER $PS51 'list' 2>&1
  foreach ($line in $out) {
    $s = [string]$line
    if ($s.StartsWith('RESP ')) { try { return ($s.Substring(5) | ConvertFrom-Json) } catch { } }
  }
  return $null
}

function Invoke-HelperRaise {
  param([string]$Token)
  $out = & node $CLIENT $HELPER $PS51 "restore:$Token" 2>&1
  foreach ($line in $out) {
    $s = [string]$line
    if ($s.StartsWith('RESP ')) { try { return ($s.Substring(5) | ConvertFrom-Json) } catch { } }
  }
  return $null
}

"=== EXPERIMENT 25 : can focus be handed back to a specific window? ==="
"observer: $observerPath"
""
"baseline foreground: $(Get-Foreground)"
""

# ---------------------------------------------------------------------------
# The three foreground applications.
# ---------------------------------------------------------------------------
"--- establishing three different foreground applications ---"
$targets = @()

$np = Start-Process -FilePath 'notepad.exe' -PassThru
$npWin = $null
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 250
  $w = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $np.Id }) | Select-Object -First 1
  if ($w) { $npWin = $w; break }
}
if (-not $npWin) { $npWin = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'notepad\.exe$' }) | Select-Object -First 1 }
"notepad      : $(if ($npWin) { "hwnd=$($npWin.Hwnd) pid=$($npWin.Pid)" } else { '<none>' })"
if ($npWin) { $targets += [pscustomobject]@{ Name = 'Notepad'; Hwnd = [IntPtr]$npWin.HwndValue; Pid = $npWin.Pid } }

$chrome = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'chrome\.exe$' }) | Select-Object -First 1
"chrome       : $(if ($chrome) { "hwnd=$($chrome.Hwnd) pid=$($chrome.Pid) title='$($chrome.Title)'" } else { '<none>' })"
if ($chrome) { $targets += [pscustomobject]@{ Name = 'Chrome'; Hwnd = [IntPtr]$chrome.HwndValue; Pid = $chrome.Pid } }

$papers = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'Papers\.exe$' }) | Select-Object -First 1
"papers       : $(if ($papers) { "hwnd=$($papers.Hwnd) pid=$($papers.Pid)" } else { '<none>' })"
if ($papers) { $targets += [pscustomobject]@{ Name = 'Papers'; Hwnd = [IntPtr]$papers.HwndValue; Pid = $papers.Pid } }
""

Add-Result 'three distinct foreground applications are available to test against' 'at least three targets' "targets=$($targets.Count): $(($targets | ForEach-Object { $_.Name }) -join ', ')" ($targets.Count -ge 3)
""

# ---------------------------------------------------------------------------
# Try to make each one foreground using the helper's Raise, and observe.
# ---------------------------------------------------------------------------
"--- raising each target through the shipping helper ---"
foreach ($t in $targets) {
  "  target $($t.Name) (pid=$($t.Pid) hwnd=$('0x{0:X}' -f $t.Hwnd.ToInt64()))"
  $before = Get-Foreground
  "    before : $before"

  # The helper's list gives us a token for the window; tokens do not cross
  # helper processes, so list and mutate happen in ONE invocation.
  $plan = 'list'
  $out = & node $CLIENT $HELPER $PS51 $plan 2>&1
  $listed = $null
  foreach ($line in $out) {
    $s = [string]$line
    if ($s.StartsWith('RESP ')) { try { $listed = ($s.Substring(5) | ConvertFrom-Json) } catch { } }
  }
  $entry = if ($listed) { @($listed.windows | Where-Object { [int]$_.processId -eq $t.Pid }) | Select-Object -First 1 } else { $null }
  if (-not $entry) {
    "    not in the helper's list; cannot be raised by token"
    Add-Result "raise $($t.Name)" 'a helper-listed window' 'not listed by the helper (task-worthiness or ownership)' $false
    continue
  }

  # `restore` is the helper method that calls Raise (BringWindowToTop +
  # SetForegroundWindow) - the only native foreground path Papers owns.
  $raiseOut = & node $CLIENT $HELPER $PS51 "list,restore:$($entry.runtimeId)" 2>&1 | Out-String
  $raised = $raiseOut -match '"outcome":"success"'
  Start-Sleep -Milliseconds 800
  $after = Get-Foreground
  "    after  : $after"
  "    helper : $(if ($raised) { 'restore reported success' } else { ($raiseOut -split "`r?`n" | Where-Object { $_ -match 'RESP ' } | Select-Object -First 1) })"
  $moved = $after -match "fg_pid=$($t.Pid)\b"
  Add-Result "focus moves to $($t.Name) when the helper restores it" "fg_pid=$($t.Pid)" $after $moved
}
""

"=== EXPERIMENT 25 NOTE ==="
"  A 'raise' that does NOT move the foreground is the Windows foreground lock"
"  refusing a background process, which is the documented behaviour and the"
"  reason a launcher must take focus through the user's own keypress rather"
"  than by asking for it."

"=== EXPERIMENT 25 RESULTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

foreach ($p in @(Get-Process -Name notepad -ErrorAction SilentlyContinue)) {
  $cim = Get-CimInstance Win32_Process -Filter "ProcessId=$($p.Id)" -ErrorAction SilentlyContinue
  if ($cim -and $cim.CreationDate -gt (Get-Date).AddMinutes(-10)) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
}
Remove-Item $observerPath -Force -ErrorAction SilentlyContinue
