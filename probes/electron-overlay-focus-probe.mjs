// scratch: measure whether a transparent always-on-top overlay can TAKE focus
// and GIVE IT BACK. This runs WITHOUT any SetForegroundWindow call, so it
// measures what Windows does on its own.
//
// Protocol: the probe shows a full-screen "foreground app" window first. The
// caller brings a third-party application to the front (Notepad is launched by
// the caller). Then the probe shows its overlay, focuses it, and closes it -
// reporting the foreground window title at each step through a native observer.
import { app, BrowserWindow, globalShortcut } from 'electron';
import * as fs from 'node:fs';
import { execFileSync } from 'node:child_process';

const OUT = process.argv[process.argv.length - 1];
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

app.whenReady().then(async () => {
  // A "foreground reporter" written as a tiny PowerShell one-liner using
  // Add-Type for GetForegroundWindow + GetWindowText. One process, one report
  // per call, so the reading is taken at a known instant.
  const reporter = `
Add-Type -TypeDefinition @'
using System; using System.Text; using System.Runtime.InteropServices;
public class Fg {
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetWindowTextW(IntPtr h, StringBuilder s, int n);
  [DllImport("user32.dll", CharSet=CharSet.Unicode)] public static extern int GetClassNameW(IntPtr h, StringBuilder s, int n);
}
'@
$h = [Fg]::GetForegroundWindow()
$t = New-Object System.Text.StringBuilder 512; [void][Fg]::GetWindowTextW($h, $t, $t.Capacity)
$c = New-Object System.Text.StringBuilder 256; [void][Fg]::GetClassNameW($h, $c, $c.Capacity)
"fg=$($t.ToString()) class=$($c.ToString()) hwnd=$('0x{0:X}' -f $h.ToInt64())"
`;
  const report = () => {
    try {
      return execFileSync('powershell.exe', ['-NoProfile', '-NonInteractive', '-Command', reporter], {
        encoding: 'utf8', timeout: 15000,
      }).trim();
    } catch (error) {
      return `reporter failed: ${String(error.message).slice(0, 80)}`;
    }
  };

  say('=== overlay focus measurement (no SetForegroundWindow anywhere) ===');
  say(`baseline      : ${report()}`);

  // The third-party application the creator would be "in".
  const { spawn } = await import('node:child_process');
  const notepad = spawn('notepad.exe', [], { detached: true, stdio: 'ignore' });
  notepad.unref();
  await sleep(3500);
  say(`notepad shown : ${report()}`);

  // The overlay: borderless, transparent, always-on-top, skipped from taskbar.
  const overlay = new BrowserWindow({
    x: 200, y: 200, width: 520, height: 240,
    frame: false,
    transparent: true,
    backgroundColor: '#00000000',
    alwaysOnTop: true,
    skipTaskbar: true,
    resizable: false,
    show: false,
    webPreferences: { contextIsolation: true, sandbox: true },
  });
  overlay.setAlwaysOnTop(true, 'floating');
  await overlay.loadURL('data:text/html,<body style="background:%23ffffffcc"><h1 id=t>overlay</h1></body>');
  await sleep(400);
  say(`overlay hidden: ${report()}`);

  overlay.show();
  overlay.focus();
  await sleep(1200);
  say(`overlay shown+focus: ${report()}`);
  say(`  overlay.isFocused=${overlay.isFocused()} isVisible=${overlay.isVisible()}`);

  // Close it the way the launcher does, and see where focus lands WITHOUT help.
  overlay.hide();
  await sleep(1200);
  say(`after hide()  : ${report()}`);

  overlay.show();
  overlay.focus();
  await sleep(900);
  overlay.close();
  await sleep(1200);
  say(`after close() : ${report()}`);

  // Now the same sequence but using showInactive, for comparison.
  const overlay2 = new BrowserWindow({
    x: 300, y: 300, width: 420, height: 200,
    frame: false, transparent: true, alwaysOnTop: true, skipTaskbar: true,
    show: false, webPreferences: { contextIsolation: true, sandbox: true },
  });
  overlay2.setAlwaysOnTop(true, 'floating');
  await overlay2.loadURL('data:text/html,<body style="background:%23ffffffcc">overlay2</body>');
  overlay2.showInactive();
  await sleep(1000);
  say(`showInactive(): ${report()}`);
  say(`  overlay2.isFocused=${overlay2.isFocused()}`);
  overlay2.destroy();
  await sleep(1000);
  say(`after destroy : ${report()}`);

  say('=== does Electron expose a foreground accessor? ===');
  say(`app.getForegroundWindow type: ${typeof app.getForegroundWindow}`);
  say(`BrowserWindow.getFocusedWindow: ${typeof BrowserWindow.getFocusedWindow}`);

  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  // Clean up only the notepad this probe started.
  try {
    execFileSync('powershell.exe', ['-NoProfile', '-Command',
      `Get-Process -Name notepad -ErrorAction SilentlyContinue | Where-Object { $_.StartTime -gt (Get-Date).AddMinutes(-3) } | Stop-Process -Force`],
      { timeout: 20000 });
  } catch { /* best effort */ }
  app.quit();
});
