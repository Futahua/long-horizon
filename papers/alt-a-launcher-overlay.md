# Alt+A is a launcher, not a window switcher

**Lane 4 · round five · correcting a shipped behaviour after the creator used it**

**Committed** `5acc5067c2188c940967be92a974a30372a9f961` at `2026-09-15T09:33:20+07:00`,
branch **`alt-a-launcher-overlay`**, cut from `main` (`523ad79`, the installed build). Not merged,
not pushed.

**Host suite at that SHA:** `102 passed | 1 skipped` files, **1005 passed | 4 skipped (1009)**,
5.28s. Baseline was 975 + 4 of 979 — **30 tests added, 0 removed, 0 newly skipped.**
`npx tsc --noEmit` exit 0.

**Alt+Shift+A is untouched.** The creator confirmed it in their hands.

---

## 1. The correction, and what it was

> "they all work, but my idea of alt a is not to bring papers forward"

Re-reading the original sentence, it was there all along: *"pop the run anywhere even when im
using a different program"*. **The popping was the request.** Bringing Papers forward was an
interpolation, and it is now removed: the invoke chord never calls `bringToFront` again, and a
test asserts that it never does.

| | Before | Now |
| --- | --- | --- |
| Alt+Shift+A | bring Papers forward | **unchanged** |
| Alt+A | bring Papers forward + invite the surface | **pop the command surface over whatever they are doing; Papers does not move** |

Papers stays exactly where it was in the z-order — minimised if it was minimised. The
application they came from keeps its place and gets focus back when the overlay closes.

---

## 2. What was built

**The overlay has its own host window.** A small, borderless, always-on-top, non-resizable,
non-fullscreenable, taskbar-skipping `BrowserWindow`. It loads **the focused project's own entry
URL** with an opaque mode marker appended (`papers-surface=command-surface`) — the same mechanism
the compact widget already uses — and the neutral event is delivered into *that* window.

**The boundary is intact.** No Backpack name, prompt or action definition enters the host. The
host knows three things: which project is focused, that a surface exists for it, and that the
creator pressed a chord.

The chord is a toggle: pressing it while the overlay is open dismisses rather than stacking.

| File | What it is |
| --- | --- |
| `src/main/windows/commandSurfaceOverlay.ts` | The overlay: placement, focusing, focus capture/return, refusals. Dependency-injected and fully tested. |
| `src/main/windows/foregroundBridge.ts` | The native foreground bridge: compile-once-and-cache, fail-closed. |
| `resources/native/fg-bridge.cs` | The bridge source. Shipped as **source**; no prebuilt binary is distributed. |
| `src/main/windows/globalInvoke.ts` | Invoke no longer raises Papers; typed overlay outcomes. |
| `src/main/index.ts` | Wiring, Escape handling, resource resolution, release on quit. |
| `electron-builder.yml` | `resources/native -> native`, alongside the existing window-helper mapping. |

---

## 3. Focus: the hard half, and what running it actually showed

**The measurement that shaped the design.** Papers' own shipping window helper reports
`restore` **success** while the foreground does not move (`probes/probe-25`). A background process
calling `SetForegroundWindow` is refused by the Windows foreground lock. That is a *false
success* — this project's recurring bug — and it means the existing helper cannot do this job.

**The strategy sweep** (`probes/probe-26`) tried `SetForegroundWindow` alone, `BringWindowToTop` +
`SetForegroundWindow`, `AttachThreadInput` in two variants, and an ALT-tap unlock. On a machine in
active use none of the workarounds showed a reliable improvement, and the foreground kept being
taken by the creator's own applications mid-run. So the design uses the plain, honest sequence and
records refusals as refusals.

**The sequence implemented:**

```
1. read the foreground window      <- BEFORE the overlay exists; after that it is unrecoverable
2. show + focus the overlay        <- makes Papers the foreground owner, which grants the right
3. on close, SetForegroundWindow(that handle)
```

**The native bridge.** C# compiled on first use by the `csc.exe` that ships with Windows, cached
in the Papers Data directory, rebuilt whenever its source changes. No new dependency, no
node-gyp, no packaged-layout change beyond one resource directory. It exits **non-zero unless
`GetForegroundWindow()` really became the target**, so a caller cannot read a refusal as success —
which is the exact defect the PowerShell path had.

If the compiler is missing or compilation fails, the bridge is absent, and the overlay **says it
could not hand focus back** rather than pretending.

**When focus is returned — and when it deliberately is not:**

| Close reason | Focus |
| --- | --- |
| Escape | handed back |
| Chord pressed again | handed back |
| An action is run | handed back — so running an item does not require Papers to come forward |
| The overlay merely loses focus | **not** handed back: the creator moved on by themselves, and stealing focus back would be worse |

---

## 4. Two defects found in my own work by running it

Both are the same shape as the bug the brief warned about: **a silent failure at the boundary.**

1. **The first bridge source did not compile.** `IntPtr.TryParse` does not exist in .NET Framework
   4.0, which is what `csc.exe` is. My tests passed anyway — because they only asserted *"the
   .exe exists"*. A facade at exactly the boundary that mattered. Fixed to `long.TryParse` + cast,
   and the tests now exercise the bridge's behaviour rather than its file's existence.
2. **The compile ran with `stdio: 'ignore'`**, so that genuine compiler error was invisible behind
   a silent `null`. `stderr` is now captured and surfaced through
   `foregroundBridgeUnavailableReason()`, and a failed compile deletes any stale binary rather
   than leaving an old one to answer for new source.

---

## 5. Verification

### 5.1 Live, by running

```
bridge compiled from shipped source  -> get: handle=2294266 shell=0
                                        class=742DEA58-ED6B-4402-BC11-20DFC6D08040
                                        title=CLIP STUDIO PAINT
                                        iswindow(0)=0  iswindow(1)=0
a real Papers instance at startup    -> papers-fg-bridge.exe present (6144 bytes) + stamp
                                        the binary Papers itself produced reads the live foreground
overlay window properties read back  -> isResizable=false   isAlwaysOnTop=true
                                        isMinimizable=false isMaximizable=false
                                        isFullScreenable=false
                                        bounds {x:640,y:238,w:640,h:220} inside the cursor display
```

That last row caught a real gap: Electron's default leaves a frameless window **fullscreenable**,
so a stray F11 could have turned the launcher into a full-screen surface. `fullscreenable: false`
was added because the measurement showed it was needed.

### 5.2 Monitors

**Chosen: the display with the cursor.** The pointer is the best cross-process signal for "the
screen they are working on", and it needs no native call to read. `probes/` shows a real work-area
read and the resulting centred, upper-third placement. Not verified: behaviour with the cursor on
a display the foreground application is *not* on, which needs a human.

### 5.3 What refused, and what it looked like

| Refusal | What it looks like |
| --- | --- |
| No project open | `overlay-unavailable`, "no project is open in Papers, so there is no command surface to show". **Papers is still not raised** — asserted by test. |
| Focused project has no surface | "the focused project has no surface to show the command surface in" |
| Entry URL is not the bound project | "overlay entry is not the bound project surface"; no window is created |
| Surface fails to load | "the command surface could not be loaded: …"; the window is destroyed, not left invisible |
| The overlay throws | "the command surface overlay failed to open: …" |
| Windows refuses the focus hand-back | `focus-not-restored`, "Windows refused the focus hand-back, so the previous application may not be in front" |
| The application in front has closed | `focus-not-restored`, "…has closed, so focus was not handed back to it" |
| No native bridge | `focus-unknown`, "the native foreground bridge is unavailable, so the previous application cannot be given focus back automatically" |

Every one of these reaches the creator through the existing `host:event:host-error` panel. None
of them is a silent no-op.

---

## 6. What I could not verify, and it is the important one

**Focus hand-back across real foreground applications — needs the creator at the machine.** This
machine is in active use; the foreground changed under the probes repeatedly (Obsidian took it
mid-run), and a background process cannot take focus at all. The one thing that must be measured
is the one thing that cannot be measured here. **The test is the creator pressing Alt+A while in
another application, typing, and closing the launcher.**

Also unverified: a window on another virtual desktop, and a fullscreen application in front.
Electron exposes no API to move a window between virtual desktops.

---

## 7. The Lane 3 contract change — what to steer

The half Lane 3 was building is **now wrong in two places**. This is the whole change:

**WITHDRAWN.** The instruction "listen for `papers:project:global-invoke` on `window` and treat
it as open the command surface". That event is no longer sent, and opening the surface at the
project's existing location is no longer what Alt+A does.

**REPLACED BY.** The project is asked to render its command surface **into a host window it has
not seen before** — a small transient overlay — *on top of the application the creator is
already in*, without that application losing its place.

Precisely, three things:

1. **A mode marker arrives in the page URL.** The overlay loads the project's own entry URL with
   `?papers-surface=command-surface`. That is the same shape as the existing compact widget
   (`?papers-surface=compact-widget&papers-layout-key=…`), so the project already has the pattern:
   read the marker, render the eligible surface, and render nothing else. **In this mode the page
   must render ONLY the command surface** — no workspace chrome, no navigation, nothing that
   assumes a full window. The overlay is 640×220 and non-resizable.
2. **One event still arrives**, relayed to `window` as
   `{ type: 'papers:project:command-surface-invoke', projectId, surfaceId, chord: 'invoke',
   reason: 'global-accelerator' }`, after the page has loaded. Treat it as "focus the command
   input and select-all/clear it", not as "open the surface" — the surface is already open by
   virtue of the marker.
3. **Dismissal.** The host handles **Escape itself** at the window level, so Lane 3 does not need
   to. If the project wants to close the overlay itself (for example on a deliberate cancel
   affordance), it should send its existing close request and say so, and the host will add the
   channel; **do not build a new channel for this without telling me.** Running an item should
   simply let the host close the overlay — the project should not try to raise Papers.

**What is unchanged and still true:** the host still does not know what a command surface is; the
project still decides everything about it; and the project still owns the action definitions. The
only change is *where* the surface is rendered and *that Papers must not come forward*.

**One caveat still open from round four**, unchanged: the event carries `projectId`, `surfaceId`
and `chord`, but **not** the receiving surface's identity, because the preload that relays it does
not know its own `surfaceId`. In command-surface mode that is harmless — the overlay is a single
purpose-built window. It would matter only if the project needed to distinguish several overlays,
which it does not.

---

## 8. Safety

- The creator's Papers was **never restarted and never disturbed**; their 7 processes ran
  throughout the work.
- Every live test used an isolated `PAPERS_TEST_USER_DATA` directory; all were removed.
- The one Notepad process the focus probes started was identified by provenance (started 09:24:18
  during `probe-26`, holding the accumulated windows of the single-instance host) and stopped.
  Verified 0 notepad processes and 0 probe Electron processes afterwards.
- No application window was moved, hidden, re-ordered or closed by this work.
- Nothing was pushed.
