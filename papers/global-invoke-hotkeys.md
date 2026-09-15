# Global invocation chords: two system-wide shortcuts, and the boundary they keep

**Lane 4 · round four · new host capability, authorized directly by the creator**

> "when papers run, i want alt a to pop the run anywhere even when im using a different program.
>  alt shift a to bring papers to front"

**Committed** `523ad79ec43cbacad25031b27c50e0442bece455` at `2026-09-15T09:05:07+07:00`,
branch **`alt-invoke-global-hotkeys`**, cut from `58e7349` (identity 018) because it is unrelated
to identity. Not merged. Not pushed.

**Host suite at that SHA:** `100 passed | 1 skipped` files, **975 passed | 4 skipped (979)**,
5.06s. Baseline was 952 + 4 of 956 — **23 tests added, 0 removed, 0 newly skipped.**
`npx tsc --noEmit` exit 0.

---

## 1. The boundary that decided the design

Quick Run lives in the As you Go backpack, and that project's `AGENTS.md` forbids its name, id,
interface, prompt and action definitions from entering Papers' compiled source. Lane 3 has
honoured that throughout. A hotkey that hard-coded "quick run" in the host would break it.

So the host never learns what it is opening. It registers the accelerator, brings the focused
Papers window forward, and delivers a **neutral event** to the focused project's surfaces:

```
main   ->  webContents.send('papers:backpack:global-invoke', {
             projectId, surfaceId, chord: 'invoke', reason: 'global-accelerator'
           })
preload ->  window.postMessage({ type: 'papers:project:global-invoke', ... })
project -> decides that this means Quick Run
```

The host's whole vocabulary is *"the focused project's command surface received an invoke
request"*. It has no idea that a command surface is a thing the creator can see, what it is
called, or what it does. `src/main/windows/globalInvoke.ts` contains no Backpack name, prompt,
or action definition, and the tests assert the ids stay opaque.

---

## 2. What was measured before designing (Electron 43.1.1, this machine)

Four things I would have got wrong by reasoning from the documentation. Probes and raw output
are in `probes/electron-shortcut-probe.mjs` and `probes/electron-accelerator-parser-probe.mjs`.

```
register('Alt+Shift+F9')      -> true    isRegistered=true
register('Alt+Shift+F9') AGAIN-> false   isRegistered=true    <- taken chord => false, no throw
isRegistered('Ctrl+Alt+Shift+F12') with no registration -> false
```

**Finding 1 — the failure is detectable, and it is a bare `false`.** `register()` returns false
when the chord is taken and does not throw. That is precisely the silent-failure shape this
codebase keeps repeating: the creator presses the key, nothing happens, nothing says why. Every
refusal is turned into a named, surfaced record here.

**Finding 2 — Electron's parser is permissive in dangerous directions.**

```
register('NotAKey+Q')   -> true     (a nonsense token, accepted)
register('Super+A')     -> false    (no throw, no reason)
register('Alt+NotAKey') -> THREW TypeError
register('A')           -> true     <-- a bare key, no modifier
```

That last one is the serious one. A future settings value of `"A"` — one typo — would register
the letter **A** globally and swallow it in **every application on the machine**. Accelerators
are therefore validated in this module before the backend sees them, and a chord with no
modifier is refused with a named reason. Unknown tokens are refused rather than accepted
(`NotAKey+Q`) or dropped.

**Finding 3 — "bring to front" is a sequence, not a call.** Measured with a real `BaseWindow`:

```
after focus()               isMinimized=false isVisible=true  isFocused=false
after minimize()            isMinimized=true  isVisible=false
after show()+focus()        isMinimized=false isVisible=true  isFocused=true
after hide()                isMinimized=false isVisible=false
after show()+focus()        isMinimized=false isVisible=true  isFocused=true
```

`focus()` alone does **not** clear `isMinimized`. The order is
`restore()` → `show()` → `focus()` → `moveTop()`, and `moveTop` is a plain re-stack — never
`setAlwaysOnTop`, which would pin Papers above everything for the rest of the session.

**Finding 4 — `isRegistered` reports only this process's own claim.** With another process
holding a chord it correctly reads `false`. It is therefore useless as a cross-process probe,
and the live verification uses a second Electron process trying to *take* the chord instead.

---

## 3. What was built

| File | What it is |
| --- | --- |
| `src/main/windows/globalInvoke.ts` | The chords: validation, registration, typed refusals, release, and the neutral invoke. Dependency-injected, so it is tested without Electron. |
| `src/main/windows/windowFront.ts` | The bring-to-front sequence and the honest report of what it observed. |
| `src/main/index.ts` | Wiring: window resolution, surface resolution, event delivery, the host-error surface, and release on `before-quit`. |
| `src/preload/backpackProject.ts` | One line in the existing relay table: the neutral event reaches the project page. |
| `src/main/control/papersControlProtocol.ts` | `globalShortcuts` in `inspect.snapshot`, so a refused chord is inspectable. |

**Every outcome is typed.** The invoke path reports:

| Outcome | Meaning |
| --- | --- |
| `brought-forward-invoked` | Papers came forward and the surface was asked to open. |
| `brought-forward-nothing-to-open` | Papers came forward, and there is nothing to open. |
| `window-unavailable` | Papers could not come forward at all. |

The middle one exists because the brief called it out: with no project open, `Alt+A` must still
bring Papers forward **and say plainly that there is nothing to open**. It is surfaced through the
same `host:event:host-error` channel the rest of the app uses, so it cannot look like nothing
happened.

**Circumstances I decided rather than measured, stated as decisions:**

- **A second Papers instance** cannot take the chords. They are held process-wide, and a second
  launch already routes into the running window through the existing `second-instance` handler.
  Verified indirectly: a second Electron process calling `register()` for either chord gets
  `false` while the first instance runs.
- **Disable:** there is no settings UI (the brief forbids building one). `release()` is public and
  idempotent, and the chords arrive as an injected value (`accelerators`), so a settings surface
  can supply and change them later without touching the module. Nothing makes one impossible.
- **`unregisterAll` is never called.** It would release chords this module does not own. A test
  asserts it is not used.

---

## 4. Verification

### 4.1 Tests, written first where a test could exist

`tests/unit/globalInvoke.test.ts` was committed-as-failing before the module existed
(`Cannot find module '../../src/main/windows/globalInvoke'`). 16 tests there, 7 more in
`tests/unit/windowFront.test.ts`. They cover: a taken chord refused by name; **no fallback chord
ever registered**; an unparseable accelerator turned into a named refusal instead of a throw; a
bare-key chord refused; independent registration so one refusal does not disarm the other;
release releasing exactly what it took; release idempotent and safe before registration; and the
three invoke outcomes including "nothing to open".

The fake `globalShortcut` in those tests encodes the **measured** behaviour — `false` on a taken
chord, `throw` on an unparseable one — so the tests exercise the real contract rather than a
convenient one.

### 4.2 Live, against a real running Papers

`probes/probe-24-global-invoke-live.ps1`, **9 of 9 PASS**. Isolated instances launched with
`PAPERS_TEST_USER_DATA` (and `PAPERS_DEV_CONTROL` + an explicit descriptor) so the creator's
Papers, vault and layouts were never involved.

```
--- 1. with no contention ---
  registered : Alt+Shift+A, Alt+A
  failures   : 0

--- 2. with another process holding Alt+A ---
  holder: holding pid=63376 Alt+A=true
  registered : Alt+Shift+A
  failure    : Alt+A chord=invoke reason=already-registered-by-another-application

--- 3. contention from a third process ---
  CONTENTION Alt+Shift+A: isRegistered-before=false register()=false
  CONTENTION Alt+A:       isRegistered-before=false register()=false

--- 4. after Papers quits ---
  CONTENTION Alt+Shift+A: register()=true
  CONTENTION Alt+A:       register()=true
```

That single run establishes, by running: both chords register when free; a taken chord is
**refused with its name and a reason** while the other still registers; no third process can take
either while Papers holds them; and both are **released when Papers quits**.

### 4.3 The probe lied first

The first run reported **6 failures** that were entirely the probe's own defect: it never stopped
the first Papers instance, so that instance legitimately held both chords and the "contention"
being measured was itself. The fix was to stop the instance and poll until the chords are
genuinely free.

This is recorded because of what it looked like: a page of red that read exactly like a broken
feature, when the product's refusal reporting was correct throughout — during the broken run it
correctly reported *both* chords as already-registered-by-another-application, which was true.

---

## 5. What I could not verify

Stated plainly. All three need a human at the machine watching real windows move.

1. **A Papers window on another virtual desktop.** Electron exposes no API to move a window
   between virtual desktops. The same sequence is attempted and the observed state reported;
   nothing claims this situation succeeded.
2. **A Papers window behind a fullscreen application.** Whether focus is granted depends on the
   other process's foreground-lock behaviour, which is not testable from here.
3. **A real human pressing the chords.** The live probe proves the chords are *held* and
   *released*, and the unit tests prove the callbacks do the right thing, but no finger pressed
   `Alt+A` while another application had focus. The creator is the only one who can confirm the
   felt behaviour.

Also unverified: that `moveTop()` visibly changes stacking on a desktop with a fullscreen
application in front of it. It is a plain re-stack and is expected to work; expected is not
verified.

---

## 6. The one thing for Lane 3

The backpack side is Lane 3's, not mine. Exactly one thing to implement:

> **In the As you Go project page, listen for `papers:project:global-invoke` on `window` and
> treat it as "the creator pressed the command-surface chord": open the command surface, i.e.
> run what Quick Run runs.**
>
> Shape of the event:
> ```js
> window.addEventListener('message', (event) => {
>   if (event.source !== window || event.origin !== window.location.origin) return;
>   if (event.data?.type !== 'papers:project:global-invoke') return;
>   if (event.data.reason !== 'global-accelerator') return;
>   // open the command surface here
> });
> ```

The host has already brought Papers to the front before the event is sent, so the project does
not need to raise a window. The project does not need to ask whether Papers is focused.

**One caveat, stated rather than hidden.** The event is delivered to the project's live
surfaces and carries `projectId`, `surfaceId` and `chord`, but **not** the receiving surface's
identity. The preload that relays it does not know its own `surfaceId` — it serves the workspace
frame and detached surfaces alike. So if a project has both a workspace surface and a detached
surface open, both receive the event and both would react. For v1 that is harmless (the command
surface is a singleton surface), but if Lane 3 wants surface-scoped delivery, that needs a
preload change and should be asked for explicitly rather than assumed. I did not build it,
because inventing a field the project cannot verify would be worse than stating the gap.

---

## 7. Safety

- The creator's Papers was **never restarted and never disturbed**. Their 8 Papers processes ran
  throughout.
- Every live test used an isolated `PAPERS_TEST_USER_DATA` directory. Four temp data directories
  were created and removed.
- No application window was moved, hidden, re-ordered or closed during this round.
- All probe Electron processes, holder processes and temp directories were cleaned up; verified
  zero leftovers afterwards.
- No settings UI was built, and no existing chord handling was touched. `src` had no
  `globalShortcut` usage before this change; it now has exactly one, in the new module's wiring.
