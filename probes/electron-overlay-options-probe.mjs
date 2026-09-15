// scratch: measure the REAL overlay window options, since "must not appear in
// the taskbar or alt-tab" and "always on top" are the requirements most likely
// to rot silently. Builds the same window the wiring builds and reads it back.
import { app, BrowserWindow, screen } from 'electron';
import * as fs from 'node:fs';

const OUT = process.argv[process.argv.length - 1];
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

app.whenReady().then(async () => {
  const area = screen.getDisplayNearestPoint(screen.getCursorScreenPoint()).workArea;
  say(`cursor display work area: x=${area.x} y=${area.y} w=${area.width} h=${area.height}`);

  const width = Math.min(640, area.width);
  const height = Math.min(220, area.height);
  const overlay = new BrowserWindow({
    x: area.x + Math.round((area.width - width) / 2),
    y: area.y + Math.round(area.height * 0.22),
    width,
    height,
    frame: false,
    title: '',
    transparent: true,
    backgroundColor: '#00000000',
    resizable: false,
    alwaysOnTop: true,
    skipTaskbar: true,
    minimizable: false,
    maximizable: false,
    show: false,
    webPreferences: { contextIsolation: true, nodeIntegration: false, sandbox: true },
  });
  overlay.setMenuBarVisibility(false);
  overlay.setAlwaysOnTop(true, 'floating');
  overlay.setSkipTaskbar(true);
  await overlay.loadURL('data:text/html,<body style="background:%23ffd">overlay</body>');

  const read = (label, fn) => {
    try { say(`${label.padEnd(34)} ${fn()}`); } catch (e) { say(`${label.padEnd(34)} THREW ${e.message}`); }
  };

  say('=== measured overlay window state ===');
  read('isResizable', () => overlay.isResizable());
  read('isAlwaysOnTop', () => overlay.isAlwaysOnTop());
  read('isMovable', () => overlay.isMovable());
  read('isMinimizable', () => overlay.isMinimizable());
  read('isMaximizable', () => overlay.isMaximizable());
  read('isFullScreenable', () => overlay.isFullScreenable());
  read('isVisible before show', () => overlay.isVisible());
  read('getBounds', () => JSON.stringify(overlay.getBounds()));
  read('title', () => JSON.stringify(overlay.getTitle()));

  // skipTaskbar has no getter, so it is measured through the native window's
  // extended styles via the bridge the host actually uses.
  const bridge = process.env['FG_BRIDGE'];
  const hwnd = overlay.getNativeWindowHandle();
  const handle = hwnd.readBigInt64LE ? hwnd.readBigInt64LE(0).toString() : String(hwnd.readInt32LE(0));
  say(`native handle (as read by Node): ${handle}`);
  if (bridge && fs.existsSync(bridge)) {
    const { execFileSync } = await import('node:child_process');
    try {
      const out = execFileSync(bridge, ['get'], { encoding: 'utf8' }).trim();
      say(`bridge get while overlay hidden: ${out}`);
    } catch (e) { say(`bridge get failed: ${e.message}`); }
  }

  overlay.show();
  overlay.focus();
  await sleep(900);
  read('isVisible after show', () => overlay.isVisible());
  read('isFocused after focus', () => overlay.isFocused());

  overlay.hide();
  await sleep(400);
  read('isVisible after hide', () => overlay.isVisible());

  overlay.destroy();
  say('destroyed');
  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  app.quit();
});
