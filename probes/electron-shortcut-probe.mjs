// scratch: measure Electron globalShortcut behaviour for real.
// Not committed. Answers: does register() detect a taken chord, what does
// isRegistered say, and is the failure observable rather than silent?
import { app, globalShortcut } from 'electron';
import * as fs from 'node:fs';

const OUT = process.argv[process.argv.length - 1];
const log = [];
const say = (line) => { log.push(line); console.log(line); };

// Contention mode: a Papers instance is already running and holds the two
// chords. This measures, in a genuinely separate OS process, whether this
// process can take them - which is what a second instance experiences.
if (process.env['PROBE_MODE'] === 'contention') {
  app.whenReady().then(() => {
    for (const chord of ['Alt+Shift+A', 'Alt+A']) {
      const before = globalShortcut.isRegistered(chord);
      let registered;
      try {
        registered = globalShortcut.register(chord, () => {});
      } catch (error) {
        registered = `THREW ${error?.constructor?.name}`;
      }
      say(`CONTENTION ${chord}: isRegistered-before=${before} register()=${registered}`);
    }
    fs.writeFileSync(OUT, log.join('\n'), 'utf8');
    app.quit();
  });
} else {
  app.whenReady().then(() => {
    say(`electron=${process.versions.electron} platform=${process.platform}`);

  // 1. A chord nobody sane owns: expected to register.
  const free = 'Alt+Shift+F9';
  let r = globalShortcut.register(free, () => {});
  say(`register(${free}) -> ${r}  isRegistered=${globalShortcut.isRegistered(free)}`);

  // 2. Same chord a SECOND time from the same process: Electron cannot express
  //    "another app owns it" here, but this tests double registration.
  let r2 = globalShortcut.register(free, () => {});
  say(`register(${free}) AGAIN -> ${r2}  isRegistered=${globalShortcut.isRegistered(free)}`);

  // 3. Inspect what electron thinks of a plausible taken chord.
  const taken = 'Alt+A';
  const regAltA = globalShortcut.register(taken, () => {});
  say(`register(${taken}) -> ${regAltA}  isRegistered=${globalShortcut.isRegistered(taken)}`);

  // 4. isRegistered for a chord never registered here.
  say(`isRegistered(Ctrl+Alt+Shift+F12) with no registration -> ${globalShortcut.isRegistered('Ctrl+Alt+Shift+F12')}`);

  // 5. Invalid accelerator strings: does register throw or return false?
  for (const bad of ['NotAKey+Q', 'Alt+', '+++', 'Alt+NotARealKeyName']) {
    try {
      const res = globalShortcut.register(bad, () => {});
      say(`register(${JSON.stringify(bad)}) -> ${res} (no throw)`);
    } catch (error) {
      say(`register(${JSON.stringify(bad)}) -> THREW ${error?.constructor?.name}: ${String(error?.message).slice(0, 120)}`);
    }
  }

  // 6. Unregister semantics.
  globalShortcut.unregister(free);
  say(`after unregister(${free}): isRegistered=${globalShortcut.isRegistered(free)}`);
  globalShortcut.unregisterAll();
  say(`after unregisterAll: isRegistered(${taken})=${globalShortcut.isRegistered(taken)}`);

    fs.writeFileSync(OUT, log.join('\n'), 'utf8');
    app.quit();
  });
}
