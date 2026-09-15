// helper-client.mjs — drive the shipping window helper over its JSON-lines
// protocol exactly the way Papers does.
//
// WHY NODE: the helper's main loop is `while (($l = [Console]::In.ReadLine())
// -ne $null)`, so it exits on stdin EOF, and PowerShell's Process/StandardInput
// plumbing proved unreliable for holding that pipe (measured: ReadLineAsync in a
// retry loop leaves the stream in use; an unbounded ReadLine blocks forever).
// Papers itself spawns the helper with node child_process.spawn and stdio pipes,
// so driving it the same way removes an entire class of instrument artefact.
//
// Usage:
//   node helper-client.mjs <helper.ps1> <powershell.exe> list
//   node helper-client.mjs <helper.ps1> <powershell.exe> observe <token>
//   node helper-client.mjs <helper.ps1> <powershell.exe> list,observe:<token>,list
//
// Prints one JSON line per response to stdout, prefixed with "RESP ".

import { spawn } from 'node:child_process';

const [helperPath, psPath, plan] = process.argv.slice(2);
if (!helperPath || !psPath || !plan) {
  console.error('usage: helper-client.mjs <helper.ps1> <powershell.exe> <plan>');
  process.exit(2);
}

const child = spawn(psPath, ['-NoProfile', '-NonInteractive', '-File', helperPath], {
  stdio: ['pipe', 'pipe', 'pipe'],
  windowsHide: true,
  shell: false,
});

let buffer = '';
const pending = [];
const ready = [];

child.stdout.setEncoding('utf8');
child.stdout.on('data', (chunk) => {
  buffer += chunk;
  let idx;
  while ((idx = buffer.indexOf('\n')) >= 0) {
    const line = buffer.slice(0, idx).trim();
    buffer = buffer.slice(idx + 1);
    if (!line) continue;
    const waiter = pending.shift();
    if (waiter) waiter(line);
  }
});

child.stderr.setEncoding('utf8');
let stderrText = '';
child.stderr.on('data', (c) => { stderrText += c; });

child.on('exit', (code) => {
  console.log(`EXIT ${code}`);
  if (stderrText.trim()) console.log(`STDERR ${stderrText.trim().slice(0, 400)}`);
});

let nextId = 1;
function request(method, target) {
  return new Promise((resolve) => {
    const id = nextId++;
    const msg = { requestId: id, method };
    if (target !== undefined) msg.target = target;
    const timer = setTimeout(() => resolve({ __timeout: true, requestId: id, method }), 90000);
    pending.push((line) => {
      clearTimeout(timer);
      try {
        resolve(JSON.parse(line));
      } catch {
        resolve({ __unparsed: line.slice(0, 200) });
      }
    });
    child.stdin.write(`${JSON.stringify(msg)}\n`);
  });
}

// Give the helper a moment to import its adapter before the first request, which
// is what Papers' start handshake effectively provides.
await new Promise((r) => setTimeout(r, 1200));

const steps = plan.split(',').filter(Boolean);
for (const step of steps) {
  const [method, target] = step.split(':');
  const resp = await request(method, target);
  console.log(`RESP ${JSON.stringify(resp)}`);
}

child.stdin.end();
await new Promise((r) => setTimeout(r, 400));
try { child.kill(); } catch { /* already gone */ }
