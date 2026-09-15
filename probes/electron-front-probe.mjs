// scratch: measure what a real Electron BaseWindow actually does for each
// "bring to front" situation. windowsHide/show/focus/isMinimized/isFocused plus
// moveTop. Not committed.
import { app, BaseWindow, WebContentsView } from 'electron';
import * as fs from 'node:fs';

const OUT = process.argv[process.argv.length - 1];
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

app.whenReady().then(async () => {
  const win = new BaseWindow({ width: 520, height: 320, title: 'papers-front-probe' });
  const view = new WebContentsView({ webPreferences: { sandbox: true } });
  win.contentView.addChildView(view);
  view.setBounds({ x: 0, y: 0, width: 520, height: 320 });
  await view.webContents.loadURL('data:text/html,<title>probe</title><h1>probe</h1>');
  await sleep(700);

  const snap = (label) => {
    const has = {
      isDestroyed: win.isDestroyed(),
      isMinimized: win.isMinimized(),
      isVisible: win.isVisible(),
      isFocused: win.isFocused(),
      isAlwaysOnTop: win.isAlwaysOnTop(),
    };
    say(`${label.padEnd(34)} ${JSON.stringify(has)}`);
  };

  say('--- sequence A: normal window, plain focus ---');
  win.focus();
  await sleep(400);
  snap('after focus()');

  say('--- sequence B: minimized window ---');
  win.minimize();
  await sleep(600);
  snap('after minimize()');
  win.show();
  win.focus();
  await sleep(600);
  snap('after show()+focus()');
  say(`   moveTop available: ${typeof win.moveTop === 'function'}`);
  win.moveTop();
  await sleep(300);
  snap('after moveTop()');

  say('--- sequence C: hidden window ---');
  win.hide();
  await sleep(400);
  snap('after hide()');
  win.show();
  win.focus();
  await sleep(500);
  snap('after show()+focus()');

  say('--- sequence D: full-screen window, then bring back ---');
  win.setFullScreen(true);
  await sleep(700);
  snap('fullscreen');
  win.setFullScreen(false);
  await sleep(700);
  win.show();
  win.focus();
  snap('after unscreen+show+focus');

  say('--- sequence E: what is exposed for virtual desktops / other apps ---');
  say(`   setVisibleOnAllWorkspaces: ${typeof win.setVisibleOnAllWorkspaces}`);
  say(`   BaseWindow methods: ${Object.getOwnPropertyNames(Object.getPrototypeOf(win)).filter((n) => /work|desk|top|focus|show|restore|move/i.test(n)).join(', ')}`);

  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  win.destroy();
  app.quit();
});
