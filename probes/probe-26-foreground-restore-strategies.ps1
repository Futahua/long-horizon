# probe-26-foreground-restore-strategies.ps1
#
# EXPERIMENT 26 — which Windows call sequence actually moves the foreground to a
# chosen window, measured rather than recalled?
#
# Probe-25 established that Papers' shipping helper reports `restore` success
# while the foreground does not move: SetForegroundWindow from a background
# process is refused by the foreground lock. This probe tries the documented
# workarounds and reports, per strategy, whether the foreground actually moved.
#
# Strategies:
#   S1 SetForegroundWindow alone
#   S2 BringWindowToTop + SetForegroundWindow
#   S3 AttachThreadInput(current) -> SetForegroundWindow -> detach
#   S4 AttachThreadInput(current AND target) -> SetForegroundWindow -> detach
#   S5 S3 plus a synthesized ALT tap (the documented foreground-lock unlock)
#
# The caller supplies the target; the observer reads the foreground afterwards.

param(
  [Parameter(Mandatory = $true)][long]$TargetHwnd
)

Add-Type -TypeDefinition @'
using System;
using System.Text;
using System.Runtime.InteropServices;

public class FgRestore {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool BringWindowToTop(IntPtr h);
  [DllImport("user32.dll")] public static extern bool ShowWindow(IntPtr h, int cmd);
  [DllImport("user32.dll")] public static extern bool IsIconic(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetWindowThreadProcessId(IntPtr h, IntPtr p);
  [DllImport("kernel32.dll")] public static extern uint GetCurrentThreadId();
  [DllImport("user32.dll")] public static extern bool AttachThreadInput(uint attach, uint attachTo, bool fAttach);
  [DllImport("user32.dll")] public static extern void keybd_event(byte vk, byte scan, uint flags, IntPtr extra);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);

  public const int SW_RESTORE = 9;
  public const byte VK_MENU = 0x12;
  public const uint KEYEVENTF_KEYUP = 0x0002;

  public static string Title(IntPtr h) {
    var sb = new StringBuilder(512);
    GetWindowTextW(h, sb, sb.Capacity);
    return sb.ToString();
  }

  public static uint OurThread() { return GetCurrentThreadId(); }

  public static uint ForegroundThread() {
    IntPtr fg = GetForegroundWindow();
    return (uint)GetWindowThreadProcessId(fg, IntPtr.Zero);
  }

  public static IntPtr Foreground() { return GetForegroundWindow(); }

  /** S5's ALT tap: press and release ALT to satisfy the foreground lock. */
  public static void AltTap() {
    keybd_event(VK_MENU, 0, 0, IntPtr.Zero);
    keybd_event(VK_MENU, 0, KEYEVENTF_KEYUP, IntPtr.Zero);
  }
}
'@

$target = [IntPtr]$TargetHwnd
"target hwnd : 0x$($TargetHwnd.ToString('X')) title='$([FgRestore]::Title($target))'"
"current fg  : 0x$([FgRestore]::Foreground().ToInt64().ToString('X')) title='$([FgRestore]::Title([FgRestore]::Foreground()))'"
""

function Test-Strategy {
  param([string]$Name, [scriptblock]$Body)
  $before = [FgRestore]::Foreground()
  & $Body
  Start-Sleep -Milliseconds 600
  $after = [FgRestore]::Foreground()
  $moved = $after -eq $target
  "  [$Name] before=0x$($before.ToInt64().ToString('X')) after=0x$($after.ToInt64().ToString('X')) movedToTarget=$moved"
  return $moved
}

"=== strategy results ==="

$s1 = Test-Strategy -Name 'S1 SetForegroundWindow' -Body {
  [void][FgRestore]::SetForegroundWindow($target)
}

$s2 = Test-Strategy -Name 'S2 BringWindowToTop+SetForegroundWindow' -Body {
  [void][FgRestore]::BringWindowToTop($target)
  [void][FgRestore]::SetForegroundWindow($target)
}

$s3 = Test-Strategy -Name 'S3 AttachThreadInput(ours)' -Body {
  $fgThread = [FgRestore]::ForegroundThread()
  $ourThread = [FgRestore]::OurThread()
  if ([FgRestore]::IsIconic($target)) { [void][FgRestore]::ShowWindow($target, [FgRestore]::SW_RESTORE) }
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $true)
  [void][FgRestore]::BringWindowToTop($target)
  [void][FgRestore]::SetForegroundWindow($target)
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $false)
}

$s4 = Test-Strategy -Name 'S4 AttachThreadInput(ours+target)' -Body {
  $fgThread = [FgRestore]::ForegroundThread()
  $ourThread = [FgRestore]::OurThread()
  $targetThread = [FgRestore]::GetWindowThreadProcessId($target, [IntPtr]::Zero)
  if ([FgRestore]::IsIconic($target)) { [void][FgRestore]::ShowWindow($target, [FgRestore]::SW_RESTORE) }
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $true)
  [void][FgRestore]::AttachThreadInput($ourThread, [uint32]$targetThread, $true)
  [void][FgRestore]::BringWindowToTop($target)
  [void][FgRestore]::SetForegroundWindow($target)
  [void][FgRestore]::AttachThreadInput($ourThread, [uint32]$targetThread, $false)
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $false)
}

$s5 = Test-Strategy -Name 'S5 ALT tap + S3' -Body {
  $fgThread = [FgRestore]::ForegroundThread()
  $ourThread = [FgRestore]::OurThread()
  if ([FgRestore]::IsIconic($target)) { [void][FgRestore]::ShowWindow($target, [FgRestore]::SW_RESTORE) }
  [FgRestore]::AltTap()
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $true)
  [void][FgRestore]::BringWindowToTop($target)
  [void][FgRestore]::SetForegroundWindow($target)
  [void][FgRestore]::AttachThreadInput($ourThread, $fgThread, $false)
}

""
"=== summary ==="
"  S1 SetForegroundWindow alone            : $s1"
"  S2 BringWindowToTop + SetForegroundWindow: $s2"
"  S3 AttachThreadInput(ours)              : $s3"
"  S4 AttachThreadInput(ours+target)       : $s4"
"  S5 ALT tap + S3                         : $s5"
""
"  Note: this runs from a background process, which is the HARD case. A process"
"  that currently owns the foreground is granted the right without any of this."
