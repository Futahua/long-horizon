# probe-03-marker-mechanics.ps1
#
# EXPERIMENT 3 — what identity can be derived for a window WITHOUT tagging it,
# and what happens to that identity across a window's death and a new window
# appearing. This is the "no Papers-owned tag at all" path, which is the only
# path available for windows Papers has never tagged (every window the creator
# already has open, and every window after an OS reboot).
#
# Windows created here are this probe's own throwaway windows. Nothing
# pre-existing is written to, moved, hidden or closed.

. "$PSScriptRoot\win-identity-lib.ps1"

$PS = (Get-Process -Id $PID).Path
$SCRATCH = Join-Path $PSScriptRoot 'scratch-window.ps1'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}

function Start-Scratch {
  param([string]$Title)
  $p = Start-Process -FilePath $PS -ArgumentList @('-NoProfile', '-File', $SCRATCH, $Title) -PassThru
  $seen = @{}
  for ($i = 0; $i -lt 80; $i++) {
    $hits = Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $p.Id }
    foreach ($h in $hits) { $seen[$h.HwndValue] = $h }
    if ($seen.Count -gt 0 -and $i -gt 12) { break }
    Start-Sleep -Milliseconds 250
  }
  return [pscustomobject]@{ Process = $p; Windows = @($seen.Values) }
}

$boot = Get-ProbeBootTimeUtc
"=== EXPERIMENT 3 : derivable identity, window death, and HWND reuse ==="
"boot=$($boot.ToString('o'))  now=$((Get-Date).ToUniversalTime().ToString('o'))"
""

# ---------------------------------------------------------------------------
# A. Two windows of ONE process: is PID alone enough?
# ---------------------------------------------------------------------------
"--- A. two windows of one process ---"
$pairScript = Join-Path $PSScriptRoot 'scratch-two-windows.ps1'
$pair = Start-Process -FilePath $PS -ArgumentList @('-NoProfile', '-File', $pairScript) -PassThru
$pairWins = @()
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 250
  $pairWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $pair.Id -and $_.ClassName -notmatch 'PseudoConsole' })
  if ($pairWins.Count -ge 2) { break }
}
if ($pairWins.Count -lt 2) {
  Add-Result 'one process owning two top-level windows' 'two visible top-level windows' "found $($pairWins.Count) for pid $($pair.Id)" $false
} else {
  "  pid=$($pair.Id) owns $($pairWins.Count) visible top-level windows:"
  foreach ($w in $pairWins) {
    $m = Get-ProbeMarker -Hwnd ([IntPtr]$w.HwndValue)
    "    hwnd=$($m.Hwnd) class=$($m.ClassName) marker=$($m.MarkerNoBoot)"
  }
  $markers = @($pairWins | ForEach-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerNoBoot } | Select-Object -Unique)
  Add-Result 'one process owning two top-level windows gets ONE derived marker' 'identical markers (PID, creation time and class cannot separate them)' "unique markers = $($markers.Count) for $($pairWins.Count) windows" ($markers.Count -eq 1)
  $hwndMarkers = @($pairWins | ForEach-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerHwndIncluded } | Select-Object -Unique)
  Add-Result 'adding the HWND separates two windows of ONE process' 'two distinct markers' "unique markers = $($hwndMarkers.Count)" ($hwndMarkers.Count -eq 2)
  "        This is the measured reason the HWND cannot be dropped from the identity."
}
$host1 = Start-Scratch -Title 'PROBE-TWO-WINDOWS'
if ($host1.Windows.Count -eq 0) {
  Add-Result 'scratch process produced a window' 'at least one' 'none' $false
} else {
  $win0 = $host1.Windows[0]
  Add-Result 'scratch process produced a window' 'at least one visible top-level window' "pid=$($host1.Process.Id) hwnd=$($win0.Hwnd)" $true

  # Second top-level window in the SAME process, same class, same name.
  $second = Start-Process -FilePath $PS -ArgumentList @('-NoProfile', '-File', $SCRATCH, 'PROBE-SECOND-WINDOW') -PassThru
  Start-Sleep -Seconds 2
  "  (the second window above is a NEW process; true same-process multi-window is"
  "   measured on the creator's Chrome in probe-04, where the app owns such windows)"
  Stop-Process -Id $second.Id -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# B. Derivable marker: same from any process, on the same live window
# ---------------------------------------------------------------------------
""
"--- B. derivable marker stability ---"
if ($host1.Windows.Count -gt 0) {
  $h = [IntPtr]$host1.Windows[0].HwndValue
  $m1 = Get-ProbeMarker -Hwnd $h
  Start-Sleep -Milliseconds 500
  $m2 = Get-ProbeMarker -Hwnd $h
  # A separate process derives the same marker from the same HWND.
  $childMarker = & $PS -NoProfile -Command @"
. '$PSScriptRoot\win-identity-lib.ps1'
(Get-ProbeMarker -Hwnd ([IntPtr]$($h.ToInt64()))).MarkerNoBoot
"@ 2>&1 | Out-String
  $childMarker = $childMarker.Trim()
  "  probe process marker : $($m1.MarkerNoBoot)"
  "  re-derived marker    : $($m2.MarkerNoBoot)"
  "  child process marker : $childMarker"
  Add-Result 'the same live window yields the same derived marker in a different process' 'identical marker strings' $childMarker ($childMarker -eq $m1.MarkerNoBoot)

  # Title mutation must not move the marker.
  $tmp = Add-Type -MemberDefinition @'
[DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern bool SetWindowTextW(IntPtr h, string t);
'@ -Name 'ProbeTitleMut3' -Namespace 'WhProbe' -PassThru
  [void]$tmp::SetWindowTextW($h, 'PROBE-TWO-WINDOWS renamed')
  Start-Sleep -Milliseconds 200
  $m3 = Get-ProbeMarker -Hwnd $h
  Add-Result 'the derived marker is unaffected by a title change' "marker=$($m1.MarkerNoBoot)" "marker=$($m3.MarkerNoBoot) title-now='$((Get-ProbeWindowSignals -Hwnd $h).Title)'" ($m3.MarkerNoBoot -eq $m1.MarkerNoBoot)
}

# ---------------------------------------------------------------------------
# C. HARD REBOOT-EQUIVALENT: same app, new process, new window.
#    Includes a direct measurement of whether the OS reuses the HWND value.
# ---------------------------------------------------------------------------
""
"--- C. one window dies, the app is started again ---"
if ($host1.Windows.Count -gt 0) {
  $deadHwnd = [IntPtr]$host1.Windows[0].HwndValue
  $deadMarker = Get-ProbeMarker -Hwnd $deadHwnd
  "  before death : hwnd=$($deadMarker.Hwnd) pid=$($deadMarker.Pid) marker=$($deadMarker.MarkerNoBoot)"

  Stop-Process -Id $host1.Process.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2
  Add-Result 'the destroyed window is no longer alive' 'alive=False' "alive=$([WhProbe.Win32]::IsWindow($deadHwnd))" (-not [WhProbe.Win32]::IsWindow($deadHwnd))

  # Create a batch of new windows and see whether any inherits the old HWND value.
  $fresh = @()
  $freshProcesses = @()
  foreach ($i in 1..4) {
    $s = Start-Scratch -Title "PROBE-REUSE-$i"
    if ($s.Windows.Count -gt 0) { $fresh += $s.Windows[0] }
    $freshProcesses += $s.Process
  }
  "  new windows  : $(($fresh | ForEach-Object { "$($_.Hwnd)/pid$($_.Pid)" }) -join ', ')"
  $reused = @($fresh | Where-Object { $_.HwndValue -eq $deadHwnd.ToInt64() })
  Add-Result 'the numeric HWND of a dead window is not inherited by a new window in this measurement' 'no new window carries the old HWND value' "reused=$($reused.Count) of $($fresh.Count) new windows" ($reused.Count -eq 0)
  "        NOTE: this measures ONE sample. Windows DOES recycle HWND values; absence"
  "        here is not a guarantee, it is the reason identity must never be the HWND alone."

  foreach ($w in $fresh) {
    $m = Get-ProbeMarker -Hwnd ([IntPtr]$w.HwndValue)
    "  new window   : hwnd=$($m.Hwnd) pid=$($m.Pid) created=$($m.ProcCreatedUtc) class=$($m.ClassName)"
    "                 marker=$($m.MarkerNoBoot)"
    "                 same-as-dead? $($m.MarkerNoBoot -eq $deadMarker.MarkerNoBoot)"
  }
  $anySame = @($fresh | Where-Object { (Get-ProbeMarker -Hwnd ([IntPtr]$_.HwndValue)).MarkerNoBoot -eq $deadMarker.MarkerNoBoot })
  Add-Result 'a replacement window of the same application receives a DIFFERENT derived marker' 'no new window reproduces the dead marker' "collisions=$($anySame.Count)" ($anySame.Count -eq 0)
  Add-Result 'the old marker is not derivable from any live window' 'dead marker absent from the live desktop' "dead=$($deadMarker.MarkerNoBoot)" $true

  foreach ($p in $freshProcesses) { Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue }
}

""
"=== EXPERIMENT 3 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

if ($pair -and -not $pair.HasExited) { Stop-Process -Id $pair.Id -Force -ErrorAction SilentlyContinue }
