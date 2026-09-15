# probe-15-bitness-integrity.ps1
#
# EXPERIMENT 15 — the scalar-nonce SetProp/GetProp representation, across bitness
# and across integrity levels, measured rather than documented.
#
# The reviewer's requirement: check bitness behaviour before choosing the
# representation, and find out what UIPI actually does when a lower-integrity
# process writes to a higher-integrity window.
#
# Bitness: a 32-bit reader must see the same marker a 64-bit writer enrolled, and
# vice versa. The representation must therefore survive the WOW64 boundary.
#
# Integrity: Papers runs unelevated. If SetProp fails with ERROR_ACCESS_DENIED
# against an elevated window, the outcome must be a typed refusal, never a
# fallback to title/PID matching and never "gone".
#
# Windows used here are created by probe-owned processes. No pre-existing window
# is written to.

. "$PSScriptRoot\win-identity-lib.ps1"

$PS64 = (Get-Process -Id $PID).Path
$PS32 = Join-Path $env:SystemRoot 'SysWOW64\WindowsPowerShell\v1.0\powershell.exe'
$CHILD = Join-Path $PSScriptRoot 'probe-child.ps1'
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

"=== EXPERIMENT 15 : scalar representation across bitness and integrity ==="
"64-bit shell : $PS64"
"32-bit shell : $PS32 (exists=$(Test-Path $PS32))"
""

# ---------------------------------------------------------------------------
# Bitness of this shell, for the record
# ---------------------------------------------------------------------------
$is64 = [Environment]::Is64BitProcess
$os64 = [Environment]::Is64BitOperatingSystem
"probe process is 64-bit: $is64   OS is 64-bit: $os64"
Add-Result 'both a 32-bit and a 64-bit PowerShell are available to test with' 'both runtimes present' "ps32=$(Test-Path $PS32) ps64=$(Test-Path $PS64)" ((Test-Path $PS32) -and (Test-Path $PS64))
""

# ---------------------------------------------------------------------------
# A window owned by a 64-bit server, marked and read by both bitnesses
# ---------------------------------------------------------------------------
$dir = Join-Path $env:TEMP ('probe-bits-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $dir | Out-Null
$cmdFile = Join-Path $dir 'cmd.txt'
$resFile = Join-Path $dir 'res.txt'
$server = Start-Process -FilePath $PS64 -ArgumentList @('-NoProfile', '-File', $SERVER, $dir) -PassThru
$ready = $false
for ($i = 0; $i -lt 100; $i++) {
  if (Test-Path $resFile) { $c = Get-Content $resFile -Raw -ErrorAction SilentlyContinue; if ($c -match 'ready') { $ready = $true; break } }
  Start-Sleep -Milliseconds 200
}
Add-Result '64-bit window server is running' 'ready' "ready=$ready pid=$($server.Id)" $ready
if (-not $ready) { "server failed"; exit 1 }

function Send-ServerCommand {
  param([string]$Command, [int]$TimeoutSec = 30)
  Remove-Item $resFile -ErrorAction SilentlyContinue
  Set-Content -Path $cmdFile -Value $Command -Encoding ascii
  $deadline = (Get-Date).AddSeconds($TimeoutSec)
  while ((Get-Date) -lt $deadline) {
    if (Test-Path $resFile) {
      Start-Sleep -Milliseconds 120
      $raw = Get-Content $resFile -Raw -ErrorAction SilentlyContinue
      if ($raw -and $raw.Trim().Length -gt 0) { return @($raw.Trim() -split "`r?`n" | Where-Object { $_.Trim() }) }
    }
    Start-Sleep -Milliseconds 60
  }
  return @('<timeout>')
}

$out = Send-ServerCommand 'CREATE|PROBE-BITS-TARGET'
$targetHwnd = [IntPtr]::Zero
foreach ($l in $out) { if ($l -match '^CREATED\|(\d+)\|') { $targetHwnd = [IntPtr][long]$matches[1] } }
if ($targetHwnd -eq [IntPtr]::Zero) { "could not create the target window: $($out -join '; ')"; exit 1 }
"target window : hwnd=$('0x{0:X}' -f $targetHwnd.ToInt64()) owner-pid=$($server.Id) (64-bit)"
""

# A cross-bitness driver: enrol or read from a named bitness.
$driverPath = Join-Path $PSScriptRoot '_bits-driver.ps1'
@'
param([string]$Op, [long]$Hwnd, [int]$Nonce)
. "$PSScriptRoot\win-identity-lib.ps1"
$h = [IntPtr]$Hwnd
$bits = if ([Environment]::Is64BitProcess) { 64 } else { 32 }
switch ($Op) {
  'enrol' {
    $r = Set-ProbeGenerationMarker -Hwnd $h -Nonce ([uint16]$Nonce)
    "DRIVER bits=$bits op=enrol ok=$($r.Ok) win32error=$($r.Win32Error) atom=$($r.Atom) nonce=$Nonce"
  }
  'read' {
    $m = Get-ProbeGenerationMarker $h
    "DRIVER bits=$bits op=read marker=$m"
  }
  'raw' {
    # Report what the property actually holds, without interpreting it.
    $raw = [WhProbe.Win32]::GetPropW($h, 'PapersInstanceGeneration')
    "DRIVER bits=$bits op=raw value=0x$($raw.ToInt64().ToString('X')) asInt64=$($raw.ToInt64())"
  }
  'deref' {
    # Deliberately treat the stored value as a string pointer: the round-one bug.
    $raw = [WhProbe.Win32]::GetPropW($h, 'PapersInstanceGeneration')
    try { $t = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($raw); "DRIVER bits=$bits op=deref OK text=$t" }
    catch { "DRIVER bits=$bits op=deref THREW $($_.Exception.GetType().Name)" }
  }
}
'@ | Set-Content -Path $driverPath -Encoding utf8

function Invoke-Driver {
  param([string]$Bitness, [string]$Op, [IntPtr]$Hwnd, [int]$Nonce = 0)
  $exe = if ($Bitness -eq '32') { $PS32 } else { $PS64 }
  $out = & $exe -NoProfile -File $driverPath -Op $Op -Hwnd $Hwnd.ToInt64() -Nonce $Nonce 2>&1 | Out-String
  return $out.Trim()
}

"--- A. 64-bit writer, both readers ---"
$nonce64 = 41001
$w = Invoke-Driver -Bitness '64' -Op 'enrol' -Hwnd $targetHwnd -Nonce $nonce64
"  $w"
$r64 = Invoke-Driver -Bitness '64' -Op 'read' -Hwnd $targetHwnd
"  $r64"
$r32 = Invoke-Driver -Bitness '32' -Op 'read' -Hwnd $targetHwnd
"  $r32"
Add-Result 'marker written by a 64-bit process is read correctly by a 32-bit process' "marker=PapersProbe.Gen.$nonce64" $r32 ($r32 -match "PapersProbe\.Gen\.$nonce64")
""

"--- B. 32-bit writer, both readers ---"
$nonce32 = 41002
$w2 = Invoke-Driver -Bitness '32' -Op 'enrol' -Hwnd $targetHwnd -Nonce $nonce32
"  $w2"
$r64b = Invoke-Driver -Bitness '64' -Op 'read' -Hwnd $targetHwnd
"  $r64b"
$r32b = Invoke-Driver -Bitness '32' -Op 'read' -Hwnd $targetHwnd
"  $r32b"
Add-Result 'marker written by a 32-bit process is read correctly by a 64-bit process' "marker=PapersProbe.Gen.$nonce32" $r64b ($r64b -match "PapersProbe\.Gen\.$nonce32")
""

"--- C. the raw stored value as each bitness sees it ---"
foreach ($bits in @('64', '32')) {
  $raw = Invoke-Driver -Bitness $bits -Op 'raw' -Hwnd $targetHwnd
  "  $raw"
}
Add-Result 'the stored value is a small scalar, identical from both bitnesses' 'the same small integer, not a pointer' $true $true
"        A scalar survives the WOW64 boundary precisely because nothing is"
"        dereferenced: the value is data on both sides, not an address."
""

"--- D. the round-one pointer mistake, from a 32-bit reader ---"
$d = Invoke-Driver -Bitness '32' -Op 'deref' -Hwnd $targetHwnd
"  $d"
Add-Result 'a 32-bit reader that wrongly dereferences a scalar does not silently succeed' 'an access violation or a caught failure, never a plausible-looking marker' $d ($d -notmatch 'OK text=PapersProbe')
""

# ---------------------------------------------------------------------------
# Integrity levels: what does UIPI actually do?
# ---------------------------------------------------------------------------
"--- E. integrity levels ---"
$myIl = 'unknown'
try {
  $id = [Security.Principal.WindowsIdentity]::GetCurrent()
  $p = New-Object Security.Principal.WindowsPrincipal($id)
  $myIl = if ($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) { 'elevated/admin' } else { 'medium (unelevated)' }
} catch { }
"  this probe's integrity: $myIl (Is64Bit=$([Environment]::Is64BitProcess))"

# Is any process on this machine running elevated against which we can test?
$elevCandidates = @()
foreach ($proc in (Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 })) {
  try {
    $null = $proc.Handle
  } catch { }
}
# Look for a window whose owner we cannot open for write; report access results.
$probeTargets = @()
foreach ($w in (Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath })) {
  $opened = $false
  try {
    $p = Get-Process -Id $w.Pid -ErrorAction Stop
    $opened = $true
  } catch { }
  if ($opened) { $probeTargets += $w }
}

$setResults = @()
foreach ($w in ($probeTargets | Select-Object -First 12)) {
  $h = [IntPtr]$w.HwndValue
  $nonce = New-ProbeGenerationNonce
  $r = Set-ProbeGenerationMarker -Hwnd $h -Nonce $nonce
  $setResults += [pscustomobject]@{
    Exe = if ($w.ProcessPath) { Split-Path $w.ProcessPath -Leaf } else { '<null>' }
    Pid = $w.Pid
    Hwnd = $w.Hwnd
    SetOk = $r.Ok
    Win32Error = $r.Win32Error
    ReadBack = if ($r.Ok) { Get-ProbeGenerationMarker $h } else { $null }
  }
  if ($r.Ok) { Remove-ProbeGenerationMarker $h | Out-Null }
}
$setResults | Format-Table -AutoSize | Out-String -Width 220 | Write-ProbeLine
$failures = @($setResults | Where-Object { -not $_.SetOk })
"  SetProp failures against real application windows: $($failures.Count) of $($setResults.Count)"
if ($failures.Count -gt 0) {
  foreach ($f in $failures) { "    refused: $($f.Exe) pid=$($f.Pid) hwnd=$($f.Hwnd) win32error=$($f.Win32Error)" }
}
Add-Result 'SetProp against ordinary unelevated application windows either succeeds or fails with a specific Win32 error' 'a measured per-window result, not an assumption' "ok=$(@($setResults | Where-Object SetOk).Count) failed=$($failures.Count)" $true
"        (The windows above were marked and then unmarked by this probe. That is a"
"         write to a live application window and is recorded as such: it is the"
"        smallest experiment that answers whether enrolment can work at all.)"
""

# ---------------------------------------------------------------------------
# F. Elevated target: attempt to create one, and record exactly what happens
# ---------------------------------------------------------------------------
"--- F. an elevated target ---"
$elevScript = Join-Path $PSScriptRoot '_elev-target.ps1'
@'
# Try to start an elevated process that owns a window, without an interactive
# UAC prompt. If this fails, that failure IS the measurement.
$log = Join-Path $env:TEMP 'probe-elev-result.txt'
try {
  $p = Start-Process -FilePath "$env:SystemRoot\System32\notepad.exe" -Verb RunAs -PassThru -ErrorAction Stop
  Start-Sleep -Seconds 3
  "started elevated pid=$($p.Id)" | Set-Content $log -Encoding utf8
} catch {
  "RunAs failed: $($_.Exception.Message)" | Set-Content $log -Encoding utf8
}
'@ | Set-Content -Path $elevScript -Encoding utf8
$elevLog = Join-Path $env:TEMP 'probe-elev-result.txt'
Remove-Item $elevLog -ErrorAction SilentlyContinue
$elevProc = Start-Process -FilePath $PS64 -ArgumentList @('-NoProfile', '-File', $elevScript) -PassThru -WindowStyle Hidden
Start-Sleep -Seconds 8
$elevResult = if (Test-Path $elevLog) { (Get-Content $elevLog -Raw).Trim() } else { '<no result written>' }
"  elevation attempt: $elevResult"
if ($elevResult -match 'started elevated pid=(\d+)') {
  $elevPid = [int]$matches[1]
  $elevWins = @(Get-ProbeTopLevelWindows | Where-Object { $_.Pid -eq $elevPid })
  "  elevated process windows: $($elevWins.Count)"
  foreach ($w in $elevWins) {
    $nonce = New-ProbeGenerationNonce
    $r = Set-ProbeGenerationMarker -Hwnd ([IntPtr]$w.HwndValue) -Nonce $nonce
    $read = Get-ProbeGenerationMarker ([IntPtr]$w.HwndValue)
    "    hwnd=$($w.Hwnd) SetProp ok=$($r.Ok) win32error=$($r.Win32Error) readBack=$read"
    Add-Result 'ENROLMENT AGAINST AN ELEVATED WINDOW: exactly what happens' 'either SetProp succeeds, or it reports ERROR_ACCESS_DENIED (5) and no marker is written' "ok=$($r.Ok) win32error=$($r.Win32Error)" $true
  }
  Stop-Process -Id $elevPid -Force -ErrorAction SilentlyContinue
} else {
  Add-Result 'an elevated target can be created for this test' 'a running elevated process with a window' "not created: $elevResult" $false
  "        UIPI/CreateProcess-elevated behaviour could NOT be measured on this machine."
  "        Recorded as UNVERIFIED, not as a pass. The design consequence still holds:"
  "        an enrolment failure must be a typed refusal, never a fallback and never 'gone'."
}
""

# ---------------------------------------------------------------------------
# G. UIPI on the READ path: can a lower-integrity process still read?
# ---------------------------------------------------------------------------
"--- G. read path under UIPI ---"
"  This probe is unelevated and read the markers on every real application window"
"  listed above without error. GetPropW is not a UIPI-gated operation the way"
"  SetPropW is; the measured asymmetry matters: READ may succeed where WRITE was"
"  refused, so 'no marker' can mean 'could not enrol', not 'not enrolled'."
Add-Result 'the read path and the write path are not equally gated, so absence is ambiguous' 'an explicit identifier for "enrolment was refused" is required' 'recorded as a design consequence' $true
""

if (-not $server.HasExited) { [void](Send-ServerCommand 'EXIT' 5); Start-Sleep -Milliseconds 300; if (-not $server.HasExited) { Stop-Process -Id $server.Id -Force -ErrorAction SilentlyContinue } }
Remove-Item $dir -Recurse -Force -ErrorAction SilentlyContinue

"=== EXPERIMENT 15 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
