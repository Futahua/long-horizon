# probe-11-hwnd-reuse-harness.ps1
#
# EXPERIMENT 11 — FORCE HWND reuse and test whether a replacement object
# occupying the same numerical HWND can inherit an enrolled generation marker.
#
# The reviewer's block: a window is destroyed and a numerically identical HWND is
# later handed to a DIFFERENT top-level window in the SAME still-running process
# with the SAME class, so boot + PID + process incarnation + class all pass while
# the window object is different. "Rare" is not a defence, so this harness forces
# the condition instead of waiting for it.
#
# Mechanism: a long-lived window server process (window-server.ps1) whose windows
# are created and destroyed on command. Killing a window frees its HWND slot, and
# the next window allocated in that process takes it back.
#
# Windows are probe-owned: created by the server this probe starts, destroyed by
# the same server. Nothing pre-existing is touched.

. "$PSScriptRoot\win-identity-lib.ps1"

$PS = (Get-Process -Id $PID).Path
$SERVER = Join-Path $PSScriptRoot 'window-server.ps1'
$results = New-Object System.Collections.ArrayList

function Add-Result {
  param([string]$Test, [string]$Expect, [string]$Observed, [bool]$Pass)
  [void]$results.Add([pscustomobject]@{ Test = $Test; Verdict = if ($Pass) { 'PASS' } else { 'FAIL' } })
  "[{0}] {1}" -f $(if ($Pass) { 'PASS' } else { 'FAIL' }), $Test
  "        expected: $Expect"
  "        observed: $Observed"
}
function Write-ProbeLine { param([string]$T) [Console]::Out.WriteLine($T); [Console]::Out.Flush() }

# --- start the window server ----------------------------------------------
$dir = Join-Path $env:TEMP ('probe-reuse-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir | Out-Null
$cmdFile = Join-Path $dir 'cmd.txt'
$resFile = Join-Path $dir 'res.txt'

$server = Start-Process -FilePath $PS -ArgumentList @('-NoProfile', '-File', $SERVER, $dir) -PassThru
"window server pid : $($server.Id)"

# wait for the server to announce readiness
$ready = $false
for ($i = 0; $i -lt 100; $i++) {
  if (Test-Path $resFile) {
    $c = Get-Content $resFile -Raw -ErrorAction SilentlyContinue
    if ($c -and $c -match 'ready') { $ready = $true; break }
  }
  Start-Sleep -Milliseconds 200
}
Add-Result 'window server is alive and accepting commands' 'a ready acknowledgement' "ready=$ready pid=$($server.Id)" $ready
if (-not $ready) {
  "server did not start; stderr follows"
  if (-not $server.HasExited) { Stop-Process -Id $server.Id -Force }
  exit 1
}
""

function Send-ServerCommand {
  param([string]$Command, [int]$TimeoutSec = 30)
  Remove-Item $resFile -ErrorAction SilentlyContinue
  Set-Content -Path $cmdFile -Value $Command -Encoding ascii
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $resFile) {
      Start-Sleep -Milliseconds 120
      $raw = Get-Content $resFile -Raw -ErrorAction SilentlyContinue
      if ($raw -and $raw.Trim().Length -gt 0) {
        return @($raw.Trim() -split "`r?`n" | Where-Object { $_.Trim() })
      }
    }
    Start-Sleep -Milliseconds 60
  }
  return @('<timeout>')
}

function New-ServerWindow {
  param([string]$Title)
  $lines = Send-ServerCommand "CREATE|$Title"
  $hwnd = $null
  foreach ($l in $lines) {
    if ($l -match '^CREATED\|(\d+)\|') { $hwnd = [IntPtr][long]$matches[1] }
  }
  return [pscustomobject]@{ Hwnd = $hwnd; Lines = $lines }
}

function Remove-ServerWindow {
  param([IntPtr]$Hwnd)
  return (Send-ServerCommand "DESTROY|$($Hwnd.ToInt64())")
}

"=== EXPERIMENT 11 : forced HWND reuse vs an enrolled generation marker ==="
""

# ---------------------------------------------------------------------------
# A. Force reuse: does a destroyed slot come back?
# ---------------------------------------------------------------------------
"--- A. forcing reuse in ONE live process ---"
$created = @()
foreach ($i in 1..4) {
  $w = New-ServerWindow -Title "PROBE-REUSE-SEED-$i"
  if ($w.Hwnd) { $created += $w.Hwnd }
}
"  seed windows : $(($created | ForEach-Object { '0x{0:X}' -f $_.ToInt64() }) -join ', ')"

$reuseHits = 0
$reuseTrials = 0
$reusePairs = @()
foreach ($h in $created) {
  $destroyOut = Remove-ServerWindow -Hwnd $h
  $aliveAfter = [WhProbe.Win32]::IsWindow($h)
  $fresh = New-ServerWindow -Title "PROBE-REUSE-REPLACEMENT"
  $reuseTrials++
  if ($fresh.Hwnd -and $fresh.Hwnd.ToInt64() -eq $h.ToInt64()) { $reuseHits++ }
  $reusePairs += [pscustomobject]@{
    Destroyed = '0x{0:X}' -f $h.ToInt64()
    DeadAfterDestroy = (-not $aliveAfter)
    Replacement = if ($fresh.Hwnd) { '0x{0:X}' -f $fresh.Hwnd.ToInt64() } else { '<none>' }
    Reused = ($fresh.Hwnd -and $fresh.Hwnd.ToInt64() -eq $h.ToInt64())
  }
  # keep the replacement alive: it is the next subject
  $created = @($created | Where-Object { $_.ToInt64() -ne $h.ToInt64() })
  if ($fresh.Hwnd) { $created += $fresh.Hwnd }
  break   # one forced-reuse pair is enough to establish the mechanism; more below
}
$reusePairs | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine

$destroyIsReal = @($reusePairs | Where-Object { -not $_.DeadAfterDestroy }).Count -eq 0
Add-Result 'destroying a window really ends it (IsWindow false)' 'every destroyed HWND is not a window' "pairs=$($reusePairs.Count) all-dead=$destroyIsReal" $destroyIsReal

if ($reuseHits -gt 0) {
  Add-Result 'FORCED: a later window in the same process receives the same numerical HWND' 'the destroyed slot is handed back' "reused $reuseHits of $reuseTrials trials" $true
} else {
  Add-Result 'FORCED: a later window in the same process receives the same numerical HWND' 'the destroyed slot is handed back' "reused $reuseHits of $reuseTrials trials - mechanism not yet forced, expanding the search" $false
  # Escalate: churn many windows in this one process to drive the allocator.
  $churnHits = 0
  $churnTrials = 0
  $seen = @{}
  foreach ($round in 1..12) {
    $w = New-ServerWindow -Title "PROBE-CHURN-$round"
    if (-not $w.Hwnd) { continue }
    $key = $w.Hwnd.ToInt64()
    if ($seen.ContainsKey($key)) { $churnHits++ } else { $seen[$key] = $round }
    $churnTrials++
    [void](Remove-ServerWindow -Hwnd $w.Hwnd)
  }
  "  churn escalation: $churnTrials create/destroy cycles, $churnHits reused a prior HWND value"
  Add-Result 'FORCED (escalated): HWND values recur within one live process' 'at least one recurrence across create/destroy cycles' "recurrences=$churnHits of $churnTrials cycles" ($churnHits -gt 0)
}
""

# ---------------------------------------------------------------------------
# B. THE INVARIANT: can a replacement inherit the enrolled marker?
# ---------------------------------------------------------------------------
"--- B. the invariant: replacement object must not inherit the enrolled marker ---"

# Establish a killed-slot pair deterministically: keep creating until one reuses.
$victim = $null
$replacement = $null
$markerNonce = $null
foreach ($attempt in 1..40) {
  $a = New-ServerWindow -Title "PROBE-INVARIANT-A-$attempt"
  if (-not $a.Hwnd) { continue }

  # Enrol generation nonce G onto A while A is alive.
  $nonce = New-ProbeGenerationNonce
  $set = Set-ProbeGenerationMarker -Hwnd $a.Hwnd -Nonce $nonce
  if (-not $set.Ok) { continue }
  $readBack = Get-ProbeGenerationMarker -Hwnd $a.Hwnd
  if ($readBack -ne "PapersProbe.Gen.$nonce") { continue }

  # Record the full corroboration scope for A.
  $scopeA = (Get-ProbeIdentityScope -Hwnd $a.Hwnd).Scope

  # Kill A.
  [void](Remove-ServerWindow -Hwnd $a.Hwnd)
  if ([WhProbe.Win32]::IsWindow($a.Hwnd)) { continue }

  # Create B repeatedly in the SAME process until it lands on A's slot.
  foreach ($try in 1..40) {
    $b = New-ServerWindow -Title "PROBE-INVARIANT-B-$attempt-$try"
    if (-not $b.Hwnd) { continue }
    if ($b.Hwnd.ToInt64() -eq $a.Hwnd.ToInt64()) {
      $victim = $a.Hwnd; $replacement = $b.Hwnd; $markerNonce = $nonce
      $scopeABefore = $scopeA
      break
    }
  }
  if ($replacement) { break }
}

if (-not $replacement) {
  Add-Result 'INVARIANT: a replacement window can be forced onto the killed slot' 'same numerical HWND, different live window object' 'could not force a slot collision in 40 attempts' $false
} else {
  $hxA = '0x{0:X}' -f $victim.ToInt64()
  "  A (killed)  : hwnd=$hxA pid=$($scopeABefore.pid) class=$($scopeABefore.className) nonce=$markerNonce"
  "  B (new)     : hwnd=$('0x{0:X}' -f $replacement.ToInt64())"

  $scopeB = (Get-ProbeIdentityScope -Hwnd $replacement).Scope
  "  B scope     : pid=$($scopeB.pid) class=$($scopeB.className) created=$($scopeB.processCreatedUtc) seq=$($scopeB.processSequence)"

  Add-Result 'the replacement occupies the SAME numerical HWND as the killed window' 'identical handle value' "A=$hxA B=$($scopeB.hwnd)" ($replacement.ToInt64() -eq $victim.ToInt64())

  # Every corroborator the round-one design relied on:
  $corrob = [ordered]@{
    'same PID'                = ($scopeA.pid -eq $scopeB.pid)
    'same process creation'   = ($scopeABefore.processCreatedUtc -eq $scopeB.processCreatedUtc)
    'same process sequence'   = ($null -ne $scopeB.processSequence -and $scopeABefore.processSequence -eq $scopeB.processSequence)
    'same window class'       = ($scopeABefore.className -eq $scopeB.className)
    'same boot'               = ($scopeABefore.bootId -eq $scopeB.bootId)
    'same session'            = ($scopeABefore.sessionId -eq $scopeB.sessionId)
  }
  foreach ($k in $corrob.Keys) { "    {0,-26} {1}" -f $k, $corrob[$k] }
  ""
  # Note: both windows live in ONE server process, so these MUST all match - that
  # is the whole point of the reviewer's counterexample.
  $allPass = -not ($corrob.Values -contains $false)
  Add-Result 'EVERY round-one corroborator passes for the replacement object' 'all corroborators identical: they cannot tell A from B' "all-match=$allPass" $allPass

  $markerOnB = Get-ProbeGenerationMarker $replacement
  "  marker on A  : PapersProbe.Gen.$markerNonce"
  "  marker on B  : $markerOnB"
  Add-Result 'INVARIANT HOLDS: the replacement does NOT carry the enrolled generation marker' 'marker absent on the replacement object' "marker on B = '$markerOnB'" ($null -eq $markerOnB)

  # Bit-identical to the reviewer's counterexample, but now with a discriminator.
  $verifiedB = Get-ProbeIdentityScope -Hwnd $replacement -Expected $scopeABefore -MarkerAtom ([uint16]0)
  "  scope check against A (corroborators only): Verified=$($verifiedB.Verified) mismatches=$($verifiedB.Mismatches.Count)"
  Add-Result 'corroborators ALONE report the replacement as the same verified instance' 'Verified=true: this is the hole the reviewer named' 'Verified=' + $verifiedB.Verified ($verifiedB.Verified -eq $true)

  # Now with the marker as part of the check:
  $scheme = New-ProbeGenerationNonce
  $setB = Set-ProbeGenerationMarker -Hwnd $replacement -Nonce $scheme
  "  (B separately enrolled with its own nonce $scheme, as a real system would)"
  $markerOnB2 = Get-ProbeGenerationMarker $replacement
  Add-Result 'a newly enrolled replacement carries its OWN generation, distinct from A''s' 'different marker value' "A=Gen.$markerNonce B=$markerOnB2" ($markerOnB2 -eq "PapersProbe.Gen.$scheme")
  Remove-ProbeGenerationMarker $replacement | Out-Null
}
""

# ---------------------------------------------------------------------------
# C. Class names are uniquely owned per process and back many windows
# ---------------------------------------------------------------------------
"--- C. window class: unique per process, shared by every window of it ---"
$c1 = New-ServerWindow -Title 'PROBE-CLASS-1'
$c2 = New-ServerWindow -Title 'PROBE-CLASS-2'
$c3 = New-ServerWindow -Title 'PROBE-CLASS-3'
$classSet = @()
foreach ($w in @($c1, $c2, $c3)) { if ($w.Hwnd) { $classSet += (Get-ProbeWindowSignals -Hwnd $w.Hwnd).ClassName } }
"  classes: $($classSet -join ' | ')"
Add-Result 'three distinct live windows of one process share one class name' 'all three class names identical' "unique=$(@($classSet | Select-Object -Unique).Count) of $($classSet.Count)" ((@($classSet | Select-Object -Unique).Count) -eq 1)
"        So class name narrows nothing: it is corroboration, exactly as the reviewer says."
foreach ($w in @($c1, $c2, $c3)) { if ($w.Hwnd) { [void](Remove-ServerWindow -Hwnd $w.Hwnd) } }
""

# ---------------------------------------------------------------------------
# D. A marker set on a destroyed window's slot: is absence proof of death?
# ---------------------------------------------------------------------------
"--- D. what marker ABSENCE does and does not mean ---"
$d1 = New-ServerWindow -Title 'PROBE-ABSENCE-1'
$nonceD = New-ProbeGenerationNonce
[void](Set-ProbeGenerationMarker -Hwnd $d1.Hwnd -Nonce $nonceD)
$presentD = Get-ProbeGenerationMarker $d1.Hwnd
[void](Remove-ServerWindow -Hwnd $d1.Hwnd)
$afterD = Get-ProbeGenerationMarker $d1.Hwnd
"  before destroy : $presentD"
"  after destroy  : $afterD (IsWindow=$([WhProbe.Win32]::IsWindow($d1.Hwnd)))"
$freshD = New-ServerWindow -Title 'PROBE-ABSENCE-2'
$onFresh = Get-ProbeGenerationMarker $freshD.Hwnd
"  on a fresh window in the same process: $onFresh"
Add-Result 'marker absence is ambiguous between "window died" and "never enrolled"' 'absence on a dead HWND and on a fresh un-enrolled window are the same observation' "dead=$afterD fresh=$onFresh" ($null -eq $afterD -and $null -eq $onFresh)
"        Therefore absence MUST map to UNVERIFIED, never to gone."
if ($freshD.Hwnd) { [void](Remove-ServerWindow -Hwnd $freshD.Hwnd) }
""

# ---------------------------------------------------------------------------
# E. The atom's refcount: does destroying the only window free the atom?
# ---------------------------------------------------------------------------
"--- E. atom lifetime versus window lifetime ---"
$e1 = New-ServerWindow -Title 'PROBE-ATOM-1'
$nonceE = New-ProbeGenerationNonce
$setE = Set-ProbeGenerationMarker -Hwnd $e1.Hwnd -Nonce $nonceE
$atomNameE = "PapersProbe.Gen.$nonceE"
$findWhileHeld = [WhProbe.Win32]::GlobalFindAtomW($atomNameE)
[void](Remove-ServerWindow -Hwnd $e1.Hwnd)
Start-Sleep -Milliseconds 300
$findAfterDestroy = [WhProbe.Win32]::GlobalFindAtomW($atomNameE)
"  atom value while window alive : $findWhileHeld"
"  atom value after window death : $findAfterDestroy (0 = gone)"
Add-Result 'destroying the window releases the atom that carried its generation' 'the atom no longer resolves after the window is gone' "find-after=$findAfterDestroy" ($findAfterDestroy -eq 0)
"        Good for hygiene: a dead window''s generation cannot be resurrected by name."
""

# ---------------------------------------------------------------------------
# F. Simultaneous live windows in one process: distinct markers, no bleed
# ---------------------------------------------------------------------------
"--- F. several live windows, distinct generations, no bleed ---"
$live = @()
$nonces = @{}
foreach ($i in 1..5) {
  $w = New-ServerWindow -Title "PROBE-MULTI-$i"
  if (-not $w.Hwnd) { continue }
  $n = New-ProbeGenerationNonce
  $r = Set-ProbeGenerationMarker -Hwnd $w.Hwnd -Nonce $n
  if ($r.Ok) { $live += $w.Hwnd; $nonces[$w.Hwnd.ToInt64()] = $n }
}
$ok = $true
foreach ($h in $live) {
  $got = Get-ProbeGenerationMarker $h
  $want = "PapersProbe.Gen.$($nonces[$h.ToInt64()])"
  if ($got -ne $want) { $ok = $false; "    MISMATCH hwnd=$('0x{0:X}' -f $h.ToInt64()) got=$got want=$want" }
}
Add-Result 'each live window keeps its own generation marker with no bleed' 'all five read back their own nonce' "windows=$($live.Count) all-correct=$ok" ($ok -and $live.Count -ge 3)
foreach ($h in $live) { [void](Remove-ServerWindow -Hwnd $h) }
""

"=== EXPERIMENT 11 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"

if (-not $server.HasExited) { [void](Send-ServerCommand 'EXIT' 5); Start-Sleep -Milliseconds 400; if (-not $server.HasExited) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue } }
Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue
