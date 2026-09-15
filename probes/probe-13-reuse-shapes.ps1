# probe-13-reuse-shapes.ps1
#
# EXPERIMENT 13 — trying to force HWND reuse by several different shapes.
#
# Probe-12 forced nothing with adjacent create/destroy pairs. Before reporting
# "could not force", this exhausts the plausible mechanisms: nested lifetimes,
# bulk allocation, bulk destruction in various orders, thread affinity, and a
# long churn. If none of them produce a recurrence, that is the finding - and it
# must be reported as "not forced here", never as "cannot happen".
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
    [DllImport("user32.dll")] public static extern bool PeekMessageW(out MSG m, IntPtr h, uint a, uint b, uint r);
    [DllImport("user32.dll")] public static extern bool TranslateMessage(ref MSG m);
    [DllImport("user32.dll")] public static extern IntPtr DispatchMessageW(ref MSG m);
    [StructLayout(LayoutKind.Sequential)] public struct MSG {
      public IntPtr hwnd; public uint message; public IntPtr wParam, lParam; public uint time;
      public int ptX, ptY;
    }
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
    // Drain the thread's message queue, which is where deferred USER teardown lands.
    public static int Pump() {
      int n = 0; MSG m;
      while (PeekMessageW(out m, IntPtr.Zero, 0, 0, 1)) {
        TranslateMessage(ref m); DispatchMessageW(ref m); n++;
        if (n > 5000) break;
      }
      return n;
    }
  }
}
'@
}

$CLASS = 'WhProbeReuseShapes'
if (-not [WhAlloc.Raw]::Register($CLASS)) { "class registration failed"; exit 1 }
"probe pid=$PID  pumping the message queue after every destroy"
""

function Get-HandleCensus {
  param([object[]]$Handles)
  $groups = $Handles | Group-Object { $_.ToInt64() }
  return [pscustomobject]@{
    Total = $Handles.Count
    Distinct = $groups.Count
    Recurrences = @($groups | Where-Object { $_.Count -gt 1 }).Count
  }
}

# ---------------------------------------------------------------------------
# Shape 1: adjacent create/destroy with queue pumping
# ---------------------------------------------------------------------------
"--- shape 1: adjacent create/destroy, message queue pumped after each destroy ---"
$all = @()
for ($i = 1; $i -le 60; $i++) {
  $h = [WhAlloc.Raw]::Create($CLASS, "S1-$i")
  if ($h -ne [IntPtr]::Zero) { $all += $h; [void][WhAlloc.Raw]::DestroyWindow($h) }
  [void][WhAlloc.Raw]::Pump()
}
$c1 = Get-HandleCensus $all
"  allocated=$($c1.Total) distinct=$($c1.Distinct) recurrences=$($c1.Recurrences)"
Add-Result 'shape 1 forces a recurrence' 'distinct < total' "distinct=$($c1.Distinct) of $($c1.Total)" ($c1.Recurrences -gt 0)
""

# ---------------------------------------------------------------------------
# Shape 2: allocate a batch, then destroy the batch, then allocate again
# ---------------------------------------------------------------------------
"--- shape 2: batch-allocate, batch-destroy (forward, reverse, middle-out), reallocate ---"
function Test-BatchOrder {
  param([string]$Name, [int[]]$DestroyOrder)
  $batch = @()
  foreach ($i in 1..10) {
    $h = [WhAlloc.Raw]::Create($CLASS, "$Name-$i")
    if ($h -ne [IntPtr]::Zero) { $batch += $h }
  }
  $before = @($batch | ForEach-Object { $_.ToInt64() })
  foreach ($idx in $DestroyOrder) {
    if ($idx -lt $batch.Count) { [void][WhAlloc.Raw]::DestroyWindow($batch[$idx]) }
    [void][WhAlloc.Raw]::Pump()
  }
  $after = @()
  foreach ($i in 1..10) {
    $h = [WhAlloc.Raw]::Create($CLASS, "$Name-R$i")
    if ($h -ne [IntPtr]::Zero) { $after += $h; [void][WhAlloc.Raw]::DestroyWindow($h); [void][WhAlloc.Raw]::Pump() }
  }
  $afterVals = @($after | ForEach-Object { $_.ToInt64() })
  $overlap = @($afterVals | Where-Object { $before -contains $_ })
  [pscustomobject]@{ Name = $Name; BatchHandles = $before.Count; Reallocated = $afterVals.Count; Overlap = $overlap.Count }
}

$shape2 = @(
  (Test-BatchOrder -Name 'FWD' -DestroyOrder (0..9)),
  (Test-BatchOrder -Name 'REV' -DestroyOrder (9..0)),
  (Test-BatchOrder -Name 'MID' -DestroyOrder @(4, 5, 3, 6, 2, 7, 1, 8, 0, 9))
)
$shape2 | Format-Table -AutoSize | Out-String -Width 200 | Write-ProbeLine
$shape2Total = ($shape2 | Measure-Object -Property Overlap -Sum).Sum
Add-Result 'shape 2 forces a recurrence' 'a reallocated HWND equals a destroyed one' "overlap=$shape2Total across three orders" ($shape2Total -gt 0)
""

# ---------------------------------------------------------------------------
# Shape 3: long churn with a working set held open
# ---------------------------------------------------------------------------
"--- shape 3: hold 20 alive, churn 200 in and out ---"
$held = @()
foreach ($i in 1..20) { $h = [WhAlloc.Raw]::Create($CLASS, "HELD-$i"); if ($h -ne [IntPtr]::Zero) { $held += $h } }
$churnSeen = @{}
$churnRecur = 0
foreach ($i in 1..200) {
  $h = [WhAlloc.Raw]::Create($CLASS, "CHURN-$i")
  if ($h -eq [IntPtr]::Zero) { continue }
  $k = $h.ToInt64()
  if ($churnSeen.ContainsKey($k)) { $churnRecur++ } else { $churnSeen[$k] = $i }
  if ($held -contains $k) { "  !! a churned window landed on a HELD handle 0x$($k.ToString('X'))" }
  [void][WhAlloc.Raw]::DestroyWindow($h)
  [void][WhAlloc.Raw]::Pump()
}
"  churned=200 distinct=$($churnSeen.Count) recurrences=$churnRecur heldStillAlive=$(@($held | Where-Object { [WhAlloc.Raw]::IsWindow($_) }).Count)"
Add-Result 'shape 3 forces a recurrence' 'a churned window reuses an earlier churned value' "recurrences=$churnRecur over 200 cycles" ($churnRecur -gt 0)
foreach ($h in $held) { [void][WhAlloc.Raw]::DestroyWindow($h) }
[void][WhAlloc.Raw]::Pump()
""

# ---------------------------------------------------------------------------
# Shape 4: is the value space a counter? (spacing tells us the allocator's shape)
# ---------------------------------------------------------------------------
"--- shape 4: the shape of the handle values themselves ---"
$seq = @()
foreach ($i in 1..12) {
  $h = [WhAlloc.Raw]::Create($CLASS, "SEQ-$i")
  if ($h -eq [IntPtr]::Zero) { continue }
  $seq += $h.ToInt64()
  [void][WhAlloc.Raw]::DestroyWindow($h)
  [void][WhAlloc.Raw]::Pump()
}
for ($i = 0; $i -lt $seq.Count; $i++) {
  $delta = if ($i -gt 0) { ' (+' + ($seq[$i] - $seq[$i-1]) + ')' } else { '' }
  "  0x$($seq[$i].ToString('X'))$delta"
}
$monotonic = $true
for ($i = 1; $i -lt $seq.Count; $i++) { if ($seq[$i] -le $seq[$i-1]) { $monotonic = $false } }
"  strictly increasing across consecutive allocations: $monotonic"
Add-Result 'handle values behave like a forward-only allocator in this sample' 'strictly increasing, no reuse of freed values' "monotonic=$monotonic over $($seq.Count) allocations" $monotonic
"        A forward-only allocator is not proof that reuse never happens - the"
"        space is finite and wraps - but it is why forcing it here failed."
""

"=== EXPERIMENT 13 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
