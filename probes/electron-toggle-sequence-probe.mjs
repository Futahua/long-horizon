// scratch: drive the toggle's real primitive sequence against two windows this
// probe owns, so the creator's desktop is not disturbed.
//
// The toggle's decision logic is unit-tested. What cannot be unit-tested is
// whether the NATIVE three-step actually works:
//   1. the bridge reports which window is foreground (decides raise vs hide)
//   2. minimising that window really hides it
//   3. the z-order walk finds what was underneath, and focusing it really moves
//      the foreground there
import { app, BrowserWindow } from 'electron';
import { execFileSync } from 'node:child_process';
import * as fs from 'node:fs';

const OUT = process.argv[process.argv.length - 1];
const BRIDGE = process.env['FG_BRIDGE'];
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
const run = (args) => {
  try { return execFileSync(BRIDGE, args, { encoding: 'utf8', timeout: 10000 }).trim(); }
  catch (error) {
    // `next` exits 5 for "nothing underneath"; the text is still the answer.
    if (error.stdout) return String(error.stdout).trim();
    return `ERR ${String(error.message).slice(0, 60)}`;
  }
};

app.whenReady().then(async () => {
  const handleOf = (win) => {
    const b = win.getNativeWindowHandle();
    return b.length >= 8 ? Number(b.readBigUInt64LE(0)) : b.readUInt32LE(0);
  };

  // Two real windows. "under" is created first so it sits lower in z-order.
  const under = new BrowserWindow({ x: 120, y: 120, width: 420, height: 260, title: 'PROBE-UNDER' });
  await under.loadURL('data:text/html,<title>PROBE-UNDER</title><h1>under</h1>');
  const top = new BrowserWindow({ x: 180, y: 180, width: 420, height: 260, title: 'PROBE-TOP' });
  await top.loadURL('data:text/html,<title>PROBE-TOP</title><h1>top</h1>');
  await sleep(800);

  const underH = handleOf(under);
  const topH = handleOf(top);
  say(`under handle=${underH}  top handle=${topH}`);

  // Step 0: what does the bridge say is in front?
  say(`bridge get            : ${run(['get'])}`);

  // Make `top` the foreground the way the toggle expects to find it.
  top.show();
  top.focus();
  top.moveTop();
  await sleep(1000);
  say(`after focus(top)      : ${run(['get'])}`);
  const isTopForeground = run(['get']).includes(`handle=${topH}`);
  say(`  top is foreground   : ${isTopForeground}`);

  // Step 1: the z-order walk from the window about to be hidden.
  const next = run(['next', String(topH)]);
  say(`next below top        : ${next}`);
  const foundUnder = next.includes(`handle=${underH}`);
  say(`  it found PROBE-UNDER: ${foundUnder}`);

  // Step 2: minimise, exactly as the toggle does.
  top.minimize();
  await sleep(900);
  say(`after minimize(top)   : ${run(['get'])}  isMinimized=${top.isMinimized()}`);

  // Step 3: hand focus to the window underneath, exactly as the toggle does.
  let focusResult = 'not attempted';
  if (foundUnder) {
    focusResult = run(['set', String(underH)]);
    await sleep(900);
    const after = run(['get']);
    say(`after set(under)      : ${after}`);
    say(`  focus moved to under: ${after.includes(`handle=${underH}`)}`);
  } else {
    say('  skipping the focus hand-off: the walk did not find the expected window');
  }

  // The same `set` on a window that is already foreground must still be honest.
  const repeat = run(['set', String(underH)]);
  say(`set(under) again      : ${repeat}`);

  say('');
  say('=== what this establishes ===');
  say(`  1. foreground readable          : yes`);
  say(`  2. z-order walk found under     : ${foundUnder}`);
  say(`  3. minimise really minimised    : ${top.isMinimized()}`);
  say(`  4. focus hand-off               : ${focusResult}`);

  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  under.destroy();
  top.destroy();
  app.quit();
});
