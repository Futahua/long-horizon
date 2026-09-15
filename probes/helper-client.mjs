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
//   node helper-client.mjs <helper.ps1> <powershell.exe> observe:<token>
//   node helper-client.mjs <helper.ps1> <powershell.exe> list,observe:<token>|use:1,list
//
// Plan steps, run IN ORDER inside ONE helper process (which is what keeps a
// session token valid across steps):
//   list                     -> a list request
//   observe:<token>          -> an observe request for that token
//   observe:last             -> observe using the first token from the last list
//   sleep:<ms>               -> wait between steps
//   action:<text>            -> print a marker (the parent mutates the window here)
//
// Prints one JSON line per response to stdout, prefixed with "RESP ".

import { spawn } from 'node:child_process';

const [helperPath, psPath, plan, mutatorPath, mutatorHwnd] = process.argv.slice(2);
if (!helperPath || !psPath || !plan) {
  console.error('usage: helper-client.mjs <helper.ps1> <powershell.exe> <plan> [mutator.ps1] [hwnd]');
  process.exit(2);
}

// Responses are ALSO written to a JSON file. Piping them through a shell proved
// unreliable: PowerShell's 2>&1 interleaving injected a non-string record that
// silently shifted every later assertion by one. A file has no such failure mode.
const RESPONSE_FILE = process.env.PROBE_RESPONSE_FILE;

function emit(entry) {
  console.log(`RESP ${JSON.stringify(entry)}`);
}

/**
 * Run the mutator script between two requests, so the helper process stays ALIVE
 * across the change. Without this the token would die with the helper and the
 * probe would be measuring a helper restart instead of a title change — which is
 * exactly the instrument defect the first version of this probe had.
 */
function runMutator() {
  return new Promise((resolve) => {
    if (!mutatorPath) {
      console.log('ACTION no-mutator');
      return resolve();
    }
    const m = spawn(psPath, ['-NoProfile', '-File', mutatorPath, String(mutatorHwnd ?? '')], {
      stdio: ['ignore', 'pipe', 'pipe'],
      windowsHide: true,
    });
    let out = '';
    m.stdout.on('data', (c) => { out += c; });
    m.stderr.on('data', (c) => { out += c; });
    m.on('exit', (code) => {
      console.log(`ACTION mutator-exit=${code} ${out.trim().slice(0, 200)}`);
      resolve();
    });
  });
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
const collected = [];
let lastTokens = [];
for (const step of steps) {
  if (step.startsWith('action:')) {
    console.log(`ACTION ${step.slice(7)}`);
    continue;
  }
  if (step.startsWith('mutate')) {
    await runMutator();
    continue;
  }
  if (step.startsWith('sleep:')) {
    await new Promise((r) => setTimeout(r, Number(step.slice(6)) || 0));
    continue;
  }
  const [method, arg] = step.split(':');
  let target;
  if (method === 'observe' || method === 'thumbnail' || method === 'close') {
    target = arg === 'last' ? lastTokens[0] : arg;
    if (!target) {
      const err = { __error: 'no token available for step', step };
      collected.push(err);
      emit(err);
      continue;
    }
  }
  const resp = await request(method, target);
  if (resp && Array.isArray(resp.windows)) {
    lastTokens = resp.windows.map((w) => w.runtimeId);
  }
  collected.push(resp);
  emit(resp);
}

if (RESPONSE_FILE) {
  const { writeFileSync } = await import('node:fs');
  writeFileSync(RESPONSE_FILE, JSON.stringify(collected, null, 2), 'utf8');
}

child.stdin.end();
await new Promise((r) => setTimeout(r, 400));
try { child.kill(); } catch { /* already gone */ }
