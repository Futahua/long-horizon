# probe-19-acceptance-exercise.ps1
#
# EXPERIMENT 19 — the acceptance exercise, driven through the REAL shipping
# helper over its own protocol plus the full identity scope, on the applications
# the design names.
#
# Targets: Chrome (two windows of one process where present), Obsidian, VS Code,
# Notepad, and a hosted/packaged target to find where EnumWindows stops.
#
# Drives: title mutation (on probe-owned windows only), helper restart,
# close/recreate churn, PID churn, HWND churn, and scope stability over time.
# Records what REFUSED and what the refusal looked like, not only what passed.
#
# The helper is driven by node (helper-client.mjs), exactly as Papers spawns it.
# PowerShell's Process stdin/stdout plumbing was measured unreliable for this
# (probe-20): an instrument that reports "denied" because its own pipe broke is
# worse than no instrument.

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

# Drive the helper once per invocation: one request, one response, process exits.
# Slower than a long-lived pipe and immune to the pipe class of instrument defect.
function Invoke-Helper {
  param([string]$Plan, [int]$TimeoutSec = 120)
  $out = & node $CLIENT $HELPER $PS51 $Plan 2>&1
  $responses = @()
  foreach ($line in $out) {
    $s = [string]$line
    if ($s.StartsWith('RESP ')) {
      try { $responses += ($s.Substring(5) | ConvertFrom-Json) } catch { }
    }
  }
  return $responses
}

"=== EXPERIMENT 19 : acceptance exercise ==="
"OS build : $(Get-ProbeBuildNumber)"
"helper   : $HELPER"
"driver   : node helper-client.mjs (child_process.spawn with stdio pipes, as Papers does)"
""

# ---------------------------------------------------------------------------
# Targets
# ---------------------------------------------------------------------------
"--- targets present ---"
foreach ($n in @('chrome', 'Obsidian', 'Code', 'notepad', 'SystemSettings')) {
  $procs = @(Get-Process -Name $n -ErrorAction SilentlyContinue)
  "  {0,-16} {1} process(es)" -f $n, $procs.Count
}
""

$all = @(Get-ProbeTopLevelWindows)
"probe sees $($all.Count) visible top-level windows"

$resp = Invoke-Helper -Plan 'list'
$listed = if ($resp.Count -gt 0 -and $resp[0].outcome -eq 'success') { @($resp[0].windows) } else { @() }
Add-Result 'the helper answers a list request through the node driver' 'outcome=success with windows' "outcome=$($resp[0].outcome) windows=$($listed.Count)" ($listed.Count -gt 0)
"  helper lists $($listed.Count) windows"
""

# ---------------------------------------------------------------------------
# A. Identity scope for every named application window
# ---------------------------------------------------------------------------
"--- A. identity scope per real application window ---"
$namedApps = 'chrome\.exe$|Obsidian\.exe$|Code\.exe$|notepad\.exe$|SystemSettings\.exe$'
$named = @($all | Where-Object { $_.ProcessPath -match $namedApps })
$rows = @()
foreach ($w in $named) {
  $scope = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$w.HwndValue)).Scope
  $rows += [pscustomobject]@{
    Exe = Split-Path $w.ProcessPath -Leaf
    Pid = $scope.pid
    Hwnd = $scope.hwnd
    Class = if ($scope.className.Length -gt 30) { $scope.className.Substring(0,30) } else { $scope.className }
    Sess = $scope.sessionId
    Incarnation = $scope.incarnationSource
    CreatedReadable = ($null -ne $scope.processCreatedUtc)
    Listed = (@($listed | Where-Object { [int]$_.processId -eq $scope.pid }).Count -gt 0)
  }
}
$rows | Format-Table -AutoSize | Out-String -Width 280 | Write-ProbeLine
$noCreate = @($rows | Where-Object { -not $_.CreatedReadable })
Add-Result 'the full scope is readable for every named application window' 'no window with an unreadable creation time' "windows=$($rows.Count) unreadable=$($noCreate.Count)" ($rows.Count -gt 0 -and $noCreate.Count -eq 0)
""

# ---------------------------------------------------------------------------
# B. Two top-level windows of one process: the ambiguity case
# ---------------------------------------------------------------------------
"--- B. two top-level windows of one process ---"
$byPid = @($all | Where-Object { $_.ProcessPath } | Group-Object Pid | Where-Object { $_.Count -gt 1 })
$multi = @($byPid | Where-Object { $_.Group[0].ProcessPath -match $namedApps })
if ($multi.Count -gt 0) {
  foreach ($g in $multi) {
    $exe = Split-Path $g.Group[0].ProcessPath -Leaf
    $scopes = @()
    foreach ($w in $g.Group) { $scopes += (Get-ProbeIdentityScope -Hwnd ([IntPtr]$w.HwndValue)).Scope }
    $withoutHwnd = @($scopes | ForEach-Object { "$($_.bootId)|$($_.pid)|$($_.processCreatedUtc)|$($_.className)" } | Select-Object -Unique)
    $withHwnd = @($scopes | ForEach-Object { "$($_.hwnd)|$($_.pid)|$($_.processCreatedUtc)|$($_.className)" } | Select-Object -Unique)
    "  $exe pid=$($g.Name): $($g.Count) windows $(($g.Group | ForEach-Object { $_.Hwnd }) -join ',')"
    "    keys without HWND: $($withoutHwnd.Count)   with HWND: $($withHwnd.Count)"
    Add-Result "the HWND is required to separate $exe's windows in one process" 'HWND-free keys collapse' "without=$($withoutHwnd.Count) with=$($withHwnd.Count) windows=$($g.Count)" ($withoutHwnd.Count -lt $withHwnd.Count)
  }
} else {
  Add-Result 'two top-level windows of one process are present to measure' 'at least one multi-window application process' 'none present at this moment' $false
  "        Round one measured this on this same Chrome with a second window open."
  "        Recorded as not-present now, not as passed."
}
""

# ---------------------------------------------------------------------------
# C. Title mutation, on a probe-owned window, through the real helper
# ---------------------------------------------------------------------------
"--- C. title mutation through the real helper ---"
$np = Start-Process -FilePath 'notepad.exe' -PassThru
Start-Sleep -Seconds 3
$npWin = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $np.Id }) | Select-Object -First 1
if (-not $npWin) {
  Add-Result 'a probe-owned application window to retitle' 'one notepad window' 'none' $false
} else {
  $npHwnd = [IntPtr]$npWin.HwndValue
  $before = (Get-ProbeIdentityScope -Hwnd $npHwnd).Scope
  $listA = Invoke-Helper -Plan 'list'
  $entryA = @($listA[0].windows | Where-Object { [int]$_.processId -eq $np.Id }) | Select-Object -First 1
  "  notepad pid=$($np.Id) hwnd=$($npWin.Hwnd) title='$($npWin.Title)'"
  "  helper token   : $($entryA.runtimeId)"
  $obs1 = Invoke-Helper -Plan "observe:$($entryA.runtimeId)"
  "  observe (title unchanged)      : outcome=$($obs1[0].outcome)"
  Add-Result 'observe succeeds while the title is unchanged' 'outcome=success' "outcome=$($obs1[0].outcome) error=$($obs1[0].error)" ($obs1[0].outcome -eq 'success')

  $mut = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeMut19' -Namespace 'WhProbe' -PassThru
  [void]$mut::SetWindowTextW($npHwnd, 'Round two acceptance (title mutated)')
  Start-Sleep -Milliseconds 400
  $after = (Get-ProbeIdentityScope -Hwnd $npHwnd).Scope
  "  after title mutation: hwnd=$($after.hwnd) pid=$($after.pid) alive=$(if ($after.alive) {'True'} else {'False'}) title='$($after.title)'"
  $obs2 = Invoke-Helper -Plan "observe:$($entryA.runtimeId)"
  "  observe (title changed)        : outcome=$($obs2[0].outcome) error=$($obs2[0].error)"
  Add-Result 'the helper refuses the SAME live window after only its title changed' 'outcome=denied, identity changed' "outcome=$($obs2[0].outcome) error=$($obs2[0].error)" ($obs2[0].outcome -ne 'success')
  Add-Result 'the window itself is still alive and unchanged apart from its title' 'same HWND, same PID, alive, new title' "hwnd=$($after.hwnd) pid=$($after.pid) alive=$($after.alive)" ($after.alive -and $after.hwnd -eq $before.hwnd -and $after.pid -eq $before.pid)

  $check = Get-ProbeIdentityScope -Hwnd $npHwnd -Expected $before
  Add-Result 'the identity SCOPE is unaffected by the title change' 'Verified=true: the scope does not include the title' "Verified=$($check.Verified) mismatches=$($check.Mismatches.Count)" ($check.Verified -eq $true)
  "        The refusal and the scope disagree, which is the whole point: the scope"
  "        says 'same window', the helper says 'identity changed'."
  Stop-Process -Id $np.Id -Force -ErrorAction SilentlyContinue
}
""

# ---------------------------------------------------------------------------
# D. Helper restart: native scope survives, tokens do not
# ---------------------------------------------------------------------------
"--- D. helper restart ---"
$beforeR = Invoke-Helper -Plan 'list'
$pidsBefore = @($beforeR[0].windows | ForEach-Object { [int]$_.processId } | Sort-Object -Unique)
$tokensBefore = @($beforeR[0].windows | ForEach-Object { $_.runtimeId } | Select-Object -First 5)
$afterR = Invoke-Helper -Plan 'list'
$pidsAfter = @($afterR[0].windows | ForEach-Object { [int]$_.processId } | Sort-Object -Unique)
$tokensAfter = @($afterR[0].windows | ForEach-Object { $_.runtimeId })
$survived = @($pidsBefore | Where-Object { $pidsAfter -contains $_ })
$tokenOverlap = @($tokensBefore | Where-Object { $tokensAfter -contains $_ })
"  listed: before=$($pidsBefore.Count) after=$($pidsAfter.Count)  surviving pids=$($survived.Count)"
"  token overlap between the two helper processes: $($tokenOverlap.Count) of $($tokensBefore.Count) sampled"
Add-Result 'the same live windows are identified by a fresh helper process' 'most PIDs still listed' "survived=$($survived.Count) of $($pidsBefore.Count)" ($survived.Count -ge [Math]::Max(1, $pidsBefore.Count - 3))
Add-Result 'helper session tokens do NOT survive a helper restart' 'zero token overlap' "overlap=$($tokenOverlap.Count)" ($tokenOverlap.Count -eq 0)
""

# ---------------------------------------------------------------------------
# E. PID churn and HWND churn
# ---------------------------------------------------------------------------
"--- E. PID churn and HWND churn (probe-owned notepads) ---"
$churn = @()
foreach ($round in 1..4) {
  $p = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Seconds 2
  $w = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $p.Id }) | Select-Object -First 1
  if ($w) {
    $s = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$w.HwndValue)).Scope
    $churn += [pscustomobject]@{
      Round = $round; Pid = $s.pid; Hwnd = $s.hwnd
      CreatedTail = if ($s.processCreatedUtc) { $s.processCreatedUtc.Substring(11, 12) } else { '<null>' }
    }
  }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
}
$churn | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
Add-Result 'each restart incarnation produces a distinct PID or creation time' 'no two rounds share an identity scope' "distinct scopes=$(@($churn | ForEach-Object { "$($_.Pid)|$($_.CreatedTail)" } | Select-Object -Unique).Count) of $($churn.Count)" ((@($churn | ForEach-Object { "$($_.Pid)|$($_.CreatedTail)" } | Select-Object -Unique).Count) -eq $churn.Count)
Add-Result 'HWND churn: distinct handles across incarnations' 'distinct handles per round' "distinct hwnds=$(@($churn | ForEach-Object { $_.Hwnd } | Select-Object -Unique).Count) of $($churn.Count)" ((@($churn | ForEach-Object { $_.Hwnd } | Select-Object -Unique).Count) -eq $churn.Count)
""

# ---------------------------------------------------------------------------
# F. The hosted / packaged boundary
# ---------------------------------------------------------------------------
"--- F. hosted / packaged application boundary ---"
$settings = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath -match 'SystemSettings\.exe$' })
$frames = @(Get-ProbeTopLevelWindows | Where-Object { $_.ClassName -match 'ApplicationFrameWindow|CoreWindow' })
"  SystemSettings.exe windows visible to EnumWindows : $($settings.Count)"
"  ApplicationFrameWindow / CoreWindow windows       : $($frames.Count)"
foreach ($w in $settings) { "    hwnd=$($w.Hwnd) class=$($w.ClassName) title='$($w.Title)'" }
foreach ($w in $frames) { "    frame hwnd=$($w.Hwnd) class=$($w.ClassName) pid=$($w.Pid) title='$($w.Title)'" }
$settingsListed = @($listed | Where-Object { $_.processPath -match 'SystemSettings\.exe$' })
"  SystemSettings.exe entries in the helper list     : $($settingsListed.Count)"
if ($settings.Count -gt 0) {
  $s = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$settings[0].HwndValue)).Scope
  Add-Result 'a packaged application window is visible AND scoped' 'present with pid, class, session, creation' "pid=$($s.pid) class=$($s.className) session=$($s.sessionId) created=$($s.processCreatedUtc)" ($s.pid -gt 0 -and $null -ne $s.processCreatedUtc)
  Add-Result 'the packaged window is listed by the helper' 'a matching helper entry' "$($settingsListed.Count) entries" ($settingsListed.Count -gt 0)
} else {
  Add-Result 'a packaged application window is visible to EnumWindows' 'at least one SystemSettings window' 'none - boundary stays UNVERIFIED' $false
  "        Recorded as UNVERIFIED. EnumWindows on Win8+ enumerates"
  "        desktop-application top-level windows; this probe does not claim it"
  "        proves the absence of every Windows surface class, only that no"
  "        SystemSettings window was present to measure."
}
""

# ---------------------------------------------------------------------------
# G. Scope stability over time (stand-in for suspend/resume)
# ---------------------------------------------------------------------------
"--- G. scope stability over a delay ---"
$hold = Start-Process -FilePath 'notepad.exe' -PassThru
Start-Sleep -Seconds 3
$holdWin = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $hold.Id }) | Select-Object -First 1
if ($holdWin) {
  $s1 = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$holdWin.HwndValue)).Scope
  "  enrolled: hwnd=$($s1.hwnd) pid=$($s1.pid) created=$($s1.processCreatedUtc) session=$($s1.sessionId) boot=$($s1.bootId)"
  "  waiting 75s..."
  Start-Sleep -Seconds 75
  $check = Get-ProbeIdentityScope -Hwnd ([IntPtr]$holdWin.HwndValue) -Expected $s1
  $s2 = $check.Scope
  "  re-read : hwnd=$($s2.hwnd) pid=$($s2.pid) created=$($s2.processCreatedUtc) session=$($s2.sessionId) boot=$($s2.bootId)"
  Add-Result 'the scope verifies as identical after a 75s delay' 'Verified=true with nothing unverified' "Verified=$($check.Verified) mismatches=$($check.Mismatches.Count) unverified=$($check.Unverified.Count)" ($check.Verified -eq $true)
  Add-Result 'the boot id is unchanged across the delay' 'same bootId' "before=$($s1.bootId) after=$($s2.bootId)" ($s1.bootId -eq $s2.bootId)
  "        Suspend, hibernate and reboot were NOT performed. A delay is a weaker"
  "        stand-in and is recorded as such, not as coverage of those transitions."
} else {
  Add-Result 'a held window for the delay test' 'one notepad window' 'none' $false
}
Stop-Process -Id $hold.Id -Force -ErrorAction SilentlyContinue
""

"=== EXPERIMENT 19 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
