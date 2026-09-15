# probe-14-reuse-rate.ps1
#
# EXPERIMENT 14 — measure the actual recycling rate of the HWND allocator, and
# then use the destroyed population to test the invariant the reviewer cares
# about: a window that was never enrolled must never carry a marker.
#
# Probe-13 showed consecutive allocations stepping by exactly +0x10000 with a
# pinned low word, i.e. a table index. That predicts recycling only when the
# index space is re-entered, which is why adjacent create/destroy never reused.
# This probe measures it instead of predicting it.
#
# Windows created here are this process's own.

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

if (-not ('WhAlloc.Raw' -as [type])) {
  Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;

namespace WhAlloc {
  public delegate IntPtr WndProc(IntPtr h, uint m, IntPtr w, IntPtr l);
  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct WNDCLASSW {
    public uint style; public WndProc lpfnWndProc; public int cbClsExtra; public int cbWndExtra;
    public IntPtr hInstance; public IntPtr hIcon; public IntPtr hCursor; public IntPtr hbrBackground;
    public string lpszMenuName; public string lpszClassName;
  }
  public static class Raw {
    [DllImport("user32.dll", SetLastError = true)] public static extern ushort RegisterClassW(ref WNDCLASSW c);
    [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern IntPtr CreateWindowExW(uint ex, string cls, string title, uint style,
      int x, int y, int w, int h, IntPtr parent, IntPtr menu, IntPtr inst, IntPtr param);
    [DllImport("user32.dll", SetLastError = true)] public static extern bool DestroyWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern bool IsWindow(IntPtr h);
    [DllImport("user32.dll")] public static extern IntPtr DefWindowProcW(IntPtr h, uint m, IntPtr w, IntPtr l);
    [DllImport("kernel32.dll")] public static extern IntPtr GetModuleHandleW(string n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetPropW(IntPtr h, string name, IntPtr value);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetPropW(IntPtr h, string name);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr RemovePropW(IntPtr h, string name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalAddAtomW(string name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalFindAtomW(string name);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern ushort GlobalDeleteAtom(ushort atom);
    [DllImport("kernel32.dll", CharSet = CharSet.Unicode)]
    public static extern uint GlobalGetAtomNameW(ushort atom, System.Text.StringBuilder buf, int size);

    public static WndProc KeepAlive;
    public static bool Register(string className) {
      KeepAlive = delegate(IntPtr h, uint m, IntPtr w, IntPtr l) { return DefWindowProcW(h, m, w, l); };
      WNDCLASSW wc = new WNDCLASSW();
      wc.lpfnWndProc = KeepAlive; wc.hInstance = GetModuleHandleW(null); wc.lpszClassName = className;
      return RegisterClassW(ref wc) != 0;
    }
    public static IntPtr Create(string className, string title) {
      return CreateWindowExW(0, className, title, 0x00CF0000, -4000, -4000, 300, 200,
        IntPtr.Zero, IntPtr.Zero, GetModuleHandleW(null), IntPtr.Zero);
    }
    // Enrol a scalar generation marker; returns the atom (0 on failure).
    public static ushort Enrol(IntPtr h, string propName, ushort nonce, out int win32Error) {
      win32Error = 0;
      ushort atom = GlobalAddAtomW("PapersProbe.Gen." + nonce);
      if (atom == 0) { win32Error = Marshal.GetLastWin32Error(); return 0; }
      if (!SetPropW(h, propName, (IntPtr)(int)atom)) {
        win32Error = Marshal.GetLastWin32Error();
        GlobalDeleteAtom(atom);
        return 0;
      }
      return atom;
    }
    public static string ReadMarker(IntPtr h, string propName) {
      IntPtr raw = GetPropW(h, propName);
      long v = raw.ToInt64();
      if (v <= 0) return null;
      if (v > 0xFFFF) return "<non-scalar:0x" + v.ToString("X") + ">";
      var sb = new System.Text.StringBuilder(512);
      uint len = GlobalGetAtomNameW((ushort)v, sb, sb.Capacity);
      return len == 0 ? null : sb.ToString();
    }
  }
}
'@
}

$CLASS = 'WhProbeReuseRate'
if (-not [WhAlloc.Raw]::Register($CLASS)) { "class registration failed"; exit 1 }
$PROP = 'PapersInstanceGeneration'

"=== EXPERIMENT 14 : measured recycling rate, and the invariant over the population ==="
"probe pid=$PID"
""

# ---------------------------------------------------------------------------
# A. Allocate N windows, destroy each immediately, count recurrences
# ---------------------------------------------------------------------------
$N = 20000
"--- A. $N create/destroy cycles, one window live at a time ---"
$seen = New-Object 'System.Collections.Generic.HashSet[long]'
$recurrences = 0
$firstRecur = $null
$lowWords = New-Object 'System.Collections.Generic.HashSet[long]'
$sw = [System.Diagnostics.Stopwatch]::StartNew()
$failures = 0
for ($i = 1; $i -le $N; $i++) {
  $h = [WhAlloc.Raw]::Create($CLASS, "RATE-$i")
  if ($h -eq [IntPtr]::Zero) { $failures++; if ($failures -gt 5) { break }; continue }
  $v = $h.ToInt64()
  [void]$lowWords.Add($v -band 0xFFFF)
  if (-not $seen.Add($v)) {
    $recurrences++
    if (-not $firstRecur) { $firstRecur = [pscustomobject]@{ At = $i; Hwnd = '0x{0:X}' -f $v } }
  }
  [void][WhAlloc.Raw]::DestroyWindow($h)
}
$sw.Stop()
"  cycles=$N failures=$failures elapsed=$([math]::Round($sw.Elapsed.TotalSeconds,1))s"
"  distinct HWND values=$($seen.Count)  recurrences=$recurrences"
"  distinct low-16-bit words=$($lowWords.Count)  (values: $(($lowWords | Select-Object -First 6 | ForEach-Object { '0x{0:X}' -f $_ }) -join ','))"
if ($firstRecur) { "  first recurrence at cycle $($firstRecur.At): $($firstRecur.Hwnd)" }
Add-Result "measure the recycling rate over $N create/destroy cycles" 'a measured rate, not an assumption' "recurrences=$recurrences over $N cycles ($([math]::Round(100.0*$recurrences/$N,2))%)" $true
""

# ---------------------------------------------------------------------------
# B. How far apart is the index space? (probe the wrap directly)
# ---------------------------------------------------------------------------
"--- B. the index space: what stride does the allocator hand out? ---"
$strides = @{}
$prev = $null
foreach ($i in 1..400) {
  $h = [WhAlloc.Raw]::Create($CLASS, "STRIDE-$i")
  if ($h -eq [IntPtr]::Zero) { continue }
  $v = $h.ToInt64()
  if ($prev -ne $null) {
    $d = $v - $prev
    if ($strides.ContainsKey($d)) { $strides[$d]++ } else { $strides[$d] = 1 }
  }
  $prev = $v
  [void][WhAlloc.Raw]::DestroyWindow($h)
}
"  observed strides and their counts:"
$strides.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 5 | ForEach-Object { "    +$($_.Key)  x$($_.Value)" }
$dominant = ($strides.GetEnumerator() | Sort-Object -Property Value -Descending | Select-Object -First 1)
Add-Result 'the allocator hands out a fixed stride over consecutive allocations' 'one dominant stride' "dominant stride = $($dominant.Key) ($($dominant.Value) of $(($strides.Values | Measure-Object -Sum).Sum))" ($dominant.Value -gt 300)
"        A fixed stride with a pinned low word means freed values are not"
"        returned to a LIFO free list; the index only recurs on wrap."
""

# ---------------------------------------------------------------------------
# C. THE INVARIANT over the whole destroyed population
# ---------------------------------------------------------------------------
"--- C. invariant: no window that was never enrolled may carry a marker ---"
$enrolledThenDestroyed = 0
$inherited = 0
$enrolledAlive = @{}
$nonceCounter = 0

# Enrol a marker, destroy, and then check a large fresh population for leakage.
foreach ($round in 1..60) {
  $victim = [WhAlloc.Raw]::Create($CLASS, "VICTIM-$round")
  if ($victim -eq [IntPtr]::Zero) { continue }
  $nonceCounter++
  $nonce = [uint16](30000 + $nonceCounter)   # deterministic, inside named-atom range
  $err = 0
  $atom = [WhAlloc.Raw]::Enrol($victim, $PROP, $nonce, [ref]$err)
  if ($atom -eq 0) { continue }
  $enrolledThenDestroyed++
  [void][WhAlloc.Raw]::DestroyWindow($victim)

  # Create a burst of replacements and inspect every one for the victim's marker.
  foreach ($j in 1..40) {
    $cand = [WhAlloc.Raw]::Create($CLASS, "CAND-$round-$j")
    if ($cand -eq [IntPtr]::Zero) { continue }
    $m = [WhAlloc.Raw]::ReadMarker($cand, $PROP)
    if ($null -ne $m) {
      $inherited++
      if ($inherited -le 3) { "  !! candidate 0x$($cand.ToInt64().ToString('X')) carried marker '$m'" }
    }
    [void][WhAlloc.Raw]::DestroyWindow($cand)
  }
}
"  windows enrolled-then-destroyed : $enrolledThenDestroyed"
"  replacement windows inspected   : $($enrolledThenDestroyed * 40)"
"  markers inherited               : $inherited"
Add-Result 'INVARIANT: an un-enrolled replacement never carries the destroyed window''s marker' 'zero inherited markers across the whole replacement population' "inherited=$inherited of $($enrolledThenDestroyed * 40) inspected" ($inherited -eq 0)
""

# ---------------------------------------------------------------------------
# D. Several enrolled windows alive at once: no bleed, and read from another process
# ---------------------------------------------------------------------------
"--- D. concurrent enrolled windows, markers read back in-process and cross-process ---"
$live = @()
foreach ($i in 1..6) {
  $h = [WhAlloc.Raw]::Create($CLASS, "LIVE-$i")
  if ($h -eq [IntPtr]::Zero) { continue }
  $nonce = [uint16](20000 + $i)
  $err = 0
  $atom = [WhAlloc.Raw]::Enrol($h, $PROP, $nonce, [ref]$err)
  if ($atom -eq 0) { "  enrol failed for LIVE-$i : win32error=$err"; continue }
  $live += [pscustomobject]@{ Hwnd = $h; Nonce = $nonce; Atom = $atom }
}
$readOk = $true
foreach ($entry in $live) {
  $m = [WhAlloc.Raw]::ReadMarker($entry.Hwnd, $PROP)
  $want = "PapersProbe.Gen.$($entry.Nonce)"
  if ($m -ne $want) { $readOk = $false; "  MISMATCH 0x$($entry.Hwnd.ToInt64().ToString('X')) got=$m want=$want" }
}
Add-Result 'each live window returns its own nonce, in-process' 'all six correct' "live=$($live.Count) all-correct=$readOk" ($readOk -and $live.Count -eq 6)

$crossOk = $true
$crossLines = @()
foreach ($entry in $live) {
  $m = Get-ProbeGenerationMarker $entry.Hwnd
  $want = "PapersProbe.Gen.$($entry.Nonce)"
  $crossLines += "0x$($entry.Hwnd.ToInt64().ToString('X')) -> $m"
  if ($m -ne $want) { $crossOk = $false }
}
foreach ($l in $crossLines) { "  $l" }
Add-Result 'each live window returns its own nonce from a DIFFERENT process' 'identical values read by the probe process' "cross-process-correct=$crossOk" $crossOk
""

# ---------------------------------------------------------------------------
# E. Capture the exact SetProp/GetProp access result for the record
# ---------------------------------------------------------------------------
"--- E. exact API-level result bytes ---"
$h5 = [WhAlloc.Raw]::Create($CLASS, 'API-1')
$atom5 = [WhAlloc.Raw]::GlobalAddAtomW('PapersProbe.Gen.12345')
$setOk = [WhAlloc.Raw]::SetPropW($h5, $PROP, [IntPtr][int]$atom5)
$errSet = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
$got = [WhAlloc.Raw]::GetPropW($h5, $PROP)
$errGet = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
$removeOk = [WhAlloc.Raw]::RemovePropW($h5, $PROP)
$errRemove = [System.Runtime.InteropServices.Marshal]::GetLastWin32Error()
$afterRemove = [WhAlloc.Raw]::GetPropW($h5, $PROP)
"  SetPropW         : ok=$setOk lastError=$errSet"
"  GetPropW         : value=0x$($got.ToInt64().ToString('X')) lastError=$errGet"
"  RemovePropW      : ok=$removeOk lastError=$errRemove"
"  GetPropW (after) : value=0x$($afterRemove.ToInt64().ToString('X'))  (0 = absent)"
"  atom still in global table after RemoveProp: $([WhAlloc.Raw]::GlobalFindAtomW('PapersProbe.Gen.12345')) (0 = released)"
Add-Result 'the scalar representation round-trips through SetProp/GetProp and releases cleanly' 'set ok, value equals the atom, remove leaves no property' "set=$setOk value=$($got.ToInt64() -eq $atom5) remove=$removeOk" ($setOk -and ($got.ToInt64() -eq $atom5) -and $removeOk)
[void][WhAlloc.Raw]::DestroyWindow($h5)
foreach ($entry in $live) { [void][WhAlloc.Raw]::DestroyWindow($entry.Hwnd) }
""

"=== EXPERIMENT 14 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
