// scratch: the end-to-end proof. Against a REAL Papers and the creator's REAL
// running service, established by running:
//
//   1. the CSP change lets a project page OPEN a loopback connection (before it
//      could not: zero requests reached the listener)
//   2. the main-process bridge reaches the live service and returns the real
//      payload, carrying the credential the project declares
//   3. a declared service that is NOT running, an undeclared origin, a remote
//      origin, a disallowed method and an unreadable credential are each
//      reported honestly
import { app, BrowserWindow, net } from 'electron';
import { createServer } from 'node:http';
import * as fs from 'node:fs';
import * as path from 'node:path';
import { createLocalServiceBridge } from './src/main/backpacks/localServiceBridge.ts';

const OUT = process.env['PROBE_OUT'];
const PROJECT_PATH = process.env['PROBE_PROJECT'];
const APP_ROOT = process.env['PROBE_APP_ROOT'];
const SERVICE = 'http://127.0.0.1:4181';
const DEAD = 'http://127.0.0.1:4199';
const TOKEN_FILE = process.env['PROBE_TOKEN_FILE'];
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const readToken = (file) => {
  try { return fs.readFileSync(file, 'utf8').trim(); } catch { return null; }
};

const perform = async ({ url, method, headers, body }) => {
  const response = await net.fetch(url, { method, headers, ...(body === null ? {} : { body }) });
  return {
    status: response.status,
    headers: Object.fromEntries(response.headers.entries()),
    body: await response.text(),
  };
};

const received = [];
const listener = createServer((req, res) => {
  received.push(req.url);
  res.writeHead(200, { 'Content-Type': 'text/plain' });
  res.end('listener-ok');
});

async function main() {
  // The real Papers main must load FIRST: `net.fetch` needs a ready app, and the
  // first run of this probe proved that by failing with
  // "Session can only be received when app is ready".
  const mainPath = path.join(APP_ROOT, 'out', 'main', 'index.js');
  await import('file://' + mainPath.replace(/\\/g, '/'));
  await app.whenReady();
  await sleep(3000);
  say('real Papers main loaded and ready');

  await new Promise((r) => listener.listen(0, '127.0.0.1', r));
  const listenerPort = listener.address().port;
  say('listener on http://127.0.0.1:' + listenerPort);

  const declaration = {
    schemaVersion: 1,
    services: [
      { origin: SERVICE, secret: 'operator' },
      { origin: DEAD, secret: 'operator' },
    ],
    secrets: [{ id: 'operator', file: TOKEN_FILE, header: 'authorization', scheme: 'Bearer' }],
  };

  say('');
  say('=== 1. the bridge against the LIVE service ===');
  const bridge = createLocalServiceBridge({
    declaration,
    readSecretFile: readToken,
    performRequest: perform,
    report: (r) => say('  [bridge] ' + r.outcome + ': ' + r.detail),
  });

  const snapshot = await bridge.fetch({ url: SERVICE + '/v1/snapshot' });
  say('snapshot ok=' + snapshot.ok + ' status=' + snapshot.status);
  let headSeq = null;
  if (snapshot.ok) {
    const parsed = JSON.parse(snapshot.body ?? '{}');
    headSeq = parsed.headSeq;
    say('  headSeq=' + parsed.headSeq + ' schemaVersion=' + parsed.schemaVersion + ' boardPresent=' + (parsed.board !== undefined));
  } else {
    say('  detail=' + snapshot.detail);
  }

  const health = await bridge.fetch({ url: SERVICE + '/v1/health' });
  say('health ok=' + health.ok + ' status=' + health.status);
  say('  body=' + (health.body ?? '').slice(0, 140));

  say('');
  say('=== 2. honest refusals ===');
  const dead = await bridge.fetch({ url: DEAD + '/v1/snapshot' });
  say('declared but NOT running : ok=' + dead.ok + ' detail=' + dead.detail);
  const undeclared = await bridge.fetch({ url: 'http://127.0.0.1:4321/v1/snapshot' });
  say('not declared by project  : ok=' + undeclared.ok + ' detail=' + undeclared.detail);
  const remote = await bridge.fetch({ url: 'http://example.com/v1/snapshot' });
  say('remote origin            : ok=' + remote.ok + ' detail=' + remote.detail);
  const trace = await bridge.fetch({ url: SERVICE + '/v1/snapshot', method: 'TRACE' });
  say('disallowed method        : ok=' + trace.ok + ' detail=' + trace.detail);
  const forged = await bridge.fetch({
    url: SERVICE + '/v1/snapshot',
    headers: { authorization: 'Bearer PAGE-SUPPLIED', cookie: 'session=stolen' },
  });
  say('page-supplied credential : ok=' + forged.ok + ' status=' + forged.status);

  let bareSent = false;
  const noSecret = createLocalServiceBridge({
    declaration,
    readSecretFile: () => null,
    performRequest: async () => { bareSent = true; throw new Error('MUST NOT BE CALLED'); },
    report: () => {},
  });
  const unreadable = await noSecret.fetch({ url: SERVICE + '/v1/snapshot' });
  say('unreadable credential    : ok=' + unreadable.ok + ' detail=' + unreadable.detail + ' bareRequestSent=' + bareSent);

  say('');
  say('=== 3. the CSP relaxation, from a real project page ===');
  const dataDir = process.env['PAPERS_TEST_USER_DATA'];
  const bindings = JSON.parse(fs.readFileSync(path.join(dataDir, 'PapersData', 'backpack-projects.json'), 'utf8'));
  const projectId = Object.keys(bindings.projects ?? {})[0];
  say('project: ' + projectId);

  const publicDir = path.join(PROJECT_PATH, 'public');
  fs.mkdirSync(publicDir, { recursive: true });
  const script = [
    'const out = [];',
    'async function probe() {',
    '  try {',
    "    const r = await fetch('http://127.0.0.1:" + listenerPort + "/direct');",
    "    out.push('csp-loopback-fetch: OK ' + r.status);",
    "  } catch (e) { out.push('csp-loopback-fetch: THREW ' + e.name); }",
    '  try {',
    "    await fetch('http://127.0.0.1:" + listenerPort + "/preflight', {",
    "      method: 'POST', headers: { 'Content-Type': 'application/json' }, body: '{}',",
    '    });',
    "    out.push('csp-preflight-sent: yes');",
    "  } catch (e) { out.push('csp-preflight: THREW ' + e.name); }",
    "  window.__probeResult = out.join(' | ');",
    '}',
    'probe();',
  ].join('\n');
  fs.writeFileSync(path.join(publicDir, 'probe.js'), script);
  fs.writeFileSync(path.join(publicDir, 'index.html'),
    '<!doctype html><html><body><h1>p</h1><script src="probe.js"></script></body></html>');

  const pageWindow = new BrowserWindow({ show: false, width: 900, height: 700 });
  pageWindow.webContents.on('console-message', (_e, _l, message) => say('  [page] ' + String(message).slice(0, 200)));
  await pageWindow.loadURL('papers-backpack://' + projectId + '/public/index.html');
  await sleep(4000);
  const pageResult = await pageWindow.webContents.executeJavaScript('window.__probeResult ?? "no result"');
  say('PAGE RESULT : ' + pageResult);
  say('listener received: ' + received.length + ' request(s) ' + JSON.stringify(received));

  say('');
  say('=== summary ===');
  say('  1. bridge reaches the LIVE service : ' + (snapshot.ok === true && snapshot.status === 200));
  say('     real payload headSeq            : ' + headSeq);
  say('  2. declared-but-not-running honest : ' + (dead.ok === false && String(dead.detail).includes('could not be reached')));
  say('     undeclared origin refused       : ' + (undeclared.ok === false));
  say('     remote origin refused           : ' + (remote.ok === false));
  say('     disallowed method refused       : ' + (trace.ok === false));
  say('     unreadable credential refused   : ' + (unreadable.ok === false && bareSent === false));
  say('     page cannot forge a credential  : ' + (forged.ok === true && forged.status === 200));
  say('  3. CSP lets the page OPEN a loopback connection : ' + (received.length > 0));

  listener.close();
  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  app.exit(0);
}

main().catch((error) => {
  say('PROBE FAILED: ' + (error && error.stack ? error.stack : error));
  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  app.exit(1);
});
