# Identity 018: the first host change, and the defect found underneath it

**Lane 4 · round three · the identity primitive lands in Papers**

**Committed** `58e7349239e18bdae2e5127d5451746145e37ab1` at `2026-09-15T08:05:58+07:00`,
branch **`lane4-window-identity`**, cut from `9a839eb`. Not merged. Papers working tree clean.

**Host suite at that SHA:** `98 passed | 1 skipped` files, **952 passed | 4 skipped (956)**,
5.10s. Baseline was 942 + 4 of 946; **10 tests added, 0 removed, 0 newly skipped.**
`npx tsc --noEmit` exit 0.

Authorised by `LongHorizon@227f25a`, which reopened the 2026-09-13 refusal for identity work
only. Held to that scope exactly: nothing from the round-two prohibitions was built.

---

## 1. What changed

The defect, measured in round one and again here before the fix:

```
observe (title unchanged)                -> outcome=success
[title changes; same HWND, same PID, window alive]
observe (same token, title changed)      -> outcome=denied
                                            error=window identity changed since the token was issued
[title restored]
observe (original token)                 -> outcome=success
```

A healthy, live window became unusable because a *string in its title bar* changed, and became
usable again when the string changed back. One failing consumer away from deleting real windows
from real layouts.

**The session-token identity key was `HWND | PID | exact title`.** It is now
**`HWND | PID | window class`**, and the exact title is compared nowhere on the identity path.

| File | Change |
| --- | --- |
| `resources/window-helper/window-helper.ps1` | `Get-WhIdentityKey` keyed by class, not title; `New-WhSessionToken` stores `className`; `Test-WhTokenIdentity` compares PID + class; `Test-WhListCapacity` rekeyed; `list` and `hover` issue class-keyed tokens; both wire observations carry `windowClass` |
| `resources/window-helper/window-capability.ps1` | `Get-WhWindowObservation` returns `ClassName` from the already-P/Invoked `GetClassName` |
| `src/main/windows/windowCapabilityTypes.ts` | `WindowObservation.windowClass?: string`; parser accepts a string or absence, rejects any other type |
| `src/main/windows/windowHelperResource.ts` | protocol `017` → `018`; both byte pins updated |
| `resources/window-helper/manifest.json` | protocol `018`; both hashes updated |
| `tests/unit/windowCapability.test.ts` | 7 tests for the new field |
| `tests/unit/windowHelperResource.test.ts` | 3 guards, including the fresh-checkout proof |

The class is **corroboration, not a discriminator**, and the code says so in three places.
Class names are unique per *process*: they back every window of that process, so two windows of
one application share one and only the runtime id separates them. Measured on the creator's live
Chrome — one process, two windows, one class, **correctly two tokens**.

`windowClass` is parsed **optionally** so an older helper or a test fake stays valid. Absence
means *not corroborated*, never *mismatch* and never *agreement*. A present-but-wrong-type value
is rejected outright, because silently dropping it would turn "cannot be corroborated" into
"corroborated by nothing" — the exact failure the field exists to prevent.

---

## 2. The defect found underneath the change

While updating the pins I found that the pins did not describe the bytes a checkout receives.

```
window-capability.ps1   working copy : CRLF, sha256 9f11a999…   (before my fix)
                        HEAD blob    : LF,   sha256 0a0cb34f…
                        compiled pin :            50b8efb5…    <- matches NEITHER
```

`.gitattributes` declares `* text=auto eol=lf`, so a checkout always delivers LF. The suite
passed only because it hashes the **working copy**, which on this machine was CRLF. On a fresh
clone, a CI runner, or a packaged build the bytes are LF, provenance validation fails, and
**the window helper never spawns at all**.

This is pre-existing, not introduced by this change, and it is the single most consequential
thing this round found: a provenance lock that silently does not hold in the environments that
matter most.

**Fixed:** both pinned scripts are now LF in the working tree *and* in the index; the pins are
recomputed from those canonical bytes; and two guards make the class of defect impossible rather
than merely absent today.

- One validates the **committed blob** (staged, falling back to HEAD) against the compiled pin
  and fails if the blob contains CRLF.
- One materialises **nothing but the git-delivered bytes** into a temp directory and runs the
  product's own `validateWindowHelperResource` against it — the end-to-end proof that a fresh
  checkout validates.

Verified independently of the suite:

```
exported the committed tree's resource dir
  window-helper.ps1      bytes=35800 crlf=0 sha256=c4057656…  bytes==pin:true manifest==pin:true
  window-capability.ps1  bytes=44945 crlf=0 sha256=d9f6ca87…  bytes==pin:true manifest==pin:true
  protocolVersion=018 versionMatches=true
  FRESH CHECKOUT VALIDATES: true
```

And because normalising line endings changes bytes that get *executed*, PS 5.1 was checked
running an LF-only script before trusting it: `LF_PROBE_OK value=42` under
`System32\WindowsPowerShell\v1.0\powershell.exe`, exit 0.

---

## 3. Verification, and the limit of the suite

The host suite is necessary and **not sufficient**, and that has to be said plainly: it has no
executable test for the helper, only string assertions on the `.ps1`. A green suite proves the
TypeScript layer still parses. It proves nothing about identity.

The identity claims were therefore verified by driving the **real shipping helper** over its own
JSON-lines protocol — `probes/probe-23-identity-revision.ps1`, **10 of 10 PASS**, against the
LF-normalised files:

```
[PASS] every listed window carries windowClass on the wire                 17 of 17
[PASS] the window itself is unchanged apart from its title
[PASS] observe succeeds before any mutation
[PASS] THE FIX: observe still succeeds after only the title changed        outcome=success
[PASS] the token is REUSED across the title change                         T865a57a… == T865a57a…
[PASS] the class reported after the title change is unchanged              'Notepad' == 'Notepad'
[PASS] the title reported on the wire DID change (the mutation was real)   'Untitled - Notepad' -> 'PROBE-018 title changed at …'
[PASS] a token for a dead window still reports missing
[PASS] a guessed token still fails closed
[PASS] two windows of one process receive distinct tokens                  2 tokens, 1 class
```

The last row is the one that matters most for the next round: **one class, two tokens.** If the
class were ever promoted from corroboration to discriminator, that row is what fails.

### 3.1 Three instrument defects, because a probe that lies is worse than no probe

All three were hit and fixed before any result was believed.

1. **One request per helper process.** The first run reported three FAILs that were entirely my
   probe's fault: each request spawned a fresh helper, so the token died with the helper and the
   probe was measuring a *helper restart*, not a title change. The helper "correctly" reported
   `unknown session token`. Fixed by running the whole sequence in one helper process and
   performing the title mutation *between* requests.
2. **A mutator cannot live in the parent.** The parent PowerShell process cannot mutate while
   blocking on the child, so `helper-client.mjs` gained a `mutate` step that runs a
   probe-owned single-handle mutator between two requests.
3. **Piping responses through a shell shifted every assertion by one.** PowerShell's `2>&1`
   interleaving injected a non-string record that my filter did not remove, so `$responses[0]`
   was a phantom and every later index was off. Fixed by having the client write its responses to
   a **JSON file** instead of stdout; a file has no such failure mode.

None of the three is in the shipped code. They are recorded because the first run's "3 FAIL"
looked exactly like a real regression in my own change.

---

## 4. Deliberately NOT done

- **No retirement, pruning or "remove invalidated" behaviour.** Still the hard gate.
- **No auto-tracker, no lifecycle watcher, no tracking state.**
- **No destructive cross-layout removal.**
- **No automatic legacy migration.**
- **No title, PID or ordinal fallback anywhere.** When the gate cannot corroborate, the operation
  fails; it never downgrades so that it can succeed.

### 4.1 One thing left title-keyed on purpose

`resolvePersisted` in `windowCapabilityService.ts:893` still resolves a persisted descriptor by
`executableFingerprint + exact title`. That is a *different* identity path — it is how a stored
member reconnects to a live window — and changing it decides legacy-member migration semantics,
which this round is explicitly forbidden to touch. It is left exactly as it was and named here so
the next round starts from a known state rather than a surprise.

### 4.2 The honest limit of the fix

The new gate proves **"this handle still belongs to the same process and the same class of
window"**. It does **not** prove **"this is the same window object"**: Windows may recycle a
handle value, and a replacement in the same process with the same class would satisfy every
clause. This is stated in the helper's own header, where the next reader will meet it, along with
the consequence — **a failed check is UNVERIFIED, never "gone"**.

That is the boundary of what landed. The per-HWND enrolled generation marker that would close the
*object* question is designed and measured (rounds two and three probes) but **is not built**,
and building it without a consumer that respects `UNVERIFIED` would be the unsafe order.

---

## 5. State for the next round

| Fact | Value |
| --- | --- |
| Branch / SHA | `lane4-window-identity` @ `58e7349239e18bdae2e5127d5451746145e37ab1` |
| Base | `9a839eb` (`native-source-diagnostic-preload`) |
| Host suite | 952 passed \| 4 skipped of 956, 5.10s; typecheck exit 0 |
| Protocol | `018` (manifest + compiled constant + both byte pins agree) |
| Live evidence | `probes/probe-23-identity-revision.ps1`, 10/10 PASS |
| Not built | retirement, auto-tracker, migration, generation marker, UNVERIFIED state |
| Left alone | `resolvePersisted` exact-title resolution; live vault; real layouts |
