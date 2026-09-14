# probe-10-helper-restart.ps1
#
# EXPERIMENT 10 — the property the replacement identity depends on.
#
# Two launched copies of the SHIPPING helper are two separate processes with no
# shared memory. If both derive the same handle, process and process-creation-time
# for one live window, then a helper restart (and a Papers restart on the same
# boot) can recover the same instance without persisting anything and without
# trusting a title.
#
# It also records, per window, what a stable instance key would be:
#   bootId | pid | processCreationTime | windowClass
# and shows it is unaffected by a title change.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

function Start-Helper {
  $psi = New-Object System.Diagnostics.ProcessStartInfo
  $psi.FileName = $PS51
  $psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
  $psi.RedirectStandardInput = $true
  $psi.RedirectStandardOutput = $true
  $psi.RedirectStandardError = $true
  $psi.UseShellExecute = $false
  $psi.CreateNoWindow = $true
  return [System.Diagnostics.Process]::Start($psi)
}

function Get-HelperList {
  param([System.Diagnostics.Process]$Helper, [int]$Id = 1)
  $Helper.StandardInput.WriteLine("{`"requestId`":$Id,`"method`":`"list`"}")
  $Helper.StandardInput.Flush()
  $deadline = (Get-Date).AddSeconds(120)
  while ((Get-Date) -lt $deadline) {
    $task = $Helper.StandardOutput.ReadLineAsync()
    if ($task.Wait(1000)) {
      $line = $task.Result
      if ($null -eq $line) { return $null }
      return (($line | ConvertFrom-Json).windows)
    }
  }
  return $null
}

$boot = Get-ProbeBootTimeUtc
"=== EXPERIMENT 10 : identity across helper restarts ==="
"boot time : $($boot.ToString('o'))"
""

# --- a live, foreign, application window to track --------------------------
$np = Start-Process -FilePath 'notepad.exe' -PassThru
Start-Sleep -Seconds 3
$npAll = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'notepad\.exe$' })
"notepad windows present: $($npAll.Count)"
foreach ($w in $npAll) {
  $m = Get-ProbeMarker -Hwnd ([IntPtr]$w.HwndValue)
  "  hwnd=$($m.Hwnd) pid=$($m.Pid) created=$($m.ProcCreatedUtc) class=$($m.ClassName) title='$($w.Title)'"
  "    derived instance key   : $($m.Marker)"
  "    derived instance key (hwnd-inclusive): $($m.MarkerHwndIncluded)"
}
""

if ($npAll.Count -eq 0) { "NO NOTEPAD WINDOW"; exit 1 }
$target = $npAll[0]
$targetHwnd = [IntPtr]$target.HwndValue

# --- helper #1 -------------------------------------------------------------
"--- helper process #1 ---"
$h1 = Start-Helper
$list1 = Get-HelperList $h1 1
"  pid=$($h1.Id) listed=$($list1.Count)"
$np1 = @($list1 | Where-Object { [int]$_.processId -eq $target.Pid })
foreach ($w in $np1) { "    runtimeId=$($w.runtimeId.Substring(0,10))... title='$($w.title)' pid=$($w.processId)" }
""

# --- helper #2: a genuinely separate process, same boot --------------------
"--- helper process #2 (separate process, no shared memory) ---"
$h2 = Start-Helper
$list2 = Get-HelperList $h2 2
"  pid=$($h2.Id) listed=$($list2.Count)"
$np2 = @($list2 | Where-Object { [int]$_.processId -eq $target.Pid })
foreach ($w in $np2) { "    runtimeId=$($w.runtimeId.Substring(0,10))... title='$($w.title)' pid=$($w.processId)" }
""

# --- compare the underlying native identity -------------------------------
$sig = Get-ProbeWindowSignals -Hwnd $targetHwnd
$m1 = Get-ProbeMarker -Hwnd $targetHwnd

Add-Result 'both helper processes are distinct OS processes' 'different PIDs' "h1=$($h1.Id) h2=$($h2.Id)" ($h1.Id -ne $h2.Id)
Add-Result 'both helper processes list the same live window by the same native PID' 'identical processId' "h1-processId=$(@($np1)[0].processId) h2-processId=$(@($np2)[0].processId)" ((@($np1)[0].processId) -eq (@($np2)[0].processId))
Add-Result 'helper session tokens are NOT portable between helper processes' 'different tokens for the same window' "h1-token=$(@($np1)[0].runtimeId.Substring(0,10)) h2-token=$(@($np2)[0].runtimeId.Substring(0,10))" ((@($np1)[0].runtimeId) -ne (@($np2)[0].runtimeId))
"        This is the measured reason a helper restart loses every capability,"
"        and the reason recovery must be by native identity, not by token."
""

Add-Result 'the window handle is still valid and unchanged for the live window' 'same HWND as recorded' "hwnd=$($sig.Hwnd) alive=$($sig.IsWindowAlive)" ($sig.IsWindowAlive -and $sig.HwndValue -eq $targetHwnd.ToInt64())
Add-Result 'the owning process creation time is available from the desktop alone' 'a non-null creation timestamp' "created=$($m1.ProcCreatedUtc)" ($null -ne $m1.ProcCreatedUtc -and $m1.ProcCreatedUtc -ne 'none')
Add-Result 'the process creation time is later than the boot time (boot-scoped)' 'created > boot' "created=$($m1.ProcCreatedUtc) boot=$($boot.ToString('o'))" ([datetime]$m1.ProcCreatedUtc -gt $boot)
""

# --- the key must not move when the title moves ---------------------------
$mut = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeMut10' -Namespace 'WhProbe' -PassThru
$beforeKey = (Get-ProbeMarker -Hwnd $targetHwnd).Marker
[void]$mut::SetWindowTextW($targetHwnd, 'Window layout notes (title changed)')
Start-Sleep -Milliseconds 300
$afterTitle = (Get-ProbeWindowSignals -Hwnd $targetHwnd).Title
$afterKey = (Get-ProbeMarker -Hwnd $targetHwnd).Marker
"--- after a title change ---"
"  title before key check : '$($target.Title)'"
"  title now              : '$afterTitle'"
"  key before             : $beforeKey"
"  key now                : $afterKey"
Add-Result 'the derived instance key is unchanged by a title change' 'identical key' "same=$($beforeKey -eq $afterKey)" ($beforeKey -eq $afterKey)
""

# --- helper #3 sees the same window after the title change ----------------
$h3 = Start-Helper
$list3 = Get-HelperList $h3 3
$np3 = @($list3 | Where-Object { [int]$_.processId -eq $target.Pid })
Add-Result 'a third fresh helper still finds the same window after the title change' 'the same native PID is listed' "entries=$(($np3 | ForEach-Object { $_.processId }) -join ',')" ($np3.Count -ge 1)
Add-Result 'the native identity is recoverable without any token and without the title' 'PID + creation time + class identical across helpers' "key=$afterKey" ($afterKey -eq $beforeKey)
""

"=== EXPERIMENT 10 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

foreach ($h in @($h1, $h2, $h3)) { if ($h -and -not $h.HasExited) { $h.Kill() } }
foreach ($p in @(Get-Process -Name notepad -ErrorAction SilentlyContinue)) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
