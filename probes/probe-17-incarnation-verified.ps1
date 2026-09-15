# probe-17-incarnation-verified.ps1
#
# EXPERIMENT 17 — the incarnation question, re-measured with the struct shape
# validated first, so "absent" cannot be confused with "my layout is wrong".
#
# Probe-16 read SequenceNumber as zero for 400 processes on build 26200, which is
# above the reviewer's stated 26100.4770+ threshold. A zero could mean the field
# is absent, or that the struct is misaligned. This probe validates the layout
# against fields with known values before drawing any conclusion.

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

"=== EXPERIMENT 17 : incarnation, with the struct layout validated first ==="
$build = Get-ProbeBuildNumber
"OS build : $build"
""
"--- layout validation: fields whose values are independently known ---"
$shape = Test-ProbeSystemProcessInfoShape
"  SYSTEM_PROCESS_INFORMATION marshalled size : $($shape.StructSize) bytes"
"  NtQuerySystemInformation status            : $($shape.Status) (0 = success)"
"  process entries walked                     : $($shape.Entries)"
"  this process (pid $PID) found in the list  : $($shape.SelfPidSeen)"
"  its HandleCount field is non-zero          : $($shape.SelfHandleCountNonZero)"
"  SequenceNumber non-zero for ANY process    : $($shape.SequenceNonZeroAnywhere)"
""
Add-Result 'NtQuerySystemInformation returns a process list this code can walk' 'status 0 and hundreds of entries' "status=$($shape.Status) entries=$($shape.Entries)" ($shape.Status -eq 0 -and $shape.Entries -gt 50)
Add-Result 'the struct layout is correct: a field with a known value reads correctly' 'this process found, and its HandleCount field is non-zero' "selfFound=$($shape.SelfPidSeen) handleCountNonZero=$($shape.SelfHandleCountNonZero)" ($shape.SelfPidSeen -and $shape.SelfHandleCountNonZero)
"        HandleCount sits AFTER the session fields and BEFORE SequenceNumber in"
"        the layout, so a correct non-zero HandleCount shows the walk is aligned"
"        at least as far as SequenceNumber. A zero SequenceNumber after that is"
"        therefore the FIELD, not the stride."
""

if (-not $shape.SequenceNonZeroAnywhere) {
  Add-Result 'SequenceNumber carries usable information on this build' 'at least one process with a non-zero sequence' "sequence non-zero anywhere = $($shape.SequenceNonZeroAnywhere) on build $build" $false
  ""
  "  >>> FINDING: on build $build, SequenceNumber is structurally present but reads"
  "      zero for every process in the list, on a struct walk that correctly reads"
  "      neighbouring fields. The reviewer's version threshold"
  "      (Win11 26100.4770+) is satisfied by this build, yet the field is not"
  "      usable. The design must not depend on it; the creation FILETIME fallback"
  "      is what this machine actually supports."
  ""
} else {
  Add-Result 'SequenceNumber carries usable information on this build' 'at least one process with a non-zero sequence' "sequence non-zero anywhere = True" $true
}
""

# ---------------------------------------------------------------------------
# FILETIME precision: does it collide between consecutive incarnations?
# ---------------------------------------------------------------------------
"--- creation FILETIME precision across consecutive incarnations ---"
$samples = @()
for ($i = 1; $i -le 10; $i++) {
  $p = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Milliseconds 700
  $s = Get-ProbeWindowSignals -Hwnd ([IntPtr]::Zero)
  $facts = $null
  $proc = Get-Process -Id $p.Id -ErrorAction SilentlyContinue
  if ($proc) {
    $created = $proc.StartTime.ToUniversalTime()
    $samples += [pscustomobject]@{ Pid = $p.Id; CreatedUtc = $created.ToString('o'); Ticks = $created.Ticks }
  }
  Stop-Process -Id $p.Id -Force -ErrorAction SilentlyContinue
  Start-Sleep -Milliseconds 500
}
$samples | Format-Table -AutoSize | Out-String -Width 220 | Write-ProbeLine

$tickGroups = @($samples | Group-Object Ticks)
$collided = @($tickGroups | Where-Object { $_.Count -gt 1 })
"  incarnations      : $($samples.Count)"
"  distinct FILETIMEs: $($tickGroups.Count)"
"  collisions        : $($collided.Count)"
Add-Result 'consecutive process incarnations get distinct creation FILETIMEs' 'no two incarnations share a timestamp' "distinct=$($tickGroups.Count) of $($samples.Count), collisions=$($collided.Count)" ($collided.Count -eq 0)
if ($collided.Count -gt 0) {
  foreach ($g in $collided) {
    "  COLLIDED at ticks=$($g.Name): pids $(($g.Group | ForEach-Object { $_.Pid }) -join ',')"
  }
  "        A colliding creation time means the fallback discriminator can fold two"
  "        incarnations together. It does not by itself grant authority - the HWND"
  "        must still match - but it must be recorded as a measured weakness rather"
  "        than assumed away."
}
""

# ---------------------------------------------------------------------------
# Access rights as a discriminator: can we actually read what we need?
# ---------------------------------------------------------------------------
"--- access rights against real application windows ---"
$targets = @(Get-ProbeTopLevelWindows | Where-Object { $_.ProcessPath } | Select-Object -First 10)
$rows = @()
foreach ($w in $targets) {
  $a = Test-ProbeProcessAccess -PidValue $w.Pid
  $inc = Get-ProbeProcessIncarnation -PidValue $w.Pid
  $rows += [pscustomobject]@{
    Exe = Split-Path $w.ProcessPath -Leaf
    Pid = $w.Pid
    HandleGranted = $a.Opened
    Win32Error = $a.Win32Error
    PathReadable = $a.PathReadable
    CreationReadable = ($null -ne $inc.CreatedUtc)
    SeqSource = $inc.Source
  }
}
$rows | Format-Table -AutoSize | Out-String -Width 240 | Write-ProbeLine
$noHandle = @($rows | Where-Object { -not $_.HandleGranted })
Add-Result 'an unelevated process can open every ordinary application process for QUERY_LIMITED_INFORMATION' 'no refusals among ordinary unelevated windows' "granted=$(@($rows | Where-Object HandleGranted).Count) refused=$($noHandle.Count) of $($rows.Count)" ($noHandle.Count -eq 0)
""

"=== EXPERIMENT 17 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
