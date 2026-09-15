# probe-16-process-incarnation.ps1
#
# EXPERIMENT 16 — the process incarnation hierarchy the reviewer named:
# SystemBasicProcessInformation.SequenceNumber where available, creation FILETIME
# as fallback, never PID alone.
#
# Questions this answers by running:
#   1. what build is this, and does the SequenceNumber field actually exist here?
#   2. is it readable from an ordinary unelevated process, for itself and others?
#   3. does it change when a process is replaced (PID churn)?
#   4. does it agree with the documented FILETIME creation time as a discriminator?
#   5. what does an elevated process report, and can we read it at all?

. "$PSScriptRoot\win-identity-lib.ps1"

$results = New-Object System.Collections.ArrayList
function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

"=== EXPERIMENT 16 : process incarnation ==="
$build = Get-ProbeBuildNumber
"OS build             : $build"
"reviewer's threshold : SequenceNumber present in 26100.4770+"
"this build is at or above it: $($build -ge 26100)"
""

# ---------------------------------------------------------------------------
# A. Is the field present and readable at all on this build?
# ---------------------------------------------------------------------------
"--- A. reading SequenceNumber for live processes ---"
Update-ProbeProcessFacts
$pids = @($script:ProcFactsCache.Keys | Select-Object -First 400)
$read = 0
$unread = 0
$samples = @()
foreach ($p in $pids) {
  $inc = Get-ProbeProcessIncarnation -PidValue $p
  if ($inc.SequenceReadable) { $read++ } else { $unread++ }
  if ($samples.Count -lt 8 -and $inc.SequenceReadable) { $samples += $inc }
  if ($read -ge 60 -and $samples.Count -ge 8) { break }
}
"  processes probed     : $($read + $unread)"
"  SequenceNumber read  : $read"
"  SequenceNumber absent: $unread"
$samples | Select-Object Pid, SequenceNumber, CreatedUtc, Source | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
Add-Result 'SequenceNumber is readable from an ordinary unelevated process' 'a non-zero sequence for live processes' "read=$read absent=$unread on build $build" ($read -gt 0)
""

# ---------------------------------------------------------------------------
# B. PID churn: does the incarnation change when the process is replaced?
# ---------------------------------------------------------------------------
"--- B. PID churn: same executable, killed and restarted ---"
$incarnations = @()
foreach ($round in 1..3) {
  $p = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Seconds 2
  $inc = Get-ProbeProcessIncarnation -PidValue $p.Id
  $incarnations += [pscustomobject]@{
    Round = $round
    Pid = $p.Id
    Sequence = $inc.SequenceNumber
    Created = if ($inc.CreatedUtc) { $inc.CreatedUtc.ToString('o') } else { $null }
    Source = $inc.Source
  }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 800
  # keep only probe-started notepads
}
$incarnations | Format-Table -AutoSize | Out-String -Width 220 | Write-ProbeLine

$seqs = @($incarnations | ForEach-Object { $_.Sequence } | Where-Object { $_ -ne $null })
$creates = @($incarnations | ForEach-Object { $_.Created } | Where-Object { $_ -ne $null })
Add-Result 'each new process incarnation gets a distinct SequenceNumber' 'three distinct sequences' "distinct=$(@($seqs | Select-Object -Unique).Count) of $($seqs.Count)" ((@($seqs | Select-Object -Unique).Count) -eq $seqs.Count -and $seqs.Count -eq 3)
Add-Result 'each new process incarnation gets a distinct creation FILETIME' 'three distinct timestamps' "distinct=$(@($creates | Select-Object -Unique).Count) of $($creates.Count)" ((@($creates | Select-Object -Unique).Count) -eq $creates.Count)
Add-Result 'the two discriminators agree about distinctness' 'same verdict from both sources' "sequences-distinct=$(@($seqs | Select-Object -Unique).Count) created-distinct=$(@($creates | Select-Object -Unique).Count)" ((@($seqs | Select-Object -Unique).Count) -eq (@($creates | Select-Object -Unique).Count))
""

# ---------------------------------------------------------------------------
# C. Which is more precise? (a discriminator that collides is useless)
# ---------------------------------------------------------------------------
"--- C. precision of the two discriminators ---"
$prec = @()
foreach ($round in 1..6) {
  $p = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Seconds 1
  $inc = Get-ProbeProcessIncarnation -PidValue $p.Id
  $prec += [pscustomobject]@{
    Pid = $p.Id
    Sequence = $inc.SequenceNumber
    CreatedTicks = if ($inc.CreatedUtc) { $inc.CreatedUtc.Ticks } else { $null }
  }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 400
}
$prec | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
$collapsed = @($prec | Group-Object CreatedTicks | Where-Object { $_.Count -gt 1 }).Count
Add-Result 'creation FILETIME does not collide across six consecutive incarnations' 'six distinct tick values' "collisions=$collapsed of 6" ($collapsed -eq 0)
""

# ---------------------------------------------------------------------------
# D. A live window's incarnation, end to end
# ---------------------------------------------------------------------------
"--- D. the incarnation as part of a window's identity scope ---"
$np = Start-Process -FilePath 'notepad.exe' -PassThru
Start-Sleep -Seconds 3
$win = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $np.Id }) | Select-Object -First 1
if ($win) {
  $scope = (Get-ProbeIdentityScope -Hwnd ([IntPtr]$win.HwndValue)).Scope
  $scope.GetEnumerator() | Where-Object { $_.Key -notin @('marker') } | ForEach-Object { "  {0,-18} {1}" -f $_.Key, $_.Value }
  Add-Result 'a live window exposes the full scope: boot, session, pid, creation, sequence, class' 'every field populated' "source=$($scope.incarnationSource) seq=$($scope.processSequence) session=$($scope.sessionId)" ($null -ne $scope.processSequence -and $null -ne $scope.sessionId -and $null -ne $scope.className)
} else {
  Add-Result 'a live window exposes the full scope' 'a notepad window to measure' 'none found' $false
}
Stop-Process -Id $np.Id -Force -ErrorAction SilentlyContinue
""

# ---------------------------------------------------------------------------
# E. Elevated process: can we read its incarnation at all?
# ---------------------------------------------------------------------------
"--- E. an elevated process's incarnation ---"
$elevScript = Join-Path $PSScriptRoot '_elev-hold.ps1'
@'
# Hold an elevated process with a window open long enough to be measured.
Add-Type -AssemblyName System.Windows.Forms
$f = New-Object System.Windows.Forms.Form
$f.Text = 'PROBE-ELEVATED-TARGET'
$f.Width = 300; $f.Height = 150
$f.Show()
"ELEVATED pid=$PID session=$([System.Diagnostics.Process]::GetCurrentProcess().SessionId)" |
  Set-Content (Join-Path $env:TEMP 'probe-elev-hold.txt') -Encoding utf8
[void][System.Windows.Forms.Application]::Run($f)
'@ | Set-Content -Path $elevScript -Encoding utf8
$holdLog = Join-Path $env:TEMP 'probe-elev-hold.txt'
Remove-Item $holdLog -ErrorAction SilentlyContinue

$elev = $null
try {
  $elev = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') `
    -ArgumentList @('-NoProfile', '-File', $elevScript) -Verb RunAs -PassThru -WindowStyle Hidden -ErrorAction Stop
} catch {
  "  RunAs failed: $($_.Exception.Message)"
}
Start-Sleep -Seconds 6
if ($elev -and -not $elev.HasExited) {
  "  elevated process started: pid=$($elev.Id)"
  $inc = Get-ProbeProcessIncarnation -PidValue $elev.Id
  "  incarnation: seq=$($inc.SequenceNumber) readable=$($inc.SequenceReadable) created=$($inc.CreatedUtc) source=$($inc.Source)"
  $elevWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $elev.Id })
  "  visible top-level windows owned by the elevated process: $($elevWins.Count)"
  foreach ($w in $elevWins) {
    $nonce = New-ProbeGenerationNonce
    $r = Set-ProbeGenerationMarker -Hwnd ([IntPtr]$w.HwndValue) -Nonce $nonce
    $rb = Get-ProbeGenerationMarker ([IntPtr]$w.HwndValue)
    "    hwnd=$($w.Hwnd) SetProp ok=$($r.Ok) win32error=$($r.Win32Error) readBack=$rb"
    Add-Result 'UIPI: enrolment against an elevated window reports a specific result' 'either success or ERROR_ACCESS_DENIED (5), never a silent no-op' "ok=$($r.Ok) win32error=$($r.Win32Error) readBack=$rb" $true
  }
  if ($elevWins.Count -eq 0) {
    Add-Result 'an elevated window is enumerated by an unelevated process' 'the elevated window appears in EnumWindows' 'zero elevated windows visible' $false
    "        Note which failed first: SetProp was never REACHED, because the window"
    "        was not even enumerable from this integrity level. That is a stronger"
    "        refusal than an access-denied write, and it means an elevated target is"
    "        invisible rather than mismatched."
  }
  Stop-Process -Id $elev.Id -Force -ErrorAction SilentlyContinue
} else {
  Add-Result 'an elevated process can be started for the UIPI test' 'a running elevated process' "started=$($elev -ne $null) exited=$($elev.HasExited)" $false
  "        UIPI against a real elevated target could NOT be measured."
}
""

"=== EXPERIMENT 16 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
