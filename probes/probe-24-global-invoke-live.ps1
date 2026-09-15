# probe-24-global-invoke-live.ps1
#
# EXPERIMENT 24 — the global invocation chords, measured against a REAL running
# Papers instance rather than reasoned about.
#
# Three things are checked by running:
#   1. with nothing holding the chords, Papers registers BOTH and reports them;
#   2. with another process already holding Alt+A, Papers reports that chord as
#      taken, names it, and still registers the other one;
#   3. a separate process cannot take either chord while Papers holds them.
#
# The instance is launched with PAPERS_TEST_USER_DATA so it is isolated from the
# creator's Papers, their vault and their layouts. Nothing of theirs is touched.

. "$PSScriptRoot\win-identity-lib.ps1"

$REPO = 'D:\Letters\MatTroiSeConMoc\Products\Papers\Source'
$ELECTRON = Join-Path $REPO 'node_modules\electron\dist\electron.exe'
$PROBES = $PSScriptRoot
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

function Start-IsolatedPapers {
  param([string]$Label)
  $data = Join-Path $env:TEMP ("papers-gi-$Label-" + [guid]::NewGuid().ToString('N'))
  New-Item -ItemType Directory -Path $data -Force | Out-Null
  $descriptor = Join-Path $data 'control.json'
  $env:PAPERS_TEST_USER_DATA = $data
  $env:PAPERS_DEV_CONTROL = '1'
  $env:PAPERS_DEV_CONTROL_DESCRIPTOR = $descriptor
  $proc = Start-Process -FilePath $ELECTRON -ArgumentList @($REPO) -PassThru -WindowStyle Minimized
  Remove-Item Env:\PAPERS_DEV_CONTROL -ErrorAction SilentlyContinue
  Remove-Item Env:\PAPERS_DEV_CONTROL_DESCRIPTOR -ErrorAction SilentlyContinue
  Remove-Item Env:\PAPERS_TEST_USER_DATA -ErrorAction SilentlyContinue
  return [pscustomobject]@{ Process = $proc; Data = $data; Descriptor = $descriptor }
}

function Stop-IsolatedPapers {
  param($App)
  if (-not $App -or -not $App.Process) { return }
  if ($App.Process.HasExited) { return }
  $App.Process.CloseMainWindow() | Out-Null
  for ($i = 0; $i -lt 20; $i++) {
    Start-Sleep -Milliseconds 500
    if ($App.Process.HasExited) { break }
  }
  if (-not $App.Process.HasExited) {
    Stop-Process -Id $App.Process.Id -Force -ErrorAction SilentlyContinue
    "  (force-stopped pid=$($App.Process.Id): CloseMainWindow did not settle)"
  } else {
    "  stopped pid=$($App.Process.Id)"
  }
  # Electron spawns helper processes that can outlive the main one; wait until
  # the chords are genuinely free rather than assuming the quit was immediate.
  for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    $probeOut = Join-Path $env:TEMP ('chord-free-check-' + [guid]::NewGuid().ToString('N') + '.txt')
    $env:PROBE_MODE = 'contention'
    $null = & node (Join-Path $REPO 'node_modules\electron\cli.js') (Join-Path $PSScriptRoot 'electron-shortcut-probe.mjs') $probeOut 2>&1
    $text = if (Test-Path $probeOut) { Get-Content $probeOut -Raw } else { '' }
    Remove-Item $probeOut -Force -ErrorAction SilentlyContinue
    if ($text -match 'Alt\+A: .*register\(\)=true') { break }
  }
  Remove-Item Env:\PROBE_MODE -ErrorAction SilentlyContinue
}

function Get-ShortcutReport {
  param([string]$Descriptor, [int]$TimeoutSec = 60)
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $Descriptor) {
      $raw = & node (Join-Path $REPO 'tools\papersControlClient.mjs') 2>$null
      break
    }
    Start-Sleep -Milliseconds 500
  }
  # papersctl is the documented client; use it for the snapshot.
  $out = & node (Join-Path $REPO 'tools\papersctl.mjs') inspect.snapshot --descriptor $Descriptor 2>&1 | Out-String
  try { return ($out | ConvertFrom-Json) } catch { return $null }
}

"=== EXPERIMENT 24 : global invocation chords against a real Papers ==="
"electron : $ELECTRON"
""

# ---------------------------------------------------------------------------
# 1. Nothing holding the chords: both must register.
# ---------------------------------------------------------------------------
"--- 1. with no contention ---"
$app1 = Start-IsolatedPapers -Label 'free'
"  launched isolated Papers pid=$($app1.Process.Id) data=$($app1.Data)"
$snap1 = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 1
  $snap1 = Get-ShortcutReport -Descriptor $app1.Descriptor -TimeoutSec 5
  if ($snap1 -and $snap1.globalShortcuts) { break }
}
if ($snap1 -and $snap1.globalShortcuts) {
  $registered = @($snap1.globalShortcuts.registered)
  $failures = @($snap1.globalShortcuts.failures)
  "  registered : $($registered -join ', ')"
  "  failures   : $($failures.Count)"
  Add-Result 'Papers registers both chords when nothing else holds them' 'Alt+Shift+A and Alt+A registered, no failures' "registered=[$($registered -join ', ')] failures=$($failures.Count)" ($registered.Count -eq 2 -and $failures.Count -eq 0)
} else {
  Add-Result 'the isolated instance reports its shortcut state' 'a globalShortcuts record in inspect.snapshot' "snapshot=$($snap1 | ConvertTo-Json -Compress -Depth 4)" $false
}
""

# ---------------------------------------------------------------------------
# 2. Another process holds Alt+A: Papers must refuse it BY NAME and keep the other.
#
# The first instance is stopped FIRST. Leaving it running was the defect in the
# previous run of this probe: it still held both chords, so the "contention"
# measured was the first instance rather than the holder.
# ---------------------------------------------------------------------------
"--- 2. with another process holding Alt+A ---"
"  stopping the first instance so the holder can take the chord"
Stop-IsolatedPapers -App $app1
""

$marker = Join-Path $env:TEMP ('chord-holder-' + [guid]::NewGuid().ToString('N') + '.txt')
Remove-Item $marker -ErrorAction SilentlyContinue
$env:HOLD_MS = '90000'
$holder = Start-Process -FilePath (Join-Path $REPO 'node_modules\.bin\electron.cmd') `
  -ArgumentList @((Join-Path $PROBES 'electron-chord-holder.mjs'), $marker) -PassThru -WindowStyle Hidden
$held = $false
for ($i = 0; $i -lt 60; $i++) {
  Start-Sleep -Milliseconds 500
  if (Test-Path $marker) { $held = $true; break }
}
$holderLine = if (Test-Path $marker) { (Get-Content $marker -Raw).Trim() } else { '<no marker>' }
"  holder: $holderLine"
Add-Result 'a separate process holds Alt+A' 'the holder registered Alt+A' $holderLine ($holderLine -match 'Alt\+A=true')

# A second isolated instance, with the holder in place.
$app2 = Start-IsolatedPapers -Label 'taken'
"  launched second isolated Papers pid=$($app2.Process.Id)"
$snap2 = $null
for ($i = 0; $i -lt 40; $i++) {
  Start-Sleep -Seconds 1
  $snap2 = Get-ShortcutReport -Descriptor $app2.Descriptor -TimeoutSec 5
  if ($snap2 -and $snap2.globalShortcuts) { break }
}
if ($snap2 -and $snap2.globalShortcuts) {
  $registered2 = @($snap2.globalShortcuts.registered)
  $failures2 = @($snap2.globalShortcuts.failures)
  "  registered : $($registered2 -join ', ')"
  foreach ($f in $failures2) { "  failure    : $($f.accelerator) chord=$($f.chord) reason=$($f.reason)" }
  Add-Result 'a taken chord is reported as a failure rather than silently ignored' 'one failure naming Alt+A' "failures=$($failures2.Count)" ($failures2.Count -eq 1)
  Add-Result 'the failure names the chord that is taken' 'Alt+A in the failure record' "$($failures2[0].accelerator)" ($failures2.Count -eq 1 -and $failures2[0].accelerator -eq 'Alt+A')
  Add-Result 'the failure distinguishes a taken chord from an unusable one' 'reason=already-registered-by-another-application' "$($failures2[0].reason)" ($failures2.Count -eq 1 -and $failures2[0].reason -eq 'already-registered-by-another-application')
  Add-Result 'the OTHER chord still registers: one refusal must not disarm the feature' 'Alt+Shift+A registered' "$($registered2 -join ', ')" ($registered2 -contains 'Alt+Shift+A')
  Add-Result 'no substitute chord was invented' 'exactly the two requested chords appear, nothing else' "registered=[$($registered2 -join ', ')]" (@($registered2 | Where-Object { $_ -ne 'Alt+Shift+A' -and $_ -ne 'Alt+A' }).Count -eq 0)
} else {
  Add-Result 'the contended instance reports its shortcut state' 'a globalShortcuts record' "snapshot=$($snap2 | ConvertTo-Json -Compress -Depth 4)" $false
}
""

# ---------------------------------------------------------------------------
# 3. While an instance holds them, can another process take them?
# ---------------------------------------------------------------------------
"--- 3. contention from a third process ---"
$outC = Join-Path $env:TEMP ('probe-contention-' + [guid]::NewGuid().ToString('N') + '.txt')
Remove-Item $outC -ErrorAction SilentlyContinue
$env:PROBE_MODE = 'contention'
$null = & node (Join-Path $REPO 'node_modules\electron\cli.js') (Join-Path $PROBES 'electron-shortcut-probe.mjs') $outC 2>&1
Remove-Item Env:\PROBE_MODE -ErrorAction SilentlyContinue
$contention = if (Test-Path $outC) { (Get-Content $outC -Raw).Trim() } else { '<none>' }
foreach ($line in ($contention -split "`r?`n")) { "  $line" }
Add-Result 'while Papers holds a chord, no other process can take it' 'register() returns false for both chords' $contention (($contention -split "`r?`n" | Where-Object { $_ -match 'register\(\)=true' }).Count -eq 0)
""

# ---------------------------------------------------------------------------
# 4. Cleanup: quit both instances and the holder.
# ---------------------------------------------------------------------------
"--- 4. shutdown ---"
Stop-IsolatedPapers -App $app2
if ($holder -and -not $holder.HasExited) { Stop-Process -Id $holder.Id -Force -ErrorAction SilentlyContinue; "  stopped holder pid=$($holder.Id)" }
# The holder's electron child may outlive the .cmd wrapper.
Get-CimInstance Win32_Process -Filter "Name='electron.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -and $_.CommandLine -like '*chord-holder*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue; "  stopped holder electron pid=$($_.ProcessId)" }
Start-Sleep -Seconds 5

$outD = Join-Path $env:TEMP ('probe-released-' + [guid]::NewGuid().ToString('N') + '.txt')
Remove-Item $outD -ErrorAction SilentlyContinue
$env:PROBE_MODE = 'contention'
$null = & node (Join-Path $REPO 'node_modules\electron\cli.js') (Join-Path $PROBES 'electron-shortcut-probe.mjs') $outD 2>&1
Remove-Item Env:\PROBE_MODE -ErrorAction SilentlyContinue
$released = if (Test-Path $outD) { (Get-Content $outD -Raw).Trim() } else { '<none>' }
foreach ($line in ($released -split "`r?`n")) { "  $line" }
Add-Result 'after Papers quits, both chords are released back to the system' 'register() returns true for both' $released (($released -split "`r?`n" | Where-Object { $_ -match 'register\(\)=true' }).Count -eq 2)
""

"=== EXPERIMENT 24 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
