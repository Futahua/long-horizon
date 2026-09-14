param([long]$TargetHwnd = 0)

# _inner-enum.ps1 -- the measuring script that runs IN PLACE of the window helper.
#
# It performs the same EnumWindows the helper performs, using only P/Invoke, and
# reports what it can see. Running the same code under different launch shapes is
# how probe-07 tells a fact about Windows from an artefact of how the helper was
# started. Required by probe-07-launch-shape.ps1.

Add-Type -TypeDefinition @"
using System;
using System.Text;
using System.Runtime.InteropServices;

public class InnerEnum {
  public delegate bool P(IntPtr h, IntPtr l);
  [DllImport("user32.dll")] public static extern bool EnumWindows(P cb, IntPtr l);
  [DllImport("user32.dll")] public static extern bool IsWindowVisible(IntPtr h);
  [DllImport("user32.dll", CharSet = CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
}
"@

$script:count = 0
$script:found = $false
$cb = [InnerEnum+P]{
  param($h, $l)
  if ([InnerEnum]::IsWindowVisible($h)) { $script:count++ }
  if ($TargetHwnd -ne 0 -and $h.ToInt64() -eq $TargetHwnd) { $script:found = $true }
  return $true
}
[void][InnerEnum]::EnumWindows($cb, [IntPtr]::Zero)

$session = [System.Diagnostics.Process]::GetCurrentProcess().SessionId
"INNER visible=$($script:count) targetVisible=$($script:found) session=$session pid=$PID"
