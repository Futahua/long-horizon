# probe-18-sequence-number.ps1
#
# EXPERIMENT 18 — get the SYSTEM_PROCESS_INFORMATION layout right, then answer the
# SequenceNumber question honestly.
#
# probe-16 reported "SequenceNumber absent for 400 processes" on build 26200. That
# was WRONG: the native call was returning STATUS_INFO_LENGTH_MISMATCH
# (0xC0000004) and the walk never ran, so the zeroes were the absence of a
# measurement, not the absence of a field. This probe reports the raw status
# first, validates the layout against fields with independently known values, and
# only then draws a conclusion.
#
# Method: walk the buffer as a raw pointer with explicit offsets, so no marshalled
# struct layout can silently differ from the native one.

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

if (-not ('WhSpi.Raw' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace WhSpi {
  public static class Raw {
    [DllImport("ntdll.dll")]
    public static extern int NtQuerySystemInformation(int cls, IntPtr info, int len, out int ret);
    [DllImport("kernel32.dll")] public static extern IntPtr GetCurrentProcess();
    [DllImport("kernel32.dll")] public static extern uint GetCurrentProcessId();

    // Raw-offset readers: no struct marshalling, so the native layout is the only
    // thing that decides what we read.
    public static uint U32(IntPtr b, int off) { return unchecked((uint)Marshal.ReadInt32(b, off)); }
    public static IntPtr Ptr(IntPtr b, int off) { return Marshal.ReadIntPtr(b, off); }
    public static int I32(IntPtr b, int off) { return Marshal.ReadInt32(b, off); }
    public static long I64(IntPtr b, int off) { return Marshal.ReadInt64(b, off); }
  }
}
'@
}

"=== EXPERIMENT 18 : is SequenceNumber usable on this machine? ==="
$build = Get-ProbeBuildNumber
"OS build : $build   (reviewer threshold for the field: 26100.4770+)"
""

# ---------------------------------------------------------------------------
# 1. Call it properly: grow the buffer until it fits, and report every status.
# ---------------------------------------------------------------------------
"--- 1. growing the buffer until the call succeeds ---"
$buf = [IntPtr]::Zero
$size = 1MB
$status = 0
$retLen = 0
$attempts = @()
for ($i = 0; $i -lt 6; $i++) {
  if ($buf -ne [IntPtr]::Zero) { [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf) }
  $buf = [System.Runtime.InteropServices.Marshal]::AllocHGlobal([int]$size)
  $status = [WhSpi.Raw]::NtQuerySystemInformation(57, $buf, [int]$size, [ref]$retLen)
  $attempts += "size=$([math]::Round($size/1KB))KB status=0x$($status.ToString('X8')) needed=$([math]::Round($retLen/1KB))KB"
  if ($status -eq 0) { break }
  $size = [int]($size * 2)
}
foreach ($a in $attempts) { "  $a" }
"  final status : 0x$($status.ToString('X8')) ($(if ($status -eq 0) { 'STATUS_SUCCESS' } elseif ($status -eq 0xC0000004) { 'STATUS_INFO_LENGTH_MISMATCH' } else { 'other' }))"
Add-Result 'NtQuerySystemInformation(SystemProcessInformation) succeeds' 'status 0' "status=0x$($status.ToString('X8')) after $($attempts.Count) size attempts" ($status -eq 0)
if ($status -ne 0) {
  "  cannot answer the SequenceNumber question without a successful call; stopping."
  exit 1
}
""

# ---------------------------------------------------------------------------
# 2. Validate the offset map against independently known values.
# ---------------------------------------------------------------------------
"--- 2. validating the offsets against known values ---"
# Offsets are taken from the documented layout walked as raw bytes:
#   +0x00 NextEntryOffset (u32)   +0x04 NumberOfThreads (u32)
#   +0x38 UniqueProcessId (ptr)   +0x48 HandleCount (u32)*
#   +0x4C SessionId (u32)         +0x64 WorkingSetSize (ptr)
#   +0x64+...                     SequenceNumber (u32) near the end
$myPid = [WhSpi.Raw]::GetCurrentProcessId()
$offsets = @{
  NextEntryOffset = 0x00
  NumberOfThreads = 0x04
  UniqueProcessId = 0x38
  HandleCount     = 0x48
  SessionId       = 0x4C
  WorkingSet      = 0x60
}

$selfPtr = [IntPtr]::Zero
$entries = 0
$off = 0
while ($true) {
  $p = [IntPtr]::Add($buf, $off)
  $entries++
  $pidRead = if ([IntPtr]::Size -eq 8) { [WhSpi.Raw]::I64($p, $offsets.UniqueProcessId) } else { [WhSpi.Raw]::I32($p, $offsets.UniqueProcessId) }
  if ($pidRead -eq $myPid) { $selfPtr = $p }
  $next = [WhSpi.Raw]::U32($p, $offsets.NextEntryOffset)
  if ($next -eq 0) { break }
  $off += [int]$next
  if ($entries -gt 5000) { break }
}
"  entries walked      : $entries"
"  this process found  : $($selfPtr -ne [IntPtr]::Zero) (pid $myPid)"
Add-Result 'the process list walks cleanly to the end' 'hundreds of entries and this process among them' "entries=$entries selfFound=$($selfPtr -ne [IntPtr]::Zero)" ($entries -gt 50 -and $selfPtr -ne [IntPtr]::Zero)

if ($selfPtr -ne [IntPtr]::Zero) {
  $handleCount = [WhSpi.Raw]::U32($selfPtr, $offsets.HandleCount)
  $sessionId = [WhSpi.Raw]::U32($selfPtr, $offsets.SessionId)
  $threads = [WhSpi.Raw]::U32($selfPtr, $offsets.NumberOfThreads)
  $realHandles = @(Get-Process -Id $myPid).HandleCount
  $realThreads = @(Get-Process -Id $myPid).Threads.Count
  $realSession = (Get-Process -Id $myPid).SessionId
  "  HandleCount via NtQuery : $handleCount   (Get-Process says $realHandles)"
  "  NumberOfThreads via NtQuery : $threads  (Get-Process says $realThreads)"
  "  SessionId via NtQuery   : $sessionId    (Get-Process says $realSession)"
  $layoutOk = ([math]::Abs([int]$handleCount - [int]$realHandles) -le 8) -and ($sessionId -eq $realSession)
  Add-Result 'the offset map is correct: independently known fields read correctly' 'HandleCount near Get-Process and SessionId exact' "handle=$handleCount~$realHandles session=$sessionId==$realSession threads=$threads~$realThreads" $layoutOk
  if (-not $layoutOk) {
    "  the offset map is not trustworthy; the SequenceNumber question stays open."
    exit 1
  } else {
    "        HandleCount and SessionId sit before SequenceNumber in the layout, so a"
    "        correct read of them shows the offsets are aligned at least that far."
  }
}
""

# ---------------------------------------------------------------------------
# 3. Now the actual question, over every process in the list.
# ---------------------------------------------------------------------------
"--- 3. reading the trailing 32-bit fields of every entry ---"
$candidates = @(0xA8, 0xAC, 0xB0, 0xB4, 0xB8, 0xBC, 0xC0, 0xC4, 0xC8, 0xCC)
$histogram = @{}
foreach ($c in $candidates) { $histogram[$c] = @{ NonZero = 0; Total = 0; Sample = $null } }

$off = 0
$count = 0
while ($true) {
  $p = [IntPtr]::Add($buf, $off)
  $count++
  foreach ($c in $candidates) {
    $v = [WhSpi.Raw]::U32($p, $c)
    $histogram[$c].Total++
    if ($v -ne 0) {
      $histogram[$c].NonZero++
      if ($null -eq $histogram[$c].Sample) { $histogram[$c].Sample = $v }
    }
  }
  $next = [WhSpi.Raw]::U32($p, 0)
  if ($next -eq 0) { break }
  $off += [int]$next
  if ($count -gt 5000) { break }
}
"  entries inspected: $count"
"  offset   non-zero entries   first sample"
foreach ($c in $candidates) {
  $h = $histogram[$c]
  "  0x{0:X3}    {1,6} of {2,-6}  {3}" -f $c, $h.NonZero, $h.Total, $(if ($h.Sample) { $h.Sample } else { '-' })
}
""
$anyUsable = @($candidates | Where-Object { $histogram[$_].NonZero -gt 0 })
if ($anyUsable.Count -gt 0) {
  "  a non-zero 32-bit field exists at offsets: $(($anyUsable | ForEach-Object { '0x{0:X}' -f $_ }) -join ', ')"
  "  (candidates only: without the exact native layout this locates a populated"
  "   field, not necessarily SequenceNumber. Recorded as a location, not a name.)"
} else {
  "  every candidate trailing offset is zero for every process."
}
Add-Result 'a populated incarnation-like field exists among the trailing offsets' 'at least one candidate offset is non-zero somewhere' "non-zero offsets: $($anyUsable.Count)" ($anyUsable.Count -gt 0)
""

# ---------------------------------------------------------------------------
# 4. Does any candidate behave like an incarnation (distinct per process)?
# ---------------------------------------------------------------------------
"--- 4. does a candidate behave like an incarnation? ---"
if ($anyUsable.Count -gt 0) {
  $probe = $anyUsable[0]
  $map = @{}
  $off = 0; $n = 0
  while ($true) {
    $p = [IntPtr]::Add($buf, $off)
    $n++
    $pidRead = if ([IntPtr]::Size -eq 8) { [WhSpi.Raw]::I64($p, 0x38) } else { [WhSpi.Raw]::I32($p, 0x38) }
    $map[[int64]$pidRead] = [WhSpi.Raw]::U32($p, $probe)
    $next = [WhSpi.Raw]::U32($p, 0)
    if ($next -eq 0) { break }
    $off += [int]$next
    if ($n -gt 5000) { break }
  }
  $vals = @($map.Values | Where-Object { $_ -ne 0 })
  "  offset 0x$($probe.ToString('X')): $($vals.Count) processes with a non-zero value, $(@($vals | Select-Object -Unique).Count) distinct values"
  # Track one process across restarts to see if the value changes with incarnation.
  $tmpA = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Seconds 2
  $tmpB = Start-Process -FilePath 'notepad.exe' -PassThru
  Start-Sleep -Seconds 2
  $buf2 = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($size)
  $st2 = [WhSpi.Raw]::NtQuerySystemInformation(57, $buf2, $size, [ref]$retLen)
  $pair = @{}
  if ($st2 -eq 0) {
    $off2 = 0; $n2 = 0
    while ($true) {
      $p2 = [IntPtr]::Add($buf2, $off2)
      $n2++
      $pidRead = if ([IntPtr]::Size -eq 8) { [WhSpi.Raw]::I64($p2, 0x38) } else { [WhSpi.Raw]::I32($p2, 0x38) }
      if ($pidRead -eq $tmpA.Id -or $pidRead -eq $tmpB.Id) { $pair[[int]$pidRead] = [WhSpi.Raw]::U32($p2, $probe) }
      $next = [WhSpi.Raw]::U32($p2, 0)
      if ($next -eq 0) { break }
      $off2 += [int]$next
      if ($n2 -gt 5000) { break }
    }
  }
  [System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf2)
  "  two concurrent notepads: $(($pair.GetEnumerator() | ForEach-Object { "pid=$($_.Key) value=$($_.Value)" }) -join '  |  ')"
  Stop-Process -Id $tmpA.Id -Force -ErrorAction SilentlyContinue
  Stop-Process -Id $tmpB.Id -Force -ErrorAction SilentlyContinue
} 
""

[System.Runtime.InteropServices.Marshal]::FreeHGlobal($buf)

"=== EXPERIMENT 18 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
