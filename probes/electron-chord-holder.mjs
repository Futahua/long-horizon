// scratch: hold Alt+A so an isolated Papers instance must report that chord as
// taken. Writes a marker file so the caller knows the claim is in place.
import { app, globalShortcut } from 'electron';
import * as fs from 'node:fs';

const marker = process.argv[process.argv.length - 1];
const holdMs = Number(process.env['HOLD_MS'] ?? '40000');

app.whenReady().then(() => {
  const results = [];
  for (const chord of ['Alt+A']) {
    results.push(`${chord}=${globalShortcut.register(chord, () => {})}`);
  }
  fs.writeFileSync(marker, `holding pid=${process.pid} ${results.join(' ')}`, 'utf8');
  setTimeout(() => app.quit(), holdMs);
});
