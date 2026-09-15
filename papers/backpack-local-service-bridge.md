# A backpack page can reach a service on this machine

**Lane 4 · round six · branch `backpack-local-service-bridge`, cut from `main` @ `523ad79`**

**Committed** `5d039f746dcdf793da457e44868ccfdb9d03f6b1` at `2026-09-15T10:03:02+07:00`, branch
**`backpack-local-service-bridge`** — on top of `523ad79` (the Alt+A chord commit that is now on
`main`). Not merged into `main`, **not pushed**, **not installed**.

**Host suite at that SHA:** `102 passed | 1 skipped` files, **994 passed | 4 skipped (998)**, and
`npx tsc --noEmit` exit 0. Baseline on `main` @ `523ad79` was `975 passed | 4 skipped (979)`.
**19 tests added, 0 removed, 0 newly skipped.**

---

## 1. The report I was working from

The Proxima cockpit rendered, in the creator's own words, the banner:

> The Proxima service is not reachable (Failed to fetch). This board is a read-only copy…

at a moment when the service was **healthy**: `http://127.0.0.1:4181/v1/health` answered, and
`/v1/snapshot` carried `headSeq 165`. The service was running, on loopback, on the same machine,
and the page still reported it unreachable.

"Failed to fetch" is the browser's word for *the request never happened as far as this page is
concerned*. It says nothing about which layer stopped it. There were two, one behind the other,
and the first one hides the second.

---

## 2. What was measured, against a real Papers

Not reasoned about — measured, with a throwaway backpack project bound into an isolated Papers
(`PAPERS_TEST_USER_DATA`), a listener on loopback, and the real protocol handler in play. Probe:
`probes/papers-local-service-probe.mjs`.

### Layer one: the content security policy refuses before the network layer

`connect-src 'none'`. The listener received **zero** requests. The page saw
`TypeError: Failed to fetch`.

This is worth stating precisely because it is the shape of the bug: **nothing was sent**. CORS,
scheme privileges, cookies, `Origin` — none of it was ever consulted. Every theory about what the
service should allow was a theory about a request that had not been made.

It also means the banner was *not lying about what it could see*. The page genuinely could not
fetch. The defect was upstream of the page.

### Layer two: once the policy lets it out, CORS stops it — and `Origin` is finally visible

With `connect-src` relaxed to loopback, the request **is** sent. The listener saw it, and saw the
header that had been unprovable until now:

```
Origin: papers-backpack://<projectId>
```

That is the real, observed origin of a real Papers page — not `null`, not `file://`, not absent.
Lane 1 could not fake this and had left it unproven; it is now measured.

It then dies on CORS: the service sends no `Access-Control-Allow-Origin`, so the page sees
`TypeError` again. A preflight `OPTIONS` reaches the service as well.

### Not the carrier: cookies

```
cookies for the http origin: 0
```

A session cookie **cannot** make the custom-scheme → http trip in this configuration. Lane 1's
suspicion that this was a cookie problem was reasonable and is now settled — as is the conclusion
that the fix cannot be "make the cookie work".

### A measurement failure of my own, recorded because it wasted an hour

The first version of the probe put its script **inline** in the page. `script-src` blocked it, so
the probe reported nothing at all and looked like a policy result. It was my probe, not Papers.
The probe now loads an external asset. Also recorded: one request per helper process exhausts the
service's token, and PowerShell's `ReadLineAsync` retry loop reports "stream is currently in use"
— both probe defects, both fixed, neither a Papers defect.

---

## 3. What was built

### 3a. The policy, widened to loopback and nothing else

`connect-src` is now:

```
http://127.0.0.1:* http://localhost:* ws://127.0.0.1:* ws://localhost:*
```

Every other directive is untouched, and a test asserts that. The old value also carried the
`'none'` keyword; Chrome **ignores a directive that carries `'none'` alongside other sources**, so
that keyword is removed rather than merely outnumbered. Leaving it in would have produced a policy
that reads as "loopback allowed" and behaves as "everything allowed" if anyone later added a
source without noticing.

### 3b. The request is made from the main process, by a bridge the project declares

A relaxed policy is necessary and not sufficient, because the second layer is still there. So
`localServiceBridge` makes the request **from the main process**, where no page origin exists for
CORS to police, and attaches a credential **the project declares in its own file**.

The design point: **the host knows nothing about any project.** No project name, port, protocol or
token is compiled into Papers. The project ships a declaration; the host enforces it; the
credential is a file the project names. Any backpack project can use this — it is not a hole cut
for one.

Declaration, `<project root>/local-service.json` beside `project.json`:

```json
{ "schemaVersion": 1,
  "services": [{ "origin": "http://127.0.0.1:4181", "secret": "operator" }],
  "secrets": [{ "id": "operator",
                "file": "D:\\Letters\\MatTroiSeConMoc\\Proxima Data Home\\token",
                "header": "authorization", "scheme": "Bearer" }] }
```

Bounds the bridge enforces, each with tests:

| Bound | Behaviour |
| --- | --- |
| Loopback only | a non-loopback declared origin is refused: *"not a loopback address"* |
| Declared origins only | an origin the project did not declare is refused |
| Methods | `GET/POST/PUT/PATCH/DELETE/HEAD/OPTIONS` only; `TRACE` refused |
| Request headers | `content-type, accept, last-event-id, cache-control` only |
| Page-supplied credentials | `authorization` and `cookie` from the page are **stripped** |
| Credential | read from the declared file, attached in main, **never sent to the page** |

Stripping the page's credential headers is deliberate twice over: a page must not be able to
**forge** an identity, and must not be able to **probe** by supplying one and reading the answer.

---

## 4. The property that had to survive, and did

The honest-refusal property is the whole point of the banner. If the bridge papered over failures,
the banner would become decorative and the creator would lose the one signal telling them the board
is stale.

**The bridge never authenticates anything itself and never softens a refusal.**

- A `401` from the service comes back as a `401` with `ok: true`. The service's own auth boundary
  is intact. **Nothing was weakened on the service side** — not its token, not its nonce, not its
  401. `/v1/health` stays open (200 unauthenticated); `/v1/snapshot` still returns 401 without the
  bearer.
- If the declared credential **cannot be read**, the bridge refuses to send the request at all,
  rather than sending it bare and reporting the service's consequent 401 as if that were the whole
  story. `bareRequestSent: false`, measured.
- `ok: false` means the service was unreachable. Callers must render the banner on `ok: false`
  only — never on a non-2xx status.

End-to-end, against the creator's **real running service** through a **real Papers**:

| Case | Result |
| --- | --- |
| bridge → live service | `ok=true status=200 headSeq=165 schemaVersion=1 boardPresent=true` |
| service declared but not running | refused — *"the service could not be reached: net::ERR_CONNECTION_REFUSED"* |
| origin not declared by the project | refused |
| remote (non-loopback) origin | refused — *"not a loopback address"* |
| `TRACE` | refused |
| unreadable credential | refused, **and no request was sent** |
| page-supplied `authorization: Bearer PAGE-SUPPLIED` + `cookie: session=stolen` | ignored; `ok=true status=200`, the **real** credential used |
| CSP lets the page open loopback | true — listener received 2 requests vs **0** before the change |

`headSeq 165` is the creator's actual board, read through the bridge. Two independent directions of
honesty: the banner cannot appear while the service is reachable through the bridge, and a
genuinely absent service is still reported as unreachable.

---

## 5. The one thing Lane 1 must change

Replace the page's own `fetch` with the bridge call, and ship the declaration. **That is the entire
project-side change.** Everything else — the service, its token, its 401 — stays as it is.

```js
// public/<cockpit>.js  — no credential here, ever
window.postMessage({ type: 'papers:project:local-service-fetch',
  url: 'http://127.0.0.1:4181/v1/snapshot', method: 'GET' }, location.origin);
// reply: { type: 'papers:project:local-service-result',
//          localService: { ok, status, headers, body } }
```

Plus `local-service.json` beside `project.json` (project root, **not** under `public/`), as in §3b.

**A direct page fetch cannot be made to work from the service side.** The Origin is
`papers-backpack://<projectId>`, which would have to be added to `--allow-origin` on every
re-registration (the project id changes), and CORS would then also have to answer the preflight.
The bridge avoids that and leaves the service's CORS policy exactly as strict as it is now. That is
why the cookie carrier is not merely awkward but unnecessary — and why **the service must not be
made more permissive to compensate**.

---

## 6. Not verified — needs a human at the machine

The bridge and the policy are proven; **the real cockpit rendering against the real service inside
the installed Papers is not.** This round did not touch Lane 1's files and does not know whether
their page has moved to the bridge yet. Until it does, the installed Papers will still show the
banner — correctly, because the page is still fetching directly.

The creator's installed Papers is at `D:\Letters\MatTroiSeConMoc\Papers\App` (asar-packed, main at
`523ad79`); the bridge commit does **not** include it. Nothing was installed this round.

## 7. Housekeeping

6 files modified, 3 added, 755 insertions, 4 deletions. Working tree clean. All probe fixtures and
copies removed; 0 probe Electron processes left; the creator's 7 Papers processes untouched; the
one `proximad.mjs` service left running as found. `Papers-3` was not pushed.
