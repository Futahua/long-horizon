// scratch: measure what a REAL Papers does when a papers-backpack:// page tries
// to reach a loopback http service.
//
// It drives the creator's own built Papers (loading out/main/index.js, so the real
// protocol handler, the real CSP and the real scheme privileges are in play), then
// navigates a window to a throwaway project's page.
//
// Three things are measured, not reasoned about:
//   1. the CSP header a project page actually receives
//   2. whether a fetch to http://127.0.0.1:<port> happens at all, and what the page
//      sees when it does not
//   3. the exact bytes that arrive at the service, including the Origin header
import { app, BrowserWindow, net } from 'electron';
import { createServer } from 'node:http';
import * as fs from 'node:fs';
import * as path from 'node:path';

const OUT = process.env['PROBE_OUT'];
const PROJECT_PATH = process.env['PROBE_PROJECT'];
const APP_ROOT = process.env['PROBE_APP_ROOT'];
const SERVICE_PORT = Number(process.env['PROBE_SERVICE_PORT'] ?? '4181');
const log = [];
const say = (l) => { log.push(l); console.log(l); };
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

// A listener that records EVERYTHING the page manages to send. If nothing arrives,
// the refusal happened before the network layer, which is itself the answer.
const received = [];
const listener = createServer((req, res) => {
  const chunks = [];
  req.on('data', (c) => chunks.push(c));
  req.on('end', () => {
    received.push({
      method: req.method,
      url: req.url,
      origin: req.headers.origin ?? null,
      cookie: req.headers.cookie ?? null,
      authorization: req.headers.authorization ?? null,
      headers: { ...req.headers },
    });
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ ok: true, sawYou: true }));
  });
});

async function main() {
  await new Promise((r) => listener.listen(0, '127.0.0.1', r));
  const listenerPort = listener.address().port;
  say(`listener on http://127.0.0.1:${listenerPort}`);

  // Load the REAL Papers main bundle. It performs bootstrap() itself and installs
  // the backpack protocol with the real privileges and CSP.
  say(`loading real Papers main from ${APP_ROOT}`);
  const mainPath = path.join(APP_ROOT, 'out', 'main', 'index.js');
  if (!fs.existsSync(mainPath)) {
    say(`MISSING ${mainPath}`);
    finish();
    return;
  }
  await import(`file://${mainPath.replace(/\\/g, '/')}`);
  await app.whenReady();
  await sleep(3000);
  say('real Papers main loaded and ready');

  // Read the project binding from the isolated registry.
  const dataDir = process.env['PAPERS_TEST_USER_DATA'];
  const bindingsPath = path.join(dataDir, 'backpack-projects.json');
  if (!fs.existsSync(bindingsPath)) {
    say(`NO BINDINGS at ${bindingsPath}`);
    finish();
    return;
  }
  const bindings = JSON.parse(fs.readFileSync(bindingsPath, 'utf8'));
  const projectId = Object.keys(bindings.projects ?? {})[0];
  if (!projectId) {
    say('NO PROJECT BOUND');
    finish();
    return;
  }
  say(`bound project: ${projectId} -> ${bindings.projects[projectId].root}`);
  const entry = (() => { try { return JSON.parse(fs.readFileSync(path.join(PROJECT_PATH, 'project.json'), 'utf8')).entry ?? 'public/index.html'; } catch { return 'public/index.html'; } })();
  const pageUrl = `papers-backpack://${projectId}/${entry}`;
  say(`page url: ${pageUrl}`);

  // The page body is written by the probe, not by Papers, so no product source is
  // touched. It reports its own results back over the SAME channel under test.
  const pageWindow = new BrowserWindow({ show: false, width: 900, height: 700 });
  const pageErrors = [];
  pageWindow.webContents.on('console-message', (_e, _level, message) => {
    pageErrors.push(message);
    say(`  [page console] ${message.slice(0, 300)}`);
  });

  // The probe writes the page into the project's public/ before loading.
  const publicDir = path.join(PROJECT_PATH, 'public');
  fs.mkdirSync(publicDir, { recursive: true });
  const pagePath = path.join(publicDir, 'index.html');
  // The page must load its script as a real ASSET: script-src does not allow
  // inline, which the first run proved by having its own probe script blocked.
  fs.writeFileSync(path.join(publicDir, 'probe.js'), `
const out = [];
async function probe() {
  try {
    const r = await fetch('http://127.0.0.1:${listenerPort}/direct', { credentials: 'include' });
    out.push('fetch-simple: OK ' + r.status);
  } catch (e) { out.push('fetch-simple: THREW ' + e.name + ': ' + e.message); }
  try {
    const r = await fetch('http://127.0.0.1:${listenerPort}/preflight', {
      method: 'POST', credentials: 'include',
      headers: { 'Content-Type': 'application/json' }, body: '{}',
    });
    out.push('fetch-preflight: OK ' + r.status);
  } catch (e) { out.push('fetch-preflight: THREW ' + e.name + ': ' + e.message); }
  try {
    const r = await fetch('http://127.0.0.1:${SERVICE_PORT}/v1/health', { credentials: 'include' });
    out.push('fetch-service: OK ' + r.status);
  } catch (e) { out.push('fetch-service: THREW ' + e.name + ': ' + e.message); }
  window.__probeResult = out.join(' | ');
}
probe();
`);
  fs.writeFileSync(pagePath, `<!doctype html><html><body><h1>probe</h1>
<script src="probe.js"></script></body></html>`);
  // Read the CSP the protocol handler actually attaches.
  const assetResponse = await net.fetch(pageUrl);
  say(`asset status: ${assetResponse.status}`);
  say(`asset CSP   : ${assetResponse.headers.get('content-security-policy')}`);
  say(`asset type  : ${assetResponse.headers.get('content-type')}`);

  await pageWindow.loadURL(pageUrl);
  await sleep(3500);
  const pageResult = await pageWindow.webContents.executeJavaScript('window.__probeResult ?? "no result"');
  say(`PAGE RESULT : ${pageResult}`);
  say(`PAGE ERRORS : ${pageErrors.length}`);
  say('');
  say(`--- what arrived at the listener (${received.length} request(s)) ---`);
  for (const r of received) {
    say(`  ${r.method} ${r.url}`);
    say(`    Origin        : ${r.origin === null ? '(absent)' : r.origin}`);
    say(`    Cookie        : ${r.cookie === null ? '(absent)' : r.cookie}`);
    say(`    Authorization : ${r.authorization === null ? '(absent)' : r.authorization.slice(0, 40)}`);
  }
  if (received.length === 0) {
    say('  NOTHING ARRIVED: the refusal happened before the network layer.');
  }

  // Does the page hold a cookie for the http origin at all?
  const { session } = await import('electron');
  try {
    const cookies = await session.defaultSession.cookies.get({ url: `http://127.0.0.1:${listenerPort}` });
    say(`cookies for the http origin: ${cookies.length}`);
  } catch (error) {
    say(`cookie read failed: ${error.message}`);
  }

  finish();
}

function finish() {
  fs.writeFileSync(OUT, log.join('\n'), 'utf8');
  try { listener.close(); } catch { /* ignore */ }
  app.exit(0);
}

main().catch((error) => {
  say(`PROBE FAILED: ${error && error.stack ? error.stack : error}`);
  finish();
});
