# Alt+Shift+A is a toggle

**Lane 4 · round five (continued) · same branch as the launcher overlay**

**Committed** `4a6120a379c91e5d9e7fadfecaa72a9174b56259` at `2026-09-15T09:42:24+07:00`,
branch **`alt-a-launcher-overlay`**, on top of the overlay commit `5acc506`. Not merged, not
pushed. It did **not** fight the overlay work, so it stayed in the same round as you asked.

**Host suite at that SHA:** `103 passed | 1 skipped` files, **1025 passed | 4 skipped (1029)**,
5.00s. The overlay commit was 1005 + 4; **20 tests added, 0 removed, 0 newly skipped.**
`npx tsc --noEmit` exit 0.

---

## 1. The rule, in one sentence

> **If the window you are looking at is Papers, the chord minimises it; otherwise the chord brings
> Papers forward.**

That sentence is exported as `TOGGLE_RULE` and a test asserts it verbatim, so the intent cannot
drift away from the behaviour without the test failing.

---

## 2. The judgement: foreground, not visibility

You asked for the ambiguous cases to be thought about rather than assumed. The tempting shorthand
— *"can the creator see Papers?"* — is the wrong question, and here is each case with its answer:

| Case | Foreground? | What happens | Why |
| --- | --- | --- | --- |
| Papers visible but unfocused (typing in Chrome, Papers behind it) | no | **raise** | They are summoning it. Hiding it here would make the chord fight itself. |
| Papers focused on another monitor | **yes** | **minimise** | Which monitor is not part of the question. Foreground is foreground. |
| Papers focused but partially covered | **yes** | **minimise** | It is the window in front; the chord dismisses it. |
| Several Papers windows, one focused | **yes** | **minimise the FOCUSED one** | The window they are looking at is the one the chord acts on — never merely the most recently used. |
| Papers minimised already | no | **raise** | Foreground cannot be a minimised window, so it restores. |
| No Papers window at all | — | **report unavailability** | Never a silent no-op. |

If visibility were the test, the first row would minimise a window the creator was in the middle of
summoning. That is the trap the rule avoids.

**The preference, as you specified it: every uncertain path raises, never minimises.**

| Uncertainty | Result |
| --- | --- |
| `isForeground()` throws or cannot answer | raise |
| Foreground is Papers by process, but matches no owned window | raise |
| The named window is destroyed | raise |
| The minimise call throws or does not take effect | **fall back to raising** |

An unwanted raise costs one more keypress. An unwanted minimise hides work they were looking at.
The second is strictly worse, so the code never chooses it on an uncertain answer.

---

## 3. Where focus lands after a minimise

Windows does not reliably pick a sensible next window, so the toggle chooses explicitly: **the next
window down the z-order from the one being hidden** — literally the window that was underneath it.

That needed a new native command. `fg-bridge.cs` gained `next <handle>`, which walks `GW_HWNDNEXT`
and returns the first window that is visible, not minimised, unowned (owned windows travel with
their owner) and not the shell or desktop. Measured live:

```
next below top        : handle=1976558 class=Chrome_WidgetWin_1 title=PROBE-UNDER
  it found PROBE-UNDER: true
next on a bogus handle: none  (exit 5)
```

And if it cannot be found or focused, **the minimise still stands** and the outcome says plainly
that focus was not placed. A failed focus hand-off never undoes the minimise — that would be a
worse bug than the one it was avoiding.

---

## 4. The overlay interaction — decided, as you asked

**Pressing Alt+Shift+A while the Alt+A launcher is open minimises Papers *and* takes the launcher
down with it.**

The reasoning: the launcher is not a window the creator manages. It exists to be summoned and
dismissed, and if they are pressing the chord that puts Papers away, leaving a launcher floating
over whatever they moved on to would be the opposite of the intent. It is closed with the
`dismissed` reason, so focus is handed back to the application they came from exactly as a normal
dismissal does.

Nothing about the overlay's own open/close path changed, and the overlay tests still pass unchanged.

---

## 5. Two defects found by running it — both silent failures

This is the third round in a row where running the thing found what reasoning did not.

**1. `SetForegroundWindow` on the window that already owns the foreground HANGS.**

A real end-to-end run *timed out on its final step*. The sequence before it had all worked —
foreground read, z-order walk, minimise, focus hand-off — and then the repeat call sat there until
the bridge's own timeout fired.

```
set(under) again : ERR spawnSync ...ETIMEDOUT     (before)
set(under) again : already=1 moved=1 fg=1976558   (after)
```

This is not a corner case. The hand-off target is *often* already in front by the time focus is
restored, so real use would have hit it constantly and shown the creator a timeout instead of an
answer. The bridge now short-circuits: if the target is already the foreground, it says so and
returns immediately. Windows grants a foreground process the right to take the foreground, which
is exactly why the real hand-back succeeds moments after the caller took focus — so the guard costs
nothing in the case that matters.

**2. Electron's `minimize()` returns `void`.** Returning `true` after calling it was a *claim*, not
an observation — the same false-success shape as the PowerShell helper's `restore`. It now verifies
`isMinimized()` and reports honestly, so a hide that did not happen falls back to raising instead of
pretending.

A regression test covers the hang case directly (it asserts the answer arrives in under four
seconds against an eight-second timeout).

---

## 6. Verification

### 6.1 Tests, written first

`tests/unit/windowToggle.test.ts` was committed-as-failing before `windowToggle.ts` existed
(`Cannot find module '../../src/main/windows/windowToggle'`). 17 tests covering the rule verbatim,
all four ambiguous cases, the focused-of-several case, the overlay-independent minimise path, the
z-order focus choice, the refused focus hand-off, the failed-minimise fallback, and both
uncertainty paths resolving to raising.

### 6.2 The primitive sequence, driven end to end against real windows

Because the toggle's decision logic is unit-tested and its *primitives* cannot be, the primitives
were driven against two real windows the probe owned — so the creator's desktop was never touched:

```
under handle=1976558  top handle=2952170
bridge get            : handle=2952170 ... title=PROBE-TOP
  top is foreground   : true
next below top        : handle=1976558 ... title=PROBE-UNDER   -> found the window underneath
after minimize(top)   : foreground is now PROBE-UNDER          isMinimized=true
after set(under)      : focus moved to under: true
set(under) again      : already=1 moved=1 (prompt, no hang)
```

Every step the toggle performs was observed working on real windows.

### 6.3 Refusals

| Refusal | What it looks like |
| --- | --- |
| No Papers window at all | `window-unavailable`, "no Papers window is open" |
| Cannot read the foreground | raise, never minimise |
| Foreground is Papers but matches no owned window | raise, never minimise |
| The minimise did not take effect | falls back to raising |
| Nothing usable underneath to focus | minimise stands; "there was no window underneath to give focus to" |
| Focus hand-off refused | minimise stands; "the window underneath could not be given focus" |
| Next-window lookup throws | minimise stands; the failure is named |

---

## 7. What needs a human at the machine

**The felt behaviour of pressing Alt+Shift+A twice while working in another application.** This
machine is in active use and a background process cannot take focus, so what is measured here is
the primitive sequence on controlled windows — not the toggle as the creator experiences it. The
two things only they can confirm:

1. Press it while in another application: Papers comes forward.
2. Press it again: Papers goes away, and the application they came from has the keyboard.

Also unverified: which window focus lands on when the window underneath is itself a full-screen
application, and the same for virtual desktops. Electron exposes no API to move between desktops.

---

## 8. Safety

- The creator's Papers was **never restarted and never disturbed**; their 7 processes ran throughout.
- No window the creator owns was minimised, moved, hidden or closed. Every window exercised by the
  sequence probe was created and destroyed by that probe.
- All temp data directories, compiled bridge copies and probe processes were removed; verified
  0 probe Electron processes and 0 notepad processes afterwards.
- Nothing was pushed. Both commits are on `alt-a-launcher-overlay`:
  `5acc506` (the launcher overlay) and `4a6120a` (this toggle).
