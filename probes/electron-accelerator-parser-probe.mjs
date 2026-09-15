// scratch: how permissive is Electron's accelerator parser? A configured chord
// with a typo that registers true but never fires would be a silent failure -
// the exact bug class this task must not add. Not committed.
import { app, globalShortcut } from 'electron';
import * as fs from 'node:fs';

const OUT = process.argv[process.argv.length - 1];
const log = [];
const say = (l) => { log.push(l); console.log(l); };

app.whenReady().then(() => {
  const cases = [
    // plausible typo / nonsense names
    'NotAKey+Q', 'Alt+NotAKey', 'Alt+Qqq', 'Alt+Ctrl+A', 'Super+A', 'Meta+A',
    'Alt+a', 'alt+a', 'ALT+A',
    // plausible real chords
    'Alt+A', 'Alt+Shift+A', 'CommandOrControl+Shift+A', 'Ctrl+Alt+A',
    // near-misses for the two chords actually requested
    'Alt+Shift+A ', ' Alt+Shift+A', 'Alt +Shift+A', 'Alt+Shift', 'A',
  ];
  for (const spec of cases) {
    let result;
    try {
      result = String(globalShortcut.register(spec, () => {}));
    } catch (error) {
      result = `THREW ${error?.constructor?.name}`;
    }
    say(`${JSON.stringify(spec).padEnd(30)} -> ${result}`);
    try { globalShortcut.unregister(spec); } catch { /* ignore */ }
  }
  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  app.quit();
});
