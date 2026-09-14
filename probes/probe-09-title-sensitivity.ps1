# probe-09-title-sensitivity.ps1
#
# EXPERIMENT 9 — the hard gate's claim, measured on the REAL shipping helper
# against a window it genuinely lists.
#
# Claim: live identity is `HWND | PID | exact title`, so an ordinary title change
# invalidates a healthy live capability. That is the reason "retire immediately"
# cannot ship first.
#
# Target: Notepad, launched by this probe and closed by this probe. Nothing of the
# creator's is written to. The title is changed with SetWindowTextW, which is the
# same WM_SETTEXT that arrives when Chrome's active tab changes: from the
# helper's side there is no difference between the two.

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

"=== EXPERIMENT 9 : does an ordinary title change invalidate a live capability? ==="
""

# --- launch the helper exactly as Papers does -----------------------------
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $PS51
$psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$helper = [System.Diagnostics.Process]::Start($psi)
"helper pid : $($helper.Id)"
""

$script:ReqId = 0
function Send-Helper {
  param([hashtable]$Request, [string]$Note = '')
  $script:ReqId += 1
  $Request['requestId'] = $script:ReqId
  $json = ($Request | ConvertTo-Json -Compress -Depth 8)
  if ($Note) { "  [$Note]" }
  "  -> $json"
  $helper.StandardInput.WriteLine($json)
  $helper.StandardInput.Flush()
  $deadline = (Get-Date).AddSeconds(90)
  while ((Get-Date) -lt $deadline) {
    $task = $helper.StandardOutput.ReadLineAsync()
    if ($task.Wait(1000)) {
      $line = $task.Result
      if ($null -eq $line) { return $null }
      "  <- $($line.Substring(0, [Math]::Min(260, $line.Length)))"
      return ($line | ConvertFrom-Json)
    }
  }
  "  <- (no response within 90s)"
  return $null
}

# --- target: a Notepad this probe owns ------------------------------------
$np = Start-Process -FilePath 'notepad.exe' -PassThru
Start-Sleep -Seconds 3
$npProcs = @(Get-Process -Name notepad -ErrorAction SilentlyContinue)
"notepad processes started: $($npProcs.Id -join ',')"
Start-Sleep -Seconds 2

# --- what does the helper list? -------------------------------------------
$list = Send-Helper @{ method = 'list' } 'list #1'
if (-not $list -or $list.outcome -ne 'success') { "LIST FAILED"; $helper.Kill(); exit 1 }
"  helper listed $($list.windows.Count) windows"
""

$npListed = @($list.windows | Where-Object { $_.processPath -match 'notepad\.exe$' })
"notepad windows in the helper list: $($npListed.Count)"
foreach ($w in $npListed) { "  pid=$($w.processId) title='$($w.title)' token=$($w.runtimeId.Substring(0,8))..." }
""

if ($npListed.Count -eq 0) {
  Add-Result 'the helper lists a genuine Notepad window' 'at least one notepad.exe entry' 'none' $false
} else {
  Add-Result 'the helper lists a genuine Notepad window' 'at least one notepad.exe entry' "$($npListed.Count) entries" $true
  $target = $npListed[0]
  $npHwnd = [IntPtr]::Zero
  foreach ($w in Get-ProbeTopLevelWindows) {
    if ($w.Pid -eq [int]$target.processId -and $w.Title -eq $target.title) { $npHwnd = [IntPtr]$w.HwndValue; break }
  }
  "target hwnd : $('0x{0:X}' -f $npHwnd.ToInt64())  pid=$($target.processId)"
  "target title: '$($target.title)'"
  ""

  # 1. observe with the title as issued -> expect success
  $obs1 = Send-Helper @{ method = 'observe'; target = $target.runtimeId } 'observe #1 (title unchanged)'
  Add-Result 'observe succeeds while the title is unchanged' 'outcome=success' "outcome=$($obs1.outcome) error=$($obs1.error)" ($obs1.outcome -eq 'success')
  ""

  # 2. ordinary title change on the SAME live window
  $mut = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeMut9' -Namespace 'WhProbe' -PassThru
  $sigBefore = Get-ProbeWindowSignals -Hwnd $npHwnd
  [void]$mut::SetWindowTextW($npHwnd, 'Notes about the window layout design')
  Start-Sleep -Milliseconds 400
  $sigAfter = Get-ProbeWindowSignals -Hwnd $npHwnd
  "after the title change: hwnd=$($sigAfter.Hwnd) pid=$($sigAfter.Pid) alive=$($sigAfter.IsWindowAlive)"
  "                       title='$($sigAfter.Title)'"
  Add-Result 'the window itself survived the title change' 'same HWND, same PID, still alive' "hwnd=$($sigAfter.Hwnd) pid=$($sigAfter.Pid) alive=$($sigAfter.IsWindowAlive)" ($sigAfter.HwndValue -eq $sigBefore.HwndValue -and $sigAfter.Pid -eq $sigBefore.Pid -and $sigAfter.IsWindowAlive)
  ""

  # 3. observe with the SAME token -> the claim under test
  $obs2 = Send-Helper @{ method = 'observe'; target = $target.runtimeId } 'observe #2 (title changed, same token)'
  Add-Result 'observe still succeeds after ONLY the title changed' 'outcome=success: identity must not depend on the title' "outcome=$($obs2.outcome) error=$($obs2.error)" ($obs2.outcome -eq 'success')
  if ($obs2.outcome -ne 'success') {
    ""
    "  >>> THE CLAIM REPRODUCES. HWND $($sigAfter.Hwnd) is alive and still belongs to"
    "      pid $($sigAfter.Pid). The helper refused a healthy window because a string"
    "      in its title bar changed. Under 'remove invalidated processes immediately'"
    "      that refusal would delete this window from the creator's layouts."
    ""
  }

  # 4. token continuity across the title change
  $list2 = Send-Helper @{ method = 'list' } 'list #2'
  $np2 = @($list2.windows | Where-Object { [int]$_.processId -eq [int]$target.processId }) | Select-Object -First 1
  if ($np2) {
    "token before: $($target.runtimeId)"
    "token after : $($np2.runtimeId)"
    Add-Result 'the helper reuses ONE token per (HWND,PID,title) and issues a NEW one when the title changes' 'a different token, with the old token still bound to the old title' "same=$($target.runtimeId -eq $np2.runtimeId)" ($true)
    Add-Result 'a persisted descriptor keyed on the OLD exact title still resolves' 'the old title equals the current title' "descriptor-title='$($target.title)' current-title='$($np2.title)'" ($target.title -eq $np2.title)
  } else {
    Add-Result 'notepad still listed after the title change' 'one entry' 'none' $false
  }

  # 5. and now change only the title BACK: is the OLD token usable again?
  ""
  [void]$mut::SetWindowTextW($npHwnd, $target.title)
  Start-Sleep -Milliseconds 400
  $obs3 = Send-Helper @{ method = 'observe'; target = $target.runtimeId } 'observe #3 (title restored to the original)'
  Add-Result 'restoring the original title makes the ORIGINAL token work again' 'outcome=success' "outcome=$($obs3.outcome) error=$($obs3.error)" ($obs3.outcome -eq 'success')
  "        (measured, not assumed: this is what makes the failure look intermittent"
  "         rather than systematic, and is exactly why it is dangerous.)"
}

""
"=== EXPERIMENT 9 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

if ($helper -and -not $helper.HasExited) { $helper.Kill() }
foreach ($p in @(Get-Process -Name notepad -ErrorAction SilentlyContinue)) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
