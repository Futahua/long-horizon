# probe-12-allocator-reuse.ps1
#
# EXPERIMENT 12 — does the window manager hand back a freed HWND slot?
#
# Probe-11 could not force reuse through WinForms: disposal there is entangled
# with the framework's own window management (control parking windows, deferred
# teardown), so a clean "create, kill, create" is not actually clean. This probe
# removes the framework and talks to the allocator directly with
# CreateWindowExW / DestroyWindow, which is the smallest experiment that can
# answer the question.
#
# Windows created here are this process's own. Nothing pre-existing is touched.

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
using System.Text;

namespace WhAlloc {
  public delegate IntPtr WndProc(IntPtr h, uint m, IntPtr w, IntPtr l);

  [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
  public struct WNDCLASSW {
    public uint style;
    public WndProc lpfnWndProc;
    public int cbClsExtra;
    public int cbWndExtra;
    public IntPtr hInstance;
    public IntPtr hIcon;
    public IntPtr hCursor;
    public IntPtr hbrBackground;
    public string lpszMenuName;
    public string lpszClassName;
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
    [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern bool SetPropW(IntPtr h, string name, IntPtr value);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr GetPropW(IntPtr h, string name);
    [DllImport("user32.dll", CharSet = CharSet.Unicode, SetLastError = true)]
    public static extern IntPtr RemovePropW(IntPtr h, string name);

    public static WndProc KeepAlive;   // prevent the delegate being collected

    public static bool Register(string className) {
      KeepAlive = delegate(IntPtr h, uint m, IntPtr w, IntPtr l) {
        return DefWindowProcW(h, m, w, l);
      };
      WNDCLASSW wc = new WNDCLASSW();
      wc.lpfnWndProc = KeepAlive;
      wc.hInstance = GetModuleHandleW(null);
      wc.lpszClassName = className;
      ushort atom = RegisterClassW(ref wc);
      return atom != 0;
    }

    public static IntPtr Create(string className, string title) {
      // WS_OVERLAPPEDWINDOW so the class/shape matches a real application window.
      return CreateWindowExW(0, className, title, 0x00CF0000, -4000, -4000, 300, 200,
        IntPtr.Zero, IntPtr.Zero, GetModuleHandleW(null), IntPtr.Zero);
    }
  }
}
'@
}

$CLASS = 'WhProbeRawReuseClass'
$registered = [WhAlloc.Raw]::Register($CLASS)
Add-Result 'a raw window class registers' 'RegisterClassW succeeds' "registered=$registered class=$CLASS" $registered
if (-not $registered) { exit 1 }
""

# ---------------------------------------------------------------------------
# A. Force reuse with a bare allocator loop
# ---------------------------------------------------------------------------
"--- A. create / destroy / create with no framework in the way ---"
$slots = @{}
$collisions = @()
$trials = 40
for ($i = 1; $i -le $trials; $i++) {
  $h = [WhAlloc.Raw]::Create($CLASS, "RAW-$i")
  if ($h -eq [IntPtr]::Zero) { "  create failed at trial $i (error $([System.Runtime.InteropServices.Marshal]::GetLastWin32Error()))"; continue }
  $key = $h.ToInt64()
  if ($slots.ContainsKey($key)) {
    $collisions += [pscustomobject]@{ Hwnd = ('0x{0:X}' -f $key); First = $slots[$key]; Now = $i }
  } else {
    $slots[$key] = $i
  }
  $destroyed = [WhAlloc.Raw]::DestroyWindow($h)
  $stillAlive = [WhAlloc.Raw]::IsWindow($h)
  if (-not $destroyed -or $stillAlive) { "  destroy at trial $i failed: destroyed=$destroyed stillAlive=$stillAlive" }
  # let any deferred teardown land, then continue
  Start-Sleep -Milliseconds 15
}

"  distinct HWND values allocated over $trials create/destroy cycles: $($slots.Count)"
if ($collisions.Count -gt 0) {
  "  HWND values that recurred:"
  $collisions | Select-Object -First 12 | Format-Table -AutoSize | Out-String -Width 160 | Write-ProbeLine
}
Add-Result 'FORCED: a create/destroy cycle hands the same HWND value back' 'at least one recurrence across 40 cycles' "recurrences=$($collisions.Count) over $trials cycles, distinct=$($slots.Count)" ($collisions.Count -gt 0)
""

# ---------------------------------------------------------------------------
# B. Deterministic reuse: kill one, create one, compare
# ---------------------------------------------------------------------------
"--- B. deterministic single-slot reuse ---"
$found = $null
foreach ($attempt in 1..60) {
  $a = [WhAlloc.Raw]::Create($CLASS, "PAIR-A-$attempt")
  if ($a -eq [IntPtr]::Zero) { continue }
  [void][WhAlloc.Raw]::DestroyWindow($a)
  Start-Sleep -Milliseconds 10
  $b = [WhAlloc.Raw]::Create($CLASS, "PAIR-B-$attempt")
  if ($b -eq [IntPtr]::Zero) { continue }
  if ($b.ToInt64() -eq $a.ToInt64()) { $found = [pscustomobject]@{ A = $a; B = $b; Attempt = $attempt }; break }
  [void][WhAlloc.Raw]::DestroyWindow($b)
  Start-Sleep -Milliseconds 10
}
if ($found) {
  Add-Result 'a destroyed HWND value is handed to the NEXT window created in the same process' 'identical value for a different window object' ("attempt $($found.Attempt): A=0x{0:X} B=0x{1:X}" -f $found.A.ToInt64(), $found.B.ToInt64()) $true
} else {
  Add-Result 'a destroyed HWND value is handed to the NEXT window created in the same process' 'identical value for a different window object' 'no adjacent reuse in 60 attempts' $false
}
""

# ---------------------------------------------------------------------------
# C. Same process, same class, same corroborators - and a marker
# ---------------------------------------------------------------------------
"--- C. the reviewer's counterexample, constructed on purpose ---"
$A = [WhAlloc.Raw]::Create($CLASS, 'COUNTEREXAMPLE-A')
$ABack = New-Object System.Text.StringBuilder 256
[void][WhAlloc.Raw]::GetWindowTextW($A, $ABack, $ABack.Capacity)
$scopeA = (Get-ProbeIdentityScope -Hwnd $A).Scope
$nonce = New-ProbeGenerationNonce
$enrolled = Set-ProbeGenerationMarker -Hwnd $A -Nonce $nonce
"  A: hwnd=0x$($A.ToInt64().ToString('X')) title='$($ABack.ToString())' pid=$($scopeA.pid) class=$($scopeA.className)"
"     enrolled generation nonce = $nonce (atom ok=$($enrolled.Ok))"
"     marker reads back as       = $(Get-ProbeGenerationMarker $A)"
"     process incarnation        = $($scopeA.processSequence) (source $($scopeA.incarnationSource))"
"     session                    = $($scopeA.sessionId)"
""

[void][WhAlloc.Raw]::DestroyWindow($A)
Start-Sleep -Milliseconds 20
$Adead = [WhAlloc.Raw]::IsWindow($A)
"  A destroyed: IsWindow=$Adead"
"  marker on the dead handle: '$(Get-ProbeGenerationMarker $A)'"
""

# Create until a new window lands on A's slot.
$B = [IntPtr]::Zero
foreach ($try in 1..80) {
  $c = [WhAlloc.Raw]::Create($CLASS, "COUNTEREXAMPLE-B-$try")
  if ($c -eq [IntPtr]::Zero) { continue }
  if ($c.ToInt64() -eq $A.ToInt64()) { $B = $c; break }
  [void][WhAlloc.Raw]::DestroyWindow($c)
  Start-Sleep -Milliseconds 10
}

if ($B -eq [IntPtr]::Zero) {
  Add-Result 'INVARIANT: a replacement object can be forced onto the killed slot' 'same numerical HWND, different window object' 'no collision forced in 80 attempts' $false
} else {
  $BBack = New-Object System.Text.StringBuilder 256
  [void][WhAlloc.Raw]::GetWindowTextW($B, $BBack, $BBack.Capacity)
  $scopeB = (Get-ProbeIdentityScope -Hwnd $B).Scope
  "  B: hwnd=0x$($B.ToInt64().ToString('X')) title='$($BBack.ToString())' pid=$($scopeB.pid) class=$($scopeB.className)"
  Add-Result 'the replacement occupies the SAME numerical HWND as the killed window' 'identical handle value' "A=0x$($A.ToInt64().ToString('X')) B=0x$($B.ToInt64().ToString('X'))" ($B.ToInt64() -eq $A.ToInt64())
  Add-Result 'the replacement is a DIFFERENT window object (its own title)' 'a different title proves it is not the same window' "A='$($ABack.ToString())' B='$($BBack.ToString())'" ($BBack.ToString() -ne $ABack.ToString())

  $corrob = [ordered]@{
    'same PID'              = ($scopeA.pid -eq $scopeB.pid)
    'same process creation' = ($scopeA.processCreatedUtc -eq $scopeB.processCreatedUtc)
    'same process sequence' = ($null -ne $scopeB.processSequence -and $scopeA.processSequence -eq $scopeB.processSequence)
    'same window class'     = ($scopeA.className -eq $scopeB.className)
    'same boot'             = ($scopeA.bootId -eq $scopeB.bootId)
    'same session'          = ($scopeA.sessionId -eq $scopeB.sessionId)
  }
  foreach ($k in $corrob.Keys) { "    {0,-26} {1}" -f $k, $corrob[$k] }
  $allPass = -not ($corrob.Values -contains $false)
  ""

  $check = Get-ProbeIdentityScope -Hwnd $B -Expected $scopeA
  Add-Result 'EVERY round-one corroborator matches the replacement object' 'all identical: corroborators alone cannot separate A from B' "all-match=$allPass" $allPass
  Add-Result 'corroborators alone VERIFY the replacement as the enrolled instance' 'Verified=true - this is the exact hole the reviewer named' "Verified=$($check.Verified) mismatches=$($check.Mismatches.Count) unverified=$($check.Unverified.Count)" ($check.Verified -eq $true)

  $markerOnB = Get-ProbeGenerationMarker $B
  Add-Result 'INVARIANT HOLDS: the replacement does NOT carry the enrolled marker' 'marker absent on the replacement object' "marker on B = '$markerOnB'" ($null -eq $markerOnB)

  # And the decisive falsification test: does a WINDOW-CLASS property survive?
  # SetClassLongPtr would be shared by every window of the class - measuring that
  # is what tells us the marker must be a WINDOW property, not a class property.
  "  (window-class storage is measured separately in probe-14: a class-wide value"
  "   would be inherited by every window of the class, including the replacement.)"

  [void][WhAlloc.Raw]::DestroyWindow($B)
}
""

"=== EXPERIMENT 12 VERDICTS ==="
$results | Format-Table -AutoSize | Out-String -Width 300
"PASS: $(($results | Where-Object Verdict -eq 'PASS').Count)  FAIL: $(($results | Where-Object Verdict -eq 'FAIL').Count)"
