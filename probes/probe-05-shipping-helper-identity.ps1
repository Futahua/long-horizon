# probe-05-shipping-helper-identity.ps1
#
# EXPERIMENT 5 — the claim the whole hard gate rests on, measured on the REAL
# shipping helper, launched exactly the way Papers launches it:
#
#   powershell.exe -NoProfile -NonInteractive -File resources\window-helper\window-helper.ps1
#
# Claim under test (design section 1.2): identity is `HWND | PID | exact title`,
# so an ordinary title change invalidates a healthy live capability.
#
# The target window is one this probe starts. Nothing of the creator's is
# written to: only `list` and `observe` are ever sent, and observe is read-only.

. "$PSScriptRoot\win-identity-lib.ps1"

$HELPER = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source\resources\window-helper\window-helper.ps1'
$PS51 = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}

function Write-ProbeLine {
  param([string]$Text)
  [Console]::Out.WriteLine($Text)
  [Console]::Out.Flush()
}

"=== EXPERIMENT 5 : the shipping helper's live identity, driven directly ==="
"helper  : $HELPER"
"runtime : $PS51"
"exists  : helper=$(Test-Path $HELPER) runtime=$(Test-Path $PS51)"
""

# --- start the helper exactly as Papers does -------------------------------
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $PS51
$psi.Arguments = "-NoProfile -NonInteractive -File `"$HELPER`""
$psi.RedirectStandardInput = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$helper = [System.Diagnostics.Process]::Start($psi)
"helper pid  : $($helper.Id)"
"helper alive: $(-not $helper.HasExited)"
""

$script:ReqId = 0
function Send-HelperRequest {
  param([hashtable]$Request)
  $script:ReqId += 1
  $Request['requestId'] = $script:ReqId
  $json = ($Request | ConvertTo-Json -Compress -Depth 8)
  Write-ProbeLine "  -> $json"
  $helper.StandardInput.WriteLine($json)
  $helper.StandardInput.Flush()
  $deadline = (Get-Date).AddSeconds(45)
  while ((Get-Date) -lt $deadline) {
    $task = $helper.StandardOutput.ReadLineAsync()
    if ($task.Wait(1000)) {
      $line = $task.Result
      if ($null -eq $line) { return $null }
      Write-ProbeLine "  <- $($line.Substring(0, [Math]::Min(220, $line.Length)))"
      return ($line | ConvertFrom-Json)
    }
  }
  return $null
}

# --- target window ---------------------------------------------------------
$idFile = Join-Path $env:TEMP ('probe-scratch-' + [guid]::NewGuid().ToString('N') + '.txt')
$scratch = Start-Process -FilePath (Get-Process -Id $PID).Path -ArgumentList @('-NoProfile', '-File', $SCRATCH, 'PROBE-HELPER-TARGET', $idFile) -PassThru
$target = $null
for ($i = 0; $i -lt 80; $i++) {
  if (Test-Path $idFile) {
    $reported = (Get-Content $idFile -Raw).Trim()
    if ($reported -match 'HWNDDEC=(\d+)') {
      $target = Get-ProbeWindowSignals -Hwnd ([IntPtr][long]$matches[1])
      break
    }
  }
  Start-Sleep -Milliseconds 250
}

if (-not $target) {
  Add-Result 'probe target window created' 'a visible task-worthy window' 'the window never reported its own handle' $false
} else {
  Add-Result 'probe target window created' 'a visible task-worthy window' "pid=$($target.Pid) hwnd=$($target.Hwnd) class=$($target.ClassName)" $true

  # 1. list -> the helper issues a session token for the window
  $list = Send-HelperRequest @{ method = 'list' }
  if ($list.outcome -ne 'success') {
    Add-Result 'helper list succeeded' 'outcome=success' "$($list | ConvertTo-Json -Compress)" $false
  } else {
    Add-Result 'helper list succeeded' 'outcome=success' "outcome=$($list.outcome) windows=$(@($list.windows).Count)" $true

    $mine = @($list.windows | Where-Object { [int]$_.processId -eq $target.Pid }) | Select-Object -First 1
    if (-not $mine) {
      Add-Result 'the probe target appears in the helper list' 'one listed window for the target pid' "listed pids: $(@($list.windows | ForEach-Object { $_.processId }) -join ',')" $false
    } else {
      Add-Result 'the probe target appears in the helper list' 'one listed window for the target pid' "token=$($mine.runtimeId) title='$($mine.title)'" $true

      # 2. observe before any title change
      $obs1 = Send-HelperRequest @{ method = 'observe'; target = $mine.runtimeId }
      "  observe #1 outcome=$($obs1.outcome)"
      Add-Result 'observe succeeds while the title is unchanged' 'outcome=success' "outcome=$($obs1.outcome) error=$($obs1.error)" ($obs1.outcome -eq 'success')

      # 3. an ordinary title change on the SAME live window (what a Chrome tab switch does)
      $tmp = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeTitleMut5' -Namespace 'WhProbe' -PassThru
      $sigBefore = Get-ProbeWindowSignals -Hwnd ([IntPtr]$target.HwndValue)
      [void]$tmp::SetWindowTextW([IntPtr]$target.HwndValue, 'PROBE-HELPER-TARGET (tab switched)')
      Start-Sleep -Milliseconds 300
      $sigAfter = Get-ProbeWindowSignals -Hwnd ([IntPtr]$target.HwndValue)

      "  hwnd before/after : $($sigBefore.Hwnd) / $($sigAfter.Hwnd)"
      "  pid  before/after : $($sigBefore.Pid) / $($sigAfter.Pid)"
      "  alive before/after: $($sigBefore.IsWindowAlive) / $($sigAfter.IsWindowAlive)"
      Add-Result 'the window really did survive the title change' 'same HWND, same PID, still alive' "hwnd=$($sigAfter.Hwnd) pid=$($sigAfter.Pid) alive=$($sigAfter.IsWindowAlive)" ($sigAfter.HwndValue -eq $sigBefore.HwndValue -and $sigAfter.Pid -eq $sigBefore.Pid -and $sigAfter.IsWindowAlive)

      # 4. observe again with the SAME token
      $obs2 = Send-HelperRequest @{ method = 'observe'; target = $mine.runtimeId }
      "  observe #2 outcome=$($obs2.outcome) error=$($obs2.error)"
      Add-Result 'observe STILL succeeds after only the title changed' 'outcome=success: identity must not depend on the title' "outcome=$($obs2.outcome) error=$($obs2.error)" ($obs2.outcome -eq 'success')

      if ($obs2.outcome -ne 'success') {
        "  >>> THE DESIGN'S CLAIM REPRODUCES: a live, healthy window became unusable"
        "      to the helper because its title changed. HWND $($target.Hwnd) is still alive"
        "      and still belongs to pid $($target.Pid)."
      }

      # 5. list again: does the token survive, or is a new one issued?
      $list2 = Send-HelperRequest @{ method = 'list' }
      $mine2 = @($list2.windows | Where-Object { [int]$_.processId -eq $target.Pid }) | Select-Object -First 1
      "  token after title change : $($mine2.runtimeId)"
      Add-Result 'the helper keeps the SAME token for the same window after a title change' 'token unchanged: token identity is not title-sensitive' "before=$($mine.runtimeId) after=$($mine2.runtimeId)" ($mine.runtimeId -eq $mine2.runtimeId)

      # 6. what a descriptor-based re-resolution would do with the NEW title
      $sigNow = Get-ProbeWindowSignals -Hwnd ([IntPtr]$target.HwndValue)
      "  helper reports title now : '$($mine2.title)'"
      "  helper reports path now  : '$($mine2.processPath)'"
      Add-Result 'a persisted descriptor captured BEFORE the title change still resolves' 'the pre-change title equals the current title' "descriptor-title='$($mine.title)' current-title='$($mine2.title)'" ($mine.title -eq $mine2.title)
    }
  }
}

""
"=== EXPERIMENT 5 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

if ($helper -and -not $helper.HasExited) { $helper.Kill(); "helper stopped" }
if ($scratch -and -not $scratch.HasExited) { Stop-Process -Id $scratch.Id -Force -ErrorAction SilentlyContinue }
Remove-Item $idFile -ErrorAction SilentlyContinue
