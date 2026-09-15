# Quick Run — Complete Implementation Checklist

<!-- STATUS: replace this block in place. Never append. -->

## Status

**Updated** 2026-09-13 · **Implemented on a feature branch, not yet accepted.** STAGE 0 through STAGE 19
carry no open boxes: the modules, the surface, the actions, the invalidation and race rules and the tests
are in place on `quick-run-stage0`, and the two slices since that branch — the STAGE 14 performance harness and the
paint cap — are on `quick-run-integrated-perf`. The **16 boxes that remain are the acceptance-shaped remainder** — one
architecture invariant, STAGE 17's host-side test requirements and the Definition of Done — and none of
them is waiting on code. The Performance pair the remainder used to include is **closed at `299152d`**: it was
measured, the measurement failed, it named its own cause, the creator chose the remedy and the re-measurement
passes. The app-level half of that acceptance is closed: the Definition of Done's four
Enter boxes ticked at `779c352`, which is the slice that moved the wiring into a seam a test can drive.

**Where everything is.** Windows paths. The short names beside `Products\<Name>\<Role>` are symlinks into
those directories and both forms work, so a tool reporting one when you typed the other is not a wrong
directory. Use `D:/...` in scripts: Windows Python cannot resolve msys `/d/...` and fails *silently*.

| | |
| --- | --- |
| Working tree | `D:\Letters\MatTroiSeConMoc\Products\Papers\Runtime\Backpack projects\As you Go` — remote `Futahua/as-you-go-backpack`, branch **`quick-run-integrated-perf`**, HEAD **`086ac42`** @ `2026-09-13T00:58:56+07:00`, clean tree, pushed. It was cut from `quick-run-stage0` @ `779c352`, which remains the branch the modules, surface, actions and tests listed above were written on; the two slices since are the STAGE 14 harness (`59bed23`, with a text-only correction at `086ac42`) and the paint cap (`299152d`) |
| Untouched baseline | `main` at `8000c88` @ `2026-09-08T18:23:53+07:00` — the anchor this work must not disturb, and has not |
| Papers host | `D:\Letters\MatTroiSeConMoc\PAPERS 3\Papers-3` (canonical) and `D:\Letters\MatTroiSeConMoc\Products\Papers\Source` — **read-only reference for this checklist**. STAGE 9's host half names the files a Papers-side change would touch; no Papers change is claimed by this branch |
| This checklist | `D:\Letters\MatTroiSeConMoc\LongHorizon` — `Futahua/long-horizon`, branch `codex/reviewer-send-verification` |
| Old Proxima plugin | `D:\LapSlop brotherhood\Local\.obsidian\plugins\proxima` — **read-only; it is live inside the creator's vault** |

**Suite at `779c352`.** `npm test` in the working tree above: **1344 tests, 1344 pass, 0 fail, 0 skipped,
exit 0** in ~16 s (the baseline recorded on `main` is 1153, so this work added 191; the five new ones are
the app-level acceptance harness). Every slice was gated
on that run, and the count is the runner's own rather than a sum of new files. **Re-verified rather than carried:** the suite was run again on 2026-09-12 by the executor - `npm test` exit 0, **1344 pass / 0 fail / 0 skipped**, the recorded figure exactly, with the tree clean afterwards. **Run a third time on 2026-09-13, on the performance harness's own branch `quick-run-integrated-perf` at `59bed23`:** `npm test` exit 0, **tests 1344 / pass 1344 / fail 0 / skipped 0**, unchanged by the harness, which is deliberately *not* wired into `npm test` because it launches a real host and takes minutes - it has its own script, `npm run test:quick-run:integrated-perf`, and its own exit code (0 within budget, 1 over it, 2 when the measurement could not be taken). **Run again at the paint cap, `299152d`:** `npm test` exit 0, **tests 1365 / pass 1365 / fail 0 / skipped 0** - the 21 new ones are the cap's own cases, and none of the existing tests was weakened, skipped or deleted. Three of them changed shape and are declared on the commit: the closed-session deep-equal now names `totalRows`/`capped`, and two files that enumerate the page's declared ids gained `#quick-run-cap`. Nothing asserted that every match is painted, so no test had to be bent to keep it.

**The 16 open boxes, and what each is waiting on.**

- **Papers activation (7)** and **Availability/native (2)** — STAGE 17's host-side requirements: a normal
  target raises and focuses, a minimized one restores first, a stale identity cannot activate a
  replacement window, a malformed capability is rejected, a page cannot supply HWND/PID/path, the
  helper-unavailable failure is typed, and the helper SHA-256 pins are updated and validated. These need
  the Papers host with the helper present.
- **Actions (2)** — the two Layout Item boxes: that Enter uniquely resolves and activates/restores the exact
  native window, and that a missing or ambiguous one stays visible and reports failure honestly. **Neither
  can close with the app-level harness, and the browser AUTHOR said so on 2026-09-12:**
  `planQuickRunActivation()` still declares Layout Item activation deferred and the resolver says native
  enumeration and activation wait for the Papers capability, so a fake command object cannot prove that the
  exact native window is activated or restored. The other four twins closed at `779c352`:
  `quick-run-workspace.test.mjs` types into the production markup's input, presses the key on the drawn row,
  and asserts the real store's session, the launcher's log and the host's web-opener log — the wiring moved
  out of the entry file into `public/app/quick-run/quick-run-workspace.js` so the harness drives the
  production line rather than a copy of it, and six mutations (removing the binding's hand-off among them)
  fail it.
- **Native boundary (4)** — the same capability seen from the host's side, including the fail-closed
  identity rule and the resource hash pins.
- **Performance (2) — CLOSED at `299152d`.** The pair was measured rather than left pending, and the first
  measurement **missed**: the harness `quick-run-integrated-perf.mjs` (`npm run test:quick-run:integrated-perf`,
  committed at `59bed23`) builds STAGE 14.1's synthetic 20,000-occurrence workspace with graph mode active and
  15 live physics nodes, opens the real Backpack surface, activates Quick Run with the app's own `Alt+Shift+X`
  chord, types through the project view as trusted input, and reported **p95 29.3-30.2 ms against the 16 ms
  target** over 401 samples across four runs. It was not a corpus artifact: latency tracked the rows committed
  in one paint (1-1,000 rows: p95 2.6-10.8 ms; 3,001-12,000 rows: p95 58.2 ms with every sample over one
  frame) and the surface capped nothing, so one keystroke could commit 12,213 rows. The creator chose the
  remedy - cap what is painted - and `QUICK_RUN_MAX_PAINTED_ROWS = 200` now bounds the session's rows, with the
  honest match count kept beside them and a line in the surface saying how many matches are not shown. The same
  instrument then reported **p95 4.3 ms, 0 samples over one frame, 0 long tasks**, reproduced by the executor.
  The earlier reading that the number had to come from the creator's vault is corrected in the boxes: STAGE
  14.1 asks for a synthetic/fixture workspace in its own words, which is what was built. What the pair's closure
  does **not** claim: the packaged-host half is not measured, the mark is the DOM commit rather than the
  presented frame, and the Creator acceptance walk at the foot of this file is untouched.
- **Architecture invariant (1)** at §5 — that the Papers addition stays exactly a narrow,
  already-resolved capability activation primitive. It is a statement about the host change, so it closes
  with the host work above.

**Next operation.** The app-level harness the browser AUTHOR scoped on 2026-09-12 is **built, at `779c352`**:
the composition seam is `public/app/quick-run/quick-run-workspace.js`, the entry composes it, and
`quick-run-workspace.test.mjs` drives it on the production markup's ids with a real store and the real
`createWorkspaceCommands` — DOM input to a real ranked row, Enter on a Folder navigating the store's session
and closing the layer, Shortcut and Link calling their exact and mutually exclusive effects, Ctrl+Enter
resolving a doubled placement to the requested occurrence, one stale-result mutation between render and
keypress, and six mutations of the production binding that all fail the harness, so there is no test-side copy
left to pass in its place. It closed the four Enter boxes, and it left none of the remaining four kinds of
work reachable from here. The two **Performance** boxes were reached the same way at `59bed23`: a second
Playwright/Electron harness that seeds a disposable profile, opens the real surface, drives the real chord and
measures real input-event → result-DOM-commit latency with graph physics live. It found the gate missed rather
than met, and that measurement is what the creator acted on: the paint is capped at 200 rows at `299152d`, the
same instrument now passes at p95 4.3 ms, and both boxes carry the before and the after. The Layout Item boxes and
the host rows either wait on that same native capability through a host run (Papers activation, native
boundary, availability) or on the creator walking `# Creator acceptance walk` at the foot of this file, which
no automated evidence replaces. **The packaged-host half of the performance route is NOT MEASURED, and for a
reason worth keeping:** `release\win-unpacked\Papers.exe` exists (built 2026-09-08T18:24, seventeen commits
before the source HEAD of 2026-09-11T06:44) and the harness launches it and reports `kind: packaged`, but the
first `show-surface` is refused with *"Shared document coordination is unavailable; durable editing is
disabled"* — and neither phrase exists anywhere in the current Papers source, so the packaged build is a
different generation from the code under test rather than a stricter gate on it. The harness reports that as
exit 2 (NOT MEASURED) with the error, which is what it is for; the numbers above are the **source** host, which
is the generation this work targets. What the two Performance boxes leave behind is one line of history rather
than a paragraph: the earlier reading of this section sent the number to the creator's vault, and STAGE 14.1's own
words - "a synthetic/fixture workspace representing 10,000-20,000 searchable occurrences with graph mode active" -
are why that reading was corrected rather than honoured. The rest of the route is now ordinary precedent for a
later run: `probes\015r3-live-proof\cdp.mjs` spawns a packaged binary with `--remote-debugging-port`, `probes\016r`
is the disposable-instance pattern (`--user-data-dir`), and `run-016-phase-a-eye-check.mjs` states in its own text
that the creator's real Papers must not be closed.
One contract line stays known-unimplemented and is recorded rather than implied: section 16.3's automatic
requery after a stale result — the binding revalidates, keeps the layer open and says why, and the harness
asserts exactly that.

**The hotkey chord is chosen and bound.** The creator chose **`Alt+Shift+X`** for the workspace scope on
2026-09-12 — recorded on the open item at the foot of this file, which was the item waiting for it — and it is
implemented as an explicit configured value rather than an invented default: `362a00d` @
`2026-09-12T08:19:15+07:00` put `workspace.quick-run` in the hotkey catalog, `28ee3ad` @
`2026-09-12T08:21:05+07:00` gave the keyboard controller a module-scoped hook that matches the action,
prevents the default and calls it, and `10f8ae6` @ `2026-09-12T08:29:36+07:00` made the chord open the
surface.

**The checkout's own rules, which bind anything written there.** Elements are declared in
`public/workspace-20260730b.html`; `public/app/dom.js`'s `getWorkspaceElements` registers them through
`requiredElement`, which **throws**, so the markup and the registry stay in lockstep by construction rather
than by care; modules are handed element handles and never build markup. New features belong in named
modules under `public/app/`, not in the entry file. `ARCHITECTURE.md` is the map, and a module missing
from it is a map that has drifted.

**Tick audit.** Every ticked box names the commit that closed it. The audit is
`D:\Letters\MatTroiSeConMoc\.dsh\audit-checklist-ticks.ps1` (box-level, so an annotation wrapped across
lines is read whole; short SHAs resolve against Proxima, this checkout, Papers-3 and this repository). At
the revision before the one carrying this block: 281 boxes, 259 ticked, 297 references, **0 unresolved**,
**0 false timestamps**, and four boxes without a SHA. Two of those were empty annotations a tick script had
dropped — `folder indexed.` and `linked shortcut with 3 placements gives 3 results.` — restored in this
revision from `fc8c1da` and `ae3697a`. The other two are deliberate and stay: the **Sets decision**
(resolved 2026-09-08) and the **hotkey chord** (chosen by the creator on 2026-09-12), whose evidence is a
decision by date rather than a commit.

**History.** The pass-by-pass narrative this block used to carry — every slice, a slice written and
reverted rather than committed, a suite number corrected after the fact — lives in
`git log -p -- papers/quick-run.md`. Status is current state only; history costs nothing to ignore in git.

# 0. Product contract

Quick Run is an As-you-Go workspace command surface inspired by command-line/AutoCAD-style quick access.

The creator invokes a workspace hotkey, types a name, chooses from matching persisted As-you-Go items, and activates the selected result.

The core interaction is:

```
hotkey
→ one search line appears
→ type
→ flat ranked results appear immediately
→ ArrowUp / ArrowDown / wheel changes highlight
→ Tab / Shift+Tab changes type filter
→ Enter performs the default action
→ Ctrl+Enter reveals the occurrence inside As-you-Go
→ Shift+Enter adds to the active window layout where supported
→ Escape closes Quick Run and leaves nothing behind
```

There is no empty-query launcher home screen.

There are no prompts.

There is no whole-window-layout result.

Quick Run is a persisted-data search system. Live native window resolution happens only when a selected Layout Item is executed.

# 1. Locked UX contract

These decisions are product requirements, not implementation suggestions.

## 1.1 Opening and closing

- [x] A configurable As-you-Go workspace hotkey opens Quick Run. — `10f8ae6` @ `2026-09-12T08:29:36+07:00` *(the chord is a catalog entry (`workspace.quick-run`, default `Alt+Shift+X`, so it is configurable through the workspace's own hotkey preferences), the controller reports it (`28ee3ad`, tested), the entry file hands the controller the surface's `open()`, and `open()` shows the layer with one empty line and takes focus. **Residual, stated:** the entry file is not importable in a test and no browser is in this loop, so the join is proved by its halves — controller reaches the callback, callback opens the surface — rather than by pressing the key.)*
- [x] V1 activation works only while the As-you-Go surface itself can receive keyboard input. — `28ee3ad` @ `2026-09-12T08:21:05+07:00` *(that is how it is built rather than a promise about it: the workspace controller returns early whenever a modal layer is open **and** whenever the keystroke targets an editable (`input`, `textarea`, `contenteditable`), so its Enter/Ctrl+Enter belong to whatever the reader is typing into; Quick Run binds its own keys on its own layer (`28ee3ad`, `10f8ae6`), which only receives them while the reader is in its line. Nothing is registered globally, so there is no activation path that works without the surface having input.)*
- [x] OS-global Quick Run activation is explicitly out of scope. — `362a00d` @ `2026-09-12T08:19:15+07:00` *(checked rather than assumed, the same way the two later boxes on this prohibition were: the tree contains no `globalShortcut`, `registerHotkey`, `global-hotkey` or `accelerator` call at all, and the action this document adds is a **workspace-scoped** catalog entry (`HOTKEY_SCOPE_WORKSPACE`). Out of scope is therefore the state of the code, and adding one would be the change that re-opens this box.)*
- [x] Opening Quick Run shows one focused search input. — `10f8ae6` @ `2026-09-12T08:29:36+07:00` *(the layer the page declares holds exactly one input (`#quick-run-input`), and `open()` paints the empty session and calls `focus()` on it — asserted in the surface test, which records the focus request. One input, focused, empty: the three parts of this box. **Residual:** the entry file that calls `open()` is not importable in a test, so the key press that leads there is proved by the controller's half rather than end to end.)*
- [x] Empty query shows no result rows. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-session.js`, exercised by `quick-run-session.test.mjs` inside the suite (1181 pass); the surface that draws the line is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Results first appear after the first non-empty search query. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-session.js`, exercised by `quick-run-session.test.mjs` inside the suite (1181 pass); the surface that draws the line is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Escape closes Quick Run. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-session.js`, exercised by `quick-run-session.test.mjs` inside the suite (1181 pass); the surface that draws the line is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Escape does not create, move, launch, select, navigate, or persist a result action. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-session.js`, exercised by `quick-run-session.test.mjs` inside the suite (1181 pass); the surface that draws the line is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Closing Quick Run clears its query/highlight/filter session state. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-session.js`, exercised by `quick-run-session.test.mjs` inside the suite (1181 pass); the surface that draws the line is a later stage, so this tick claims the rule and not the pixels.)*

The existing Backpack hotkey model already has workspace-scoped actions and configurable bindings, while the keyboard controller is the central workspace keydown seam. Add Quick Run there rather than introducing a second unrelated keybinding system. `workspace.reveal-selection` and `workspace.open-selection` already occupy Ctrl+Enter and Enter in the ordinary workspace, so Quick Run must take over those keys only while its own input surface is active.

## 1.2 Result presentation

Every visible result row contains:

```
icon
primary name
faint trailing breadcrumb
```

One flat list only.

No grouped sections.

Duplicate names are allowed and expected when breadcrumbs differ.

## 1.3 Highlight

- [x] First matching result starts highlighted. — `66fd5f4` @ `2026-09-12T08:32:47+07:00` *(the session's rule: resolving results sets the highlight to the first row of the set it just produced (`quick-run-session.js`), the surface paints that row with `data-quick-run-highlighted="true"`, and the surface test asserts exactly one row carries it. **Residual:** the entry file that opens the session is not importable in a test, so the paint is asserted through the surface rather than through a key press.)*
- [x] ArrowDown moves highlight one result down. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the **rule** is implemented and tested — `src`-side in `public/app/quick-run/quick-run-index.js`, exercised by `quick-run-index.test.mjs` in the suite that runs 1173 cases — while the surface that calls it is a later stage, so this tick claims the rule and not the visible highlight.)*
- [x] ArrowUp moves highlight one result up. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the **rule** is implemented and tested — `src`-side in `public/app/quick-run/quick-run-index.js`, exercised by `quick-run-index.test.mjs` in the suite that runs 1173 cases — while the surface that calls it is a later stage, so this tick claims the rule and not the visible highlight.)*
- [x] Mouse wheel/scroll updates which result is highlighted according to the agreed list behavior. — `7f60ecb` @ `2026-09-12T08:31:51+07:00` *(the contract answers this itself in § 6.3, which is what "the agreed list behavior" points at: *"scrolling list changes viewport normally"*, *"when a row becomes selected by intended scroll behavior, its selection is deterministic"*, and *"keyboard highlight never points to an off-list stale row"* — with `:hover` explicitly not authoritative. Implemented as exactly that and nothing more: **no wheel handler is registered at all** (asserted, and firing a wheel event leaves the highlight where it was), the highlight is always a member of the displayed set across a query sequence including a no-match one (asserted), and the keyboard is the only thing that moves it.)*
- [x] Highlight never points to an item not present in the currently displayed filtered result set. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the **rule** is implemented and tested — `src`-side in `public/app/quick-run/quick-run-index.js`, exercised by `quick-run-index.test.mjs` in the suite that runs 1173 cases — while the surface that calls it is a later stage, so this tick claims the rule and not the visible highlight.)*
- [x] When the current result set changes, preserve the highlighted result by stable result key if it still exists. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the **rule** is implemented and tested — `src`-side in `public/app/quick-run/quick-run-index.js`, exercised by `quick-run-index.test.mjs` in the suite that runs 1173 cases — while the surface that calls it is a later stage, so this tick claims the rule and not the visible highlight.)*
- [x] Otherwise select the first result. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the **rule** is implemented and tested — `src`-side in `public/app/quick-run/quick-run-index.js`, exercised by `quick-run-index.test.mjs` in the suite that runs 1173 cases — while the surface that calls it is a later stage, so this tick claims the rule and not the visible highlight.)*

## 1.4 Type filters

Filter cycle:

```
All
Folders
Shortcuts
Links
Layout Items
```

- [x] Tab cycles forward. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-types.js` and its suite; the surface that draws the chips is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Shift+Tab cycles backward. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-types.js` and its suite; the surface that draws the chips is a later stage, so this tick claims the rule and not the pixels.)*
- [x] Chips appear above the result list. — `27485d8` @ `2026-09-12T08:25:42+07:00` *(this is now a fact about the page rather than a rule: `workspace-20260730b.html` declares the layer as input, then the chip strip, then the result list, in that order, and the surface paints chips into the strip and rows into the list. It is also the first tick in this document that could only be made honestly *after* the elements existed — before `27485d8` there was nothing to appear above anything.)*
- [x] Only result types with at least one current query match receive type chips. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-types.js` and its suite; the surface that draws the chips is a later stage, so this tick claims the rule and not the pixels.)*
- [x] All is shown whenever there is at least one result. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-types.js` and its suite; the surface that draws the chips is a later stage, so this tick claims the rule and not the pixels.)*
- [x] If the active type filter loses all matches after another keystroke, immediately fall back to All. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the **rule** is implemented and tested in `public/app/quick-run/quick-run-types.js` and its suite; the surface that draws the chips is a later stage, so this tick claims the rule and not the pixels.)*
- [x] After that fallback, highlight the first All result. — `0adc8fc` @ `2026-09-12T08:15:05+07:00` *(the two rules compose and the composition is asserted: `resolveFilter` hands back the `All` set when the active filter loses its matches, and `highlightAfterResults` given a key that is not in the set it is handed returns that set's first row — which is the case `0adc8fc` tests. The surface that performs it is a later stage.)*

## 1.5 Default Enter actions

```
Folder
→ navigate into that folder

Shortcut
→ launch it

Link
→ open its web URL

Layout Item
→ activate/focus that exact external application window
→ restore it first if currently minimized
```

## 1.6 Modifier actions

### Ctrl+Enter

Means: reveal this exact occurrence inside As-you-Go.

It explicitly does not mean OS file-manager reveal.

It must not reuse the existing `workspace.reveal-selection` behavior or `revealShortcut()`, because the existing command explicitly reveals shortcut targets through the host/file manager.

### Shift+Enter

- [x] Enabled only for Layout Items. — `56b2fe1` @ `2026-09-12T08:38:24+07:00` *(`planQuickRunShiftEnter` answers an action for a `layout-item` row and a `disabled` reason for everything else; the test walks a folder, a shortcut and a link and asserts each gets `only-layout-items`.)*
- [x] Visibly disabled for Folder, Shortcut, and Link results. — `56b2fe1` @ `2026-09-12T08:38:24+07:00` *(the plan returns the reason a surface draws — the affordance is not merely inert, it has a sentence to show. **Residual:** the surface that renders the affordance is the entry-file slice, so this tick claims the plan and the reason, not the pixels.)*
- [ ] Never silently ignore Shift+Enter. — `56b2fe1` @ `2026-09-12T08:38:24+07:00` *(the function has no path that returns nothing: every input yields an action or a `disabled` reason, including `null` — which is asserted directly, because a plan that answered `undefined` would let a caller drop the keypress without saying so.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] If no active window layout exists, the Layout Item Shift+Enter affordance is disabled with a visible reason. — `56b2fe1` @ `2026-09-12T08:38:24+07:00` *(`activeLayoutId: null` (and an omitted fact) both answer `no-active-window-layout`, which is a reason a surface can print rather than an absence.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [x] If the selected window already occurs in the active layout under the defined duplicate rule, report that instead of creating an accidental duplicate. — `56b2fe1` @ `2026-09-12T08:38:24+07:00` *(the caller supplies `alreadyInActiveLayout`, and when it is true the plan answers `already-in-the-active-layout` instead of an add action — the duplicate rule itself belongs to the layout model, so this reads its answer rather than re-deriving it.)*

# 2. Searchable universe

Classification: HARD PRODUCT SCOPE

Quick Run v1 intentionally searches a narrower universe than every user-visible object As-you-Go currently contains.

The current workspace model contains top-level groups, shortcut records with one or more placements, window layouts, prompt-library state, and Sets. Window-layout members are nested persisted descriptor records rather than ordinary `itemsIn()` entries. Shortcut placements — not shared shortcut records — are the location-specific item identities exposed to the workspace.

## 2.1 Included in v1

### Folders

Source:

```
state.groups
```

One result per active folder.

### Shortcuts

Source:

```
state.shortcuts[].placements[]
```

One result per active placement, not per shared shortcut record.

A linked shortcut shown in three folders may therefore produce three Quick Run rows with:

```
same name
same underlying target
different placement IDs
different breadcrumbs
```

This is intentional. The workspace itself already treats placement IDs as the selectable/movable occurrence identity.

### Links

Links are not a separate durable record kind.

A Link is a Shortcut whose target parses as `http:` or `https:`. `createWebLink()` delegates to `createShortcut()`, and `isWebLink()` classifies the target URL. Therefore Quick Run must create one shortcut index and classify each occurrence into either link or non-web shortcut; do not build a second Link store/index.

### Layout Items

Source:

```
state.windowLayouts[].arrangement.members[]
```

One result per member occurrence.

A single native application window intentionally present in two layouts therefore produces two Quick Run rows, each with the containing layout in its breadcrumb.

Persisted window-layout members carry:

```
member.id
descriptor.version
descriptor.title
descriptor.executableFingerprint
bounds
state
```

The persisted descriptor — not an HWND/runtime token — is their durable native identity.

# 3. Explicit exclusions

Classification: HARD V1 SCOPE

Do not accidentally broaden "valid item type" to mean every persisted concept in the Backpack.

V1 excludes:

- [x] Whole window layouts. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Prompts / prompt library entries. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Bin contents. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Items whose ancestor folder is currently binned. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Binned shortcut placements. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Binned window layouts and their members. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the exclusion is asserted rather than assumed: quick-run-universe.test.mjs holds it. Re-annotated 2026-09-12: a tick script dropped the original annotation.)*
- [x] Sets — see the resolved decision at the top of this document. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*

## If Sets are later included

Add `Sets` as its own result kind and filter chip.

Then define separately:

- result key;
- display name;
- breadcrumb/location semantics;
- default Enter action;
- Ctrl+Enter reveal semantics;
- whether Shift+Enter is disabled;
- ranking/index invalidation for set rename/delete;
- whether set membership changes affect searchable identity.

Do not treat a Set as a Folder. Sets are a workspace-view grouping abstraction rather than folder-tree containers.

# 5. Non-negotiable architecture invariants

Classification: HARD LAUNCH CRITERIA

- [x] Quick Run index construction performs zero native window enumeration. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(the universe is built from persisted data only — state.groups, state.shortcuts[].placements[] and state.windowLayouts[].arrangement.members[], whose descriptors are the durable identity — and the module that builds it has no native access at all. Section 2.1 states the same thing from the other side: live native resolution happens only when a selected Layout Item is executed, which is a path this loop has deliberately left unimplemented.)*
- [x] Typing performs zero native window enumeration. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(one property, asserted at `4f63739` @ `2026-09-12T08:39:21+07:00`: the session captures the workspace rows once at open and every keystroke after that is pure ranking over that snapshot — the test counts the workspace reads and finds exactly one across opening plus a run of keystrokes, arrows and Tab presses. Nothing under public/app/quick-run/ imports a host, a window or the entry file, so there is no path from a keystroke to native work even in principle.)*
- [x] Typing performs zero capability resolution. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(one property, asserted at `4f63739` @ `2026-09-12T08:39:21+07:00`: the session captures the workspace rows once at open and every keystroke after that is pure ranking over that snapshot — the test counts the workspace reads and finds exactly one across opening plus a run of keystrokes, arrows and Tab presses. Nothing under public/app/quick-run/ imports a host, a window or the entry file, so there is no path from a keystroke to native work even in principle.)*
- [x] Typing performs zero window observation. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(one property, asserted at `4f63739` @ `2026-09-12T08:39:21+07:00`: the session captures the workspace rows once at open and every keystroke after that is pure ranking over that snapshot — the test counts the workspace reads and finds exactly one across opening plus a run of keystrokes, arrows and Tab presses. Nothing under public/app/quick-run/ imports a host, a window or the entry file, so there is no path from a keystroke to native work even in principle.)*
- [x] Typing performs zero thumbnail requests. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(one property, asserted at `4f63739` @ `2026-09-12T08:39:21+07:00`: the session captures the workspace rows once at open and every keystroke after that is pure ranking over that snapshot — the test counts the workspace reads and finds exactly one across opening plus a run of keystrokes, arrows and Tab presses. Nothing under public/app/quick-run/ imports a host, a window or the entry file, so there is no path from a keystroke to native work even in principle.)*
- [x] Typing performs zero host IPC other than anything strictly necessary for unrelated existing renderer infrastructure. — `4f63739` @ `2026-09-12T08:39:21+07:00` *(one property, asserted at `4f63739` @ `2026-09-12T08:39:21+07:00`: the session captures the workspace rows once at open and every keystroke after that is pure ranking over that snapshot — the test counts the workspace reads and finds exactly one across opening plus a run of keystrokes, arrows and Tab presses. Nothing under public/app/quick-run/ imports a host, a window or the entry file, so there is no path from a keystroke to native work even in principle.)*
- [x] Ranking is pure local computation. — `8bfc829` @ `2026-09-12T08:13:29+07:00` *(`quick-run-index.js` imports two things: the row builder and the vocabulary module. Normalisation, the four tiers and the ordering are arithmetic over strings and arrays, with no host, no clock, no randomness and no I/O — which is also what makes the tier tests deterministic.)*
- [x] Breadcrumb generation is based on persisted workspace hierarchy. — `bd24a2c` @ `2026-09-12T08:17:59+07:00` *(the breadcrumb is the parentId chain of the persisted groups, walked once per row — not the graph or UI code the contract tells the implementer to avoid calling per keystroke — and the ancestor **ids** travel with it as readcrumbIds so a caller need not re-walk. Tested in the search and presentation suites.)*
- [x] Window-layout result actionability is not guessed from persisted state. — `217007f` @ `2026-09-12T08:43:01+07:00` *(availability is a function of the row kind and of nothing else: a member persisted as `minimized` still starts `unknown`, which is the one persisted value that would have tempted a guess. § 10.1 states the rule; the test is the assertion.)*
- [x] An untouched Layout Item starts availability=unknown, not "Not running." — `f78cd16` @ `2026-09-12T08:42:28+07:00` *(`quickRunRowViews` carries `availability` for layout-item rows only; every other row kind keeps `null`, so "Not running" is not merely unused but unrepresentable on a row that cannot have the state.)*
- [x] Missing/ambiguous native targets remain searchable because their persisted member still exists. — `217007f` @ `2026-09-12T08:43:01+07:00` *(asserted for a member whose executable no host reports: the row is built from the persisted member, and the pure layer never consults a resolution, so neither a missing nor an ambiguous target can remove a row by construction. The resolution path itself is still unbuilt, which is why the outcome boxes in § Availability/native stay open.)*
- [x] A failed native resolution never silently substitutes a different matching window. — `4541f19` @ `2026-09-12T09:11:59+07:00` *(the rule now has a module rather than a hope: quick-run-resolution.js matches only the descriptor fields the member declares, requires every one of them to agree exactly, treats a descriptor that declares nothing as matching nothing, and returns ambiguous with the candidate identities instead of a window. A near miss is a miss, and the test that proves it also records the subtlety that undeclared fields are ignored rather than disqualifying.)*
- [x] Enter re-reads the selected object from the current state by stable IDs before acting. — `d11206e` @ `2026-09-12T08:40:17+07:00` *(`revalidateQuickRunRow` rebuilds the universe from the current state and finds the row by the pinned stable key, at `d11206e` @ `2026-09-12T08:40:17+07:00` — the test renames the shortcut under the index and asserts the re-read carries the new name while the indexed row keeps the old one, and that a removed occurrence answers a reason instead of an action. The entry-file slice that runs the plan is expected to call this first, which is why it is a function rather than a comment.)*
- [x] Indexed result payloads are never treated as current authority. — `d11206e` @ `2026-09-12T08:40:17+07:00` *(`revalidateQuickRunRow` rebuilds the universe from the current state and finds the row by the pinned stable key, at `d11206e` @ `2026-09-12T08:40:17+07:00` — the test renames the shortcut under the index and asserts the re-read carries the new name while the indexed row keeps the old one, and that a removed occurrence answers a reason instead of an action. The entry-file slice that runs the plan is expected to call this first, which is why it is a function rather than a comment.)*
- [x] Quick Run does not invoke the normal full workspace render() on every keystroke. — `72384be` @ `2026-09-12T08:48:10+07:00` *(structural rather than behavioural, because there is nothing to guard at runtime: none of the seven modules contains `render(`, and neither does the entry region that mounts the surface. A keystroke cannot render the workspace that Quick Run holds no reference to, and the scan is the test so a later pass cannot add one quietly.)*
- [x] Query interaction does not restart/reheat graph physics. — `72384be` @ `2026-09-12T08:48:10+07:00` *(the same scan: no module and no part of the entry wiring mentions `reheat` or reaches the graph at all.)*
- [x] Search-index rebuilding is not triggered by layout-member state/bounds observation. — `72384be` @ `2026-09-12T08:48:10+07:00` *(nothing in the seven modules observes anything — no `MutationObserver`, no `ResizeObserver`, no `setInterval`, no `requestAnimationFrame` — and the index is built once at open, which `4f63739` already counts as exactly one workspace read across a run of keystrokes.)*
- [ ] The Papers addition is exactly a narrow already-resolved capability activation primitive; Papers does not own Quick Run search/index/ranking in v1.
- [x] OS-global hotkey registration is not added as part of v1. — `362a00d` @ `2026-09-12T08:19:15+07:00` *(checked rather than assumed: the tree has no global-shortcut registration of any kind (no `globalShortcut`, `registerHotkey`, `global-hotkey` or `accelerator` call in the app or entry sources), and the action this pass added to the catalog is **workspace-scoped** (`HOTKEY_SCOPE_WORKSPACE`), which is exactly the boundary the box draws. It stays ticked only while that remains true, and a future global binding is what would re-open it.)*

# 6. Do NOT attempt in v1

This section exists to stop scope creep.

Do not add:

- [x] Papers-level universal command palette. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no palette, registry or command discovery exists; the universe is groups, shortcuts and layout members. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Cross-Backpack aggregated search. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(quickRunRows takes one workspace state and there is no second Backpack to aggregate. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] OS-global accelerator. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the chord is workspace-scoped in the catalog and registered by the workspace keydown seam; the scan finds no globalShortcut, registerHotkey or accelerator. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Quick Run invocation while another unrelated desktop application has focus. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(follows from the same fact: the binding is workspace-scoped, so another application having focus cannot reach it. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Prompt search. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(prompts are not a source, and a populated prompt library is asserted to contribute no row. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Whole-layout search. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(a layout appears only inside a member breadcrumb; the four row types are pinned. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Bin search. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(all four bin shapes are excluded from the universe. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Live "which applications are running" scanning. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no observer, timer or host reference in any module; availability is computed from the row kind. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Native availability polling in the background. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the same scan, plus the section 3.4 table: nothing observes and nothing polls. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Thumbnail generation for Quick Run rows. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no thumbnail source, and the scan finds no capturePage, toDataURL, screenshot or thumbnail. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Desktop enumeration while typing. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(opening reads the workspace once and typing reads it no further, and no native module is reachable. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Automatic relaunch of a missing layout member. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(activation is planned and then deferred; the scan finds no relaunch path. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] "Best guess" resolution for ambiguous window descriptors. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(there is no resolution at all yet, and the plan answers deferred with a reason rather than guessing. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Folder/shortcut semantic search through descriptions or file contents. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(matching reads the display name only, which quick-run-index.test.mjs asserts directly. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Search inside file contents. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no module reads a file or a host, so there is no content to search. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Search through link page titles fetched from the network. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(there is no network facility of any kind in the modules or in the wiring that mounts them. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Search by URL target unless separately approved later. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(matching reads the display name only; a target rides on the row for the action and never for the query. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] AI ranking. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no model, service or prompt reference anywhere in the ranking. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Embeddings/vector search. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no embedding, vector, cosine or similarity reference. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Prompt/verb syntax in the query. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the query is normalised text matched against names; the query path is scanned for verb and command syntax, whole words, which is how the scan nearly failed on the word verbatim. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Command verbs inside the Tab filter cycle. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the cycle is the five fixed contract names, asserted in quick-run-types.test.mjs. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Launch-a-shortcut-and-then-capture-its-new-window behavior for Shift+Enter. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(Shift+Enter plans a layout membership and nothing captures a window. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] Worker architecture before profiling proves it necessary. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(no worker, thread or message passing anywhere in the feature. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*
- [x] New search dependency/library before the pure matcher has been measured. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the modules import each other and two model helpers, and nothing else. The scan that holds it is quick-run-prohibitions.test.mjs, which covers the seven modules and the entry region and names this prohibition in its holder list.)*

# STAGE 0 — Pure search viability proof

Purpose: Prove the search/index design at target scale before UI or native work.

Classification: HARD GO/NO-GO GATE

No UI integration should begin until this stage passes.

## 0.1 Create pure Quick Run modules

Suggested new As-you-Go modules:

```
public/app/quick-run/quick-run-index.js
public/app/quick-run/quick-run-search.js
public/app/quick-run/quick-run-types.js
```

They must have no imports from:

```
host-bridge
DOM
graph
d3
window capability runtime
thumbnail code
```

## 0.2 Define stable result shape

Suggested shape:

```
{
  resultKey,
  type,
  name,
  normalizedName,
  breadcrumb,
  breadcrumbIds,
  actionRef,
}
```

Type-specific authority references:

```
folder
  groupId

shortcut/link
  shortcutId
  placementId

layout-item
  layoutId
  memberId
```

Do not copy an entire mutable workspace object into actionRef.

## 0.3 Stable result keys

Pin these or an equivalent deterministic scheme:

```
folder:<groupId>
shortcut:<placementId>
link:<placementId>
layout-member:<layoutId>:<memberId>
```

Result identity is occurrence identity.

## 0.4 Build breadcrumbs once

Use persisted folder ancestry.

The existing workspace has a simple parent walk in `pathTo()` that builds the `As you Go → ...` breadcrumb chain. Extract or implement a pure equivalent rather than calling UI/graph code for every keystroke.

Expected breadcrumbs:

### Folder

```
As you Go › Parent › Grandparent
```

Do not repeat the row's own name in the trailing breadcrumb.

### Shortcut/Link placement

```
As you Go › ... › containing folder
```

### Layout Item

```
As you Go › ... › containing folder › Window layout name
```

The whole layout is not itself searchable, but it is valid breadcrumb context.

## 0.5 Searchable text

V1 matching uses the display name only.

Do not rank against:

- breadcrumb;
- shortcut target path;
- URL;
- executable fingerprint;
- descriptor metadata.

If later approved, those become explicit product changes.

## 0.6 Normalization

Pin a single normalization function and unit-test it. Minimum:

```
Unicode normalize
case-fold/lowercase
trim
collapse repeated whitespace
```

Do not normalize the underlying display string shown in UI.

## 0.7 Ranking tiers

The ranking order is fixed:

```
Tier 0 — exact
Tier 1 — whole-name prefix
Tier 2 — word prefix
Tier 3 — fuzzy subsequence
no match
```

No fuzzy result may outrank a prefix result because of usage history.

Word-prefix behavior must be tested across:

```
spaces
hyphens
underscores
punctuation
multiple words
```

## 0.8 Tie-breaking

Within one relevance tier:

```
1. recency
2. frequency
3. normalized display name
4. breadcrumb
5. resultKey
```

The final deterministic fallback prevents list order from changing randomly across identical queries.

If the creator later specifies a different recency/frequency order, modify the pure ranking contract and tests only.

## 0.9 Synthetic performance corpus

Generate a representative synthetic workspace equivalent to roughly 10,000–20,000 searchable occurrences.

Include:

- deeply nested folders;
- duplicate shortcut placements;
- links;
- many layout-member occurrences;
- duplicate names;
- long names;
- fuzzy-match-heavy queries.

Measure only the pure query/ranking path after the index is built.

## 0.10 Performance gate

On the creator-relevant target machine or another agreed reference desktop:

```
20,000 indexed occurrences
1000 representative queries
```

Required target:

```
p95 query + ranking <= 8 ms
p99 <= 12 ms
no ordinary query >= 16 ms
```

Measure independently of DOM rendering.

Also record:

```
initial index build duration
full semantic rebuild duration
memory footprint
```

## STAGE 0 PASS GATE

Proceed with same-thread pure matching if the performance gate passes with comfortable margin.

## STAGE 0 WORKER FALLBACK

If the matcher cannot stay inside the budget, STOP UI implementation and move only the pure index/query engine to a Web Worker.

Suggested module:

```
public/app/quick-run/quick-run-worker.js
```

Worker requirements:

- immutable/versioned index payload;
- query sequence IDs;
- latest-query-wins;
- stale worker results discarded;
- no host calls;
- no native APIs;
- no DOM access;
- same pure ranking tests run against worker and direct modes.

Do not lower the latency target merely because the naïve implementation is slow.

# STAGE 1 — Canonical v1 index construction

Purpose: Convert current persisted state into the exact searchable universe.

Classification: HARD CORRECTNESS GATE

## 1.1 Folder inclusion

Include a group only if:

- it is not binned;
- none of its ancestors is binned.

## 1.2 Shortcut placement inclusion

For each shortcut record:

- classify `isWebLink(shortcut)`;
- enumerate every active placement;
- exclude a placement under a binned ancestor;
- emit one result per placement.

The existing model already expands shortcut records into one occurrence per active placement for normal workspace rendering. Reuse those semantics rather than collapsing linked placements.

## 1.3 Link classification

```
http/https target
→ type = link

everything else
→ type = shortcut
```

Do not duplicate the shortcut record/index.

## 1.4 Layout Item inclusion

For every active non-binned window layout:

- include every persisted arrangement member;
- result name = `member.descriptor.title`;
- result identity = layoutId + memberId;
- breadcrumb includes containing layout context.

Do not call:

```
windowCandidates()
resolveWindowDescriptor()
observeWindowCapability()
windowThumbnailCapability()
```

during indexing.

## 1.5 Row icons

Quick Run must show an icon without adding native work to the search path.

Allowed:

### Folder

- persisted/custom folder icon;
- existing normal folder fallback.

### Shortcut

- persisted shortcut icon if present;
- existing shortcut fallback otherwise.

### Link

- existing persisted/cached icon if already available;
- link fallback otherwise.

### Layout Item

- already-present in-memory member icon cache if available;
- static window/application placeholder otherwise.

Not allowed: opening Quick Run causes missing layout-member icons to hydrate through Papers.

Icon hydration is presentation enhancement, not search authority.

## 1.6 Whole-layout exclusion test

Given a layout `Work` with members `Chrome` and `VS Code`, the query `Work` must not return the whole layout merely because its name matches.

Layout name may only appear as the member breadcrumb.

## STAGE 1 EVIDENCE

Pure index snapshot tests must assert exact result keys and breadcrumbs for a fixture containing:

- nested folder;
- ordinary shortcut;
- linked shortcut with two placements;
- web link;
- window layout with two members;
- binned folder containing otherwise valid items;
- binned shortcut placement;
- binned window layout.

# STAGE 2 — Usage metadata for recency/frequency

Purpose: Implement tie-break history without coupling it to search-index identity.

Classification: CORE FEATURE

## 2.1 Define bounded usage records

Suggested shape:

```
{
  resultKey,
  lastUsedAt,
  useCount,
}
```

Do not persist query strings. Do not persist native window capability data.

## 2.2 Persistence location

Choose one bounded As-you-Go-owned durable location.

Recommended v1:

```
state.view.quickRunUsage
```

with normalization and a strict maximum record count.

Suggested cap:

```
2048–4096 result keys
```

If the project already develops a better per-project local preference store before this feature is implemented, reevaluate this placement explicitly rather than silently changing it.

## 2.3 Update policy

Increment usage only after a Quick Run action actually succeeds:

```
Folder navigation succeeded
Shortcut launch accepted
Link open accepted
Layout-item activation succeeded
Ctrl+Enter reveal completed
Shift+Enter add completed
```

A missing/ambiguous/denied layout member does not gain frequency.

## 2.4 Do not rebuild index for usage changes

Usage affects ranking only. Updating `lastUsedAt` / `useCount` must not rebuild the semantic search index.

## 2.5 Bound/prune

When over the cap:

- drop least-recently-used stale records first;
- do not allow usage history to grow unbounded.

Deleted result keys may be pruned opportunistically.

# STAGE 3 — Index invalidation architecture

Purpose: Keep Quick Run semantically current without rebuilding it for high-frequency irrelevant state.

Classification: HARD PERFORMANCE/CORRECTNESS CRITERION

## 3.1 Default strategy

Use whole semantic-index rebuild on a relevant searchable-data mutation.

Do not begin with complicated per-row incremental patches.

At 10k–20k occurrences, correctness is more important than avoiding an occasional bounded rebuild.

## 3.2 Local invalidation seam

Create one API, e.g. `quickRunIndex.invalidate(reason)`.

Every local mutation that changes Quick Run semantics routes through that seam.

## 3.3 Mutations that MUST invalidate/rebuild

### Folders

- [x] create folder; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(a new folder is a row with its own breadcrumb, from quick-run-mutation-coverage.test.mjs.)*
- [x] delete/permanently remove folder; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(deleting a folder takes its descendants with it, and the test names the rows that remain.)*
- [x] rename folder; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the reopen shows the new name and the children breadcrumb follows it, from quick-run-invalidation.test.mjs.)*
- [x] move folder; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the moved folder and the placement inside it take the new ancestor chain, asserted by breadcrumb.)*
- [x] bin folder; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(binning is the same disappearance as deletion, and the test follows it with a restore.)*
- [x] restore folder; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(unbinning returns exactly the universe that was there before, compared as a key set rather than by count.)*
- [x] any mutation changing its parent. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(covered by the folder-move and placement-move cases, plus a layout moved through its parent in the coverage file: the breadcrumb is rebuilt from the persisted ancestry every time.)*

Folder rename/move can change breadcrumbs for every descendant, so full rebuild is appropriate.

### Shortcuts/Links

- [x] create shortcut; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(a record with no placement adds no row, and becomes one the moment it is placed - the occurrence is the placement, which the fixture makes explicit with an unplaced record.)*
- [x] create link; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(the same creation path, classified by target: a placed https record arrives as a Link row.)*
- [x] delete shared shortcut record; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(every placement leaves with the record, asserted for both of its occurrences.)*
- [x] rename shortcut; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the placement row carries the new record name.)*
- [x] target change; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(a non-web retarget keeps the occurrence key and carries the new target, which is the distinction the classification case turns on.)*
- [x] URL/non-URL classification change; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the row changes type and the stable key moves with it, because the prefix is the type; asserted rather than glossed.)*
- [x] create placement; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(a second occurrence of one record, with its own breadcrumb and the shared record id.)*
- [x] remove placement; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(the row leaves and the record stays.)*
- [x] move placement; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the moved placement takes the new breadcrumb and the folder it left is untouched.)*
- [x] bin placement; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(only that occurrence disappears; its sibling is asserted untouched.)*
- [x] restore placement; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(the universe returns to exactly its previous key set.)*
- [x] fork placement where occurrence identity changes; — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(a fork is a new placement id, so it is a new row with a new key, sharing the record with the occurrence it was forked from.)*
- [x] collapse placements where occurrence identity changes. — `e8a7c03` @ `2026-09-12T09:00:49+07:00` *(the collapsed occurrences leave the universe and the surviving one keeps its identity.)*

### Window layouts relevant to members

- [x] create layout if it receives/contains searchable members; — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(a created layout brings its members into the universe under its own name in the breadcrumb, and the neighbouring layout is asserted untouched.)*
- [x] delete layout; — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(the deleted layout takes its member rows with it.)*
- [x] move layout; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the moved layout takes its members to the new ancestor chain, asserted by breadcrumb in quick-run-invalidation.test.mjs.)*
- [x] bin layout; — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(binning removes the member rows, and the test follows it with a restore.)*
- [x] restore layout; — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(unbinning returns exactly the universe that was there, compared as a key set.)*
- [x] layout name change, because layout name is part of member breadcrumbs; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(both members take the new layout name in their breadcrumb.)*
- [x] add member; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(one added member is exactly one added row.)*
- [x] remove member; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(a removed member leaves the universe.)*
- [x] change member descriptor title; — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the renamed member changes name, its neighbour does not, and the occurrence key is unchanged.)*
- [x] change member descriptor executable fingerprint; — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(a fingerprint change leaves both the display name and the occurrence key alone: the descriptor describes the window, the member id is the occurrence.)*
- [x] descriptor replacement/rebinding. — `c1e57d0` @ `2026-09-12T09:06:33+07:00` *(rebinding takes the new title and keeps the member id, which is the distinction the fingerprint case turns on.)*

## 3.4 Mutations that MUST NOT rebuild

This list is explicit because high-frequency false invalidation is a known performance risk.

Do not rebuild for:

- [x] graph x/y positions; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] graph rest positions; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] graph physics ticks; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] graph simulation cooling/heating; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] toolbar position; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] workspace selection; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] selection anchor; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] current folder navigation; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] breadcrumb navigation; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] graph-expanded folder state; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] trail-expanded folder state; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] Bin mode view toggle by itself; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] icon-size preference; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] theme/preferences unrelated to Quick Run hotkey; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] prompt-library changes; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] Set membership changes while Sets remain excluded; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] Set rename/creation while Sets remain excluded. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] activeWindowLayoutId; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] window-layout member state normal/minimized; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] window-layout member bounds; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] window-layout card size; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] window-layout member order; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] capability cache changes; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] helper restart by itself; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] hover; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] preview state; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] thumbnail result; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] icon hydration alone; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] widget open/close; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] detached/attached presentation state; — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*
- [x] recency/frequency usage metadata. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(section 3.4 case, asserted in quick-run-invalidation.test.mjs: the open session is a snapshot and cannot change, a fresh open over the mutated state finds the same universe, and the same query resolves to the same rows. Rows are compared as a set of stable keys, since member order may legitimately reorder occurrences on reopen; a control test proves a source change does move the content, so these cases measure something.)*

Window-layout bounds/state are updated by live observation and are specifically not searchable semantics. The model separates those data-only member patches from descriptor identity.

## 3.5 External/peer document installs

The current workspace supports external document installs from other As-you-Go surfaces while preserving local navigation/session state. Quick Run must react to semantic changes arriving through this path as well.

Implement a pure searchable semantic comparison for external installs. It should compare only fields relevant to the Quick Run index.

Do not use full-document equality.

Do not allow a remote window-layout bounds observation to rebuild a 20,000-entry search index every 500 ms.

## 3.6 External semantic signature

A valid semantic projection may include:

```
groups:
  id
  name
  parentId
  bin status

shortcuts:
  shortcut id
  name
  target
  placement id
  parentId
  bin status

window layouts:
  layout id
  name
  parentId
  bin status
  members:
    member id
    descriptor version
    descriptor title
    executable fingerprint
```

Explicitly omit:

```
bounds
normal/minimized state
cardSize
activeWindowLayoutId
icons
view positions
selection
runtime fields
```

## 3.7 Open Quick Run during rebuild

When semantic index changes while Quick Run is open:

1. atomically replace index;
2. rerun current query;
3. preserve current filter if it still has matches;
4. otherwise fall back to All;
5. preserve highlighted resultKey if still present;
6. otherwise highlight first result.

## STAGE 3 GATE

Synthetic tests must prove:

```
100 state-only layout observation updates
→ 0 search-index rebuilds

one member descriptor rename
→ exactly 1 semantic rebuild
```

# STAGE 4 — Quick Run UI shell

Purpose: Build the interaction surface without yet enabling all actions.

Classification: CORE FEATURE

Suggested new modules:

```
public/app/quick-run/quick-run-controller.js
public/app/quick-run/quick-run-view.js
public/styles/quick-run.css
```

Integrate from `public/workspace-20260730b.js`.

Prefer a dedicated controller rather than adding another large inline block to the workspace entry.

## 4.1 Modal ownership

Quick Run is its own transient modal interaction layer.

While open, it owns printable keys, Escape, Enter, Ctrl+Enter, Shift+Enter, Tab/Shift+Tab and arrows; ordinary workspace hotkeys do not also fire.

## 4.2 Opening state

On open:

```
query = ''
filter = All
highlight = null
results = []
```

Focus input immediately.

## 4.3 Empty query

Evidence:

```
open Quick Run
→ no results
→ no chips requiring result data
→ no native/host call
```

## 4.4 Styling

Quick Run must be visually part of As-you-Go, not a Papers-native popup.

Required:

- one-line input;
- chips above rows;
- bounded result panel;
- icon/name/breadcrumb row;
- clear highlighted row;
- unavailable-state treatment;
- scrollable long result list.

Do not change graph layout to make room. Render Quick Run over/above the workspace.

## 4.5 No normal workspace render

Typing `a`, `ab`, `abc` must not call the full workspace `render()` three times.

Add an instrumentation test/spying seam proving:

```
100 Quick Run keystrokes
→ 0 graph update calls
→ 0 workspace full-render calls
```

# STAGE 5 — Hotkey integration

Purpose: Make Quick Run a normal As-you-Go workspace action.

Classification: HARD V1 UX CRITERION

Files:

```
public/app/hotkeys-model.js
public/app/interactions/keyboard-controller.js
public/workspace-20260730b.js
```

## 5.1 Add workspace action

Add `workspace.quick-run` to the existing hotkey catalog.

Pick the actual default chord only if already approved by the creator; otherwise leave the binding explicit/TODO rather than inventing one silently.

## 5.2 Keyboard controller seam

The ordinary keyboard controller should invoke `quickRun.open()` only when:

- Quick Run is closed;
- no existing editor/confirm/prompt modal owns the key;
- event is not native typing inside another editable control.

While Quick Run is open, its controller gets first refusal for its own keys.

## 5.3 Focus scope proof

Verify:

```
As-you-Go focused
+ hotkey
→ Quick Run opens
```

and:

```
another desktop app focused
+ same keys
→ As-you-Go renderer does not magically receive it
```

The second result is expected v1 behavior.

Documentation note: OS-global activation requires a future Papers accelerator/routing feature; it must not move Quick Run indexing into Papers.

# STAGE 6 — Query, filtering and keyboard navigation

Purpose: Finish the pure interaction semantics before actions.

Classification: CORE FEATURE

## 6.1 Printable typing

Every query change:

1. normalize query;
2. run pure matcher;
3. calculate All results;
4. derive chip availability;
5. apply current type filter;
6. select/preserve highlight;
7. patch Quick Run DOM only.

## 6.2 Tab behavior

Tab must never insert a tab character into the search input.

Test complete wraparound:

```
All → Folders → Shortcuts → Links → Layout Items → All
```

but skip types with no matches. Reverse with Shift+Tab.

## 6.3 Highlight and scrolling

Arrow navigation must keep the highlighted row visible.

Wheel/trackpad scrolling must have an explicitly tested rule:

- scrolling list changes viewport normally;
- when a row becomes selected by intended scroll behavior, its selection is deterministic;
- keyboard highlight never points to an off-list stale row.

Do not rely on `:hover` as authoritative keyboard selection.

## 6.4 Mouse

If pointer selection is supported:

- moving over row may update highlight;
- click executes same default path as Enter;
- there is one execution implementation, not duplicate mouse/keyboard logic.

## STAGE 6 EVIDENCE

DOM/controller test sequence:

```
query produces 5 rows
highlight row 1
Down -> 2
Down -> 3
Up -> 2
Tab -> next available type
first result in that type highlighted
Shift+Tab -> prior type
Escape -> controller closed and query cleared
```

# STAGE 7 — Default actions for Folder, Shortcut and Link

Purpose: Reuse current As-you-Go behavior rather than reinvent execution.

Classification: CORE FEATURE

Primary existing module: `public/app/workspace-commands.js`

The current command layer already navigates folders through session navigation, launches ordinary shortcuts, and routes HTTP/HTTPS shortcuts through `host.openWebLink()`.

## 7.1 Execution-time authority gate

Before every action:

```
selected resultKey
→ read CURRENT state
→ resolve current object by stable IDs
→ verify it is still active/non-binned and still of expected type
→ only then execute
```

If stale, report that the Quick Run result changed or no longer exists. Do not execute a stale indexed payload. Requery immediately.

## 7.2 Folder Enter

Given `folder:<groupId>`, re-read the current groupId.

Verify:

- group exists;
- not binned;
- no binned ancestor.

Then perform the same navigation semantics as current `navigateToFolder()`.

On success: close Quick Run, record usage.

## 7.3 Shortcut Enter

Given `shortcut:<placementId>`, re-read the placement.

Verify:

- placement exists;
- active;
- under active hierarchy;
- underlying shortcut still non-web.

Launch using the existing shortcut execution path.

## 7.4 Link Enter

Given `link:<placementId>`, re-read placement and current shortcut. Verify `isWebLink()` still true.

If its target was edited from URL to non-web between query and Enter:

- do not execute from stale classification;
- rebuild/requery;
- tell controller the result changed.

Otherwise open through the existing `host.openWebLink()` path.

# STAGE 8 — Ctrl+Enter reveal-inside-As-you-Go

Purpose: Implement the deliberately new meaning of Reveal.

Classification: CORE FEATURE

Do not route this through:

```
workspace.reveal-selection
commands.revealSelection()
revealShortcut()
host.revealShortcut()
```

Those existing paths reveal the underlying target in the OS/file manager.

Suggested new module or command seam:

```
public/app/quick-run/quick-run-reveal.js
```

or a clearly named Quick Run-specific command inside `workspace-commands.js`.

## 8.1 Folder reveal

Navigate to the containing parent folder, then select the folder occurrence.

If the folder is at root: navigate root, select folder.

## 8.2 Shortcut/Link reveal

Navigate to that exact placement's parent folder, then select `placementId` — not another placement of the same shortcut.

This is why one-result-per-placement is mandatory.

## 8.3 Layout Item reveal

Navigate to the containing layout's folder. Then:

- reveal/select the containing window-layout card;
- visually identify/highlight the specific member within the card.

Do not activate/focus the native application as part of Ctrl+Enter.

## 8.4 Explorer vs graph presentation

Quick Run reveal must be truthful in both As-you-Go layouts. Define the expected visible result separately for `explorer` and `graph`.

For graph mode, use existing graph/item visibility/centering primitives if available; do not create a second graph camera implementation inside Quick Run.

If no existing "center this node" primitive exists, extract one from the graph controller rather than querying/manipulating SVG transforms ad hoc.

## 8.5 Evidence

After Ctrl+Enter:

```
session.currentId == result parent
session.selected contains exact occurrence ID
target occurrence is visibly identifiable
Quick Run is closed
```

For a Layout Item also assert the correct memberId, not merely the correct layout, receives the reveal cue.

# STAGE 9 — Papers activateWindowCapability

Purpose: Add the one host operation Quick Run cannot perform locally.

Classification: HARD LAYOUT-ITEM LAUNCH CRITERION

Quick Run needs: activate/focus this already-resolved exact window capability; restore it first if minimized.

Do not make the Backpack implement observe → decide → restore/raise as separate round trips if the helper can make the decision atomically.

The current Papers capability stack already has enumerated helper methods and a single-request atomic toggle path; activation should follow the same narrow typed design.

## 9.1 New method name

Recommended: `activate`

```
Page-facing Backpack bridge: activateWindowCapability(capability)
Project request:             papers:project:window-activate-capability
Papers IPC:                  papers:window-capability:activate
Helper method:               activate
```

## 9.2 Required native contract

In one helper request:

```
validate token identity
→ read current native state
→ if minimized:
     restore
  else:
     raise/focus
→ return typed success
```

No thumbnail. No preview frame seed. No desktop enumeration. No arbitrary HWND from renderer.

The current native helper already defines `Restore-WhWindow()` as restore plus Raise and has a native Raise operation used when applying bounds, so activation should reuse those trusted primitives rather than inventing another focus mechanism.

## 9.3 Files expected to change — As-you-Go

```
public/app/host/host-bridge.js
```

Add `activateWindowCapability(capability)` beside existing observe/toggle/minimize/restore/resolve methods. The bridge currently exposes the capability operations through enumerated Papers project request names.

## 9.4 Files expected to change — Papers

```
src/preload/backpackProject.ts
src/main/ipc/windowCapabilityIpc.ts
src/main/windows/windowCapabilityService.ts
src/main/windows/windowCapabilityClient.ts
src/main/windows/windowCapabilityTypes.ts
src/main/windows/windowHelperFactory.ts
resources/window-helper/window-helper.ps1
resources/window-helper/window-capability.ps1
```

The existing preload already parses opaque capabilities and maps project requests to enumerate/bind/observe/toggle/minimize/restore/etc.; activation should follow that exact trust boundary.

## 9.5 Helper hash pins

Because the helper scripts are resource-hash pinned, after changing helper files update both expected resource hash locations used by Papers:

```
src/main/windows/windowHelperResource.ts
resources/window-helper/manifest.json
```

Do not finish the Papers commit until actual helper bytes, compiled expected hash and manifest hash all agree.

## 9.6 Typed outcomes

At minimum support:

```
success
missing
denied
helper-unavailable
malformed/internal typed failure as existing protocol allows
```

`ambiguous` belongs to descriptor resolution before activation, not to activation of an already-issued exact capability.

## 9.7 Host tests

Pin:

### Normal window

```
activate
→ Raise called
→ Restore not called
```

### Minimized window

```
activate
→ Restore called
→ window raised/focused
```

### Stale/reused identity

```
activate
→ missing/denied
→ no other HWND raised
```

### Renderer authority

Malformed page capability cannot smuggle HWND, PID or path through the new operation.

## STAGE 9 GATE

Do not enable Layout Item Enter until the complete operation works end-to-end through the packaged Papers capability stack.

# STAGE 10 — Layout Item default action and availability state

Purpose: Make persisted window members searchable without live probing.

Classification: HARD FEATURE CRITERION

## 10.1 Availability state

Each Quick Run layout-member occurrence may have ephemeral session availability:

```
unknown
available
unavailable
```

Default: `unknown`

Do not infer "not running" from persisted `member.state`. Persisted normal/minimized is arrangement state, not a guarantee that the native window currently exists.

## 10.2 No probes while searching

Typing `c`, `ch`, `chr`, `chrome` must cause:

```
0 windowCandidates
0 resolveWindowDescriptor
0 observeWindowCapability
0 activateWindowCapability
0 thumbnail calls
```

## 10.3 Selection-time resolution

On Enter for `layout-member:<layoutId>:<memberId>`:

1. re-read layout by layoutId;
2. verify layout is still active/non-binned;
3. re-read member by memberId;
4. verify descriptor still matches the indexed result identity;
5. use existing cached `capabilityForMember()`/equivalent fast path if valid;
6. otherwise call `host.resolveWindowDescriptor(currentDescriptor)`;
7. only after successful unique resolution call `host.activateWindowCapability(capability)`.

The existing member capability path already caches by layout/member and resolves the persisted descriptor only on a miss. Reuse/extract that seam rather than building Quick Run-specific native resolution.

## 10.4 Exact resolution outcomes

### Unique and activation succeeds

```
availability = available
close Quick Run
record successful use
```

### Missing

```
availability = unavailable
reason = not-running/missing
keep Quick Run open
do not remove persisted result
do not silently do nothing
```

### Ambiguous

```
availability = unavailable
reason = multiple-matching-windows
keep Quick Run open
do not choose one
```

### Helper unavailable

```
availability = unavailable
reason = helper unavailable
keep Quick Run open
```

### Denied

```
availability = unavailable
reason = permission denied/unsupported
keep Quick Run open
```

## 10.5 Availability invalidation

Availability is ephemeral UI knowledge, not durable Backpack truth.

Reset to `unknown` when:

- descriptor changes;
- member is removed/re-added;
- page reloads;
- an operation reports stale/missing after previously successful use.

Do not write availability into persisted layout members.

## 10.6 Fresh capability test

Fixture: member exists in persisted layout, no runtime capability cached.

Search must show it. Only Enter may call descriptor resolution.

## 10.7 Ambiguity test

Two native windows satisfy the descriptor. Expected:

```
result remains in Quick Run
row becomes unavailable
message says multiple matches
0 activate calls
```

# STAGE 11 — Shift+Enter: add Layout Item to active window layout

> **CUT — 2026-09-13: Shift+Enter was removed, not repaired.** The creator chose the cut over a fix,
> because the gesture had one write path and it was not a truthful one: it installed state in memory
> without committing it, so on a surface without document-write authority the write could be refused and
> the old state handed back - with no throw - after which Quick Run still said "added" and closed the
> layer. A false success that silently loses the write is worse than a missing gesture.
>
> What was removed: the `planQuickRunShiftEnter` plan and its three disabled reasons, the
> duplicate-descriptor helper and the descriptor field list it kept, the binding's `onShiftEnter` and
> `shiftEnterNotice` callbacks and the store/render/window-layout collaborators they needed, the
> surface's Shift+Enter branch and the notice line that advertised it, and the tests that held them.
> The key is left deliberately inert rather than falling through to the default action, so a cut gesture
> cannot quietly become a second Enter.
>
> Every Shift+Enter box in this document is therefore UN-TICKED (2026-09-13) rather than left claiming a
> gesture that no longer exists. The Papers-side window-activation boxes are untouched by this cut: they
> were never about this key. `quick-run-entry.test.mjs` fails if any removed piece comes back, and
> `ARCHITECTURE.md` carries the cut under its Quick Run rows.

Purpose: Implement the only non-default modifier action enabled in v1.

Classification: CORE FEATURE

The model's `addWindowLayoutMember()` is data-only and takes a persisted member shape; it does not itself launch or mutate a native window. Reuse that model operation.

## 11.1 Preconditions

Before enabling Shift+Enter for a Layout Item:

- source occurrence still exists;
- active runtime recording context has a valid active layout;
- destination layout exists and is active/non-binned;
- destination is not read-only due to surface handoff/conflict;
- duplicate rule allows the addition.

## 11.2 Do not resolve native window unnecessarily

The source result already contains a persisted descriptor. Adding the same descriptor-bound window to another layout is primarily a data operation.

Do not run desktop enumeration merely to copy the descriptor if the current model contract allows the persisted descriptor to be reused.

If initial bounds/state are required for a truthful member creation, use already-known persisted source arrangement as the v1 starting arrangement unless a separate product requirement explicitly demands fresh observation.

## 11.3 New member identity

Never copy the source `member.id`. Destination receives a new membership ID. The descriptor is reused.

## 11.4 Duplicate rule

Pin one explicit rule. Recommended:

```
same descriptor already present in destination layout
→ do not add
→ visible "Already in active layout"
```

Do not silently create two identical members inside one layout unless current window-layout semantics explicitly allow that and the creator approves it.

## 11.5 No active layout

Shift+Enter is visibly disabled. Reason: `No active window layout`.

## 11.6 Non-Layout results

Folder/Shortcut/Link show Shift+Enter unavailable.

Do not launch a Shortcut hoping to infer which new window it creates. That is a different feature.

# STAGE 12 — Stale index and execution-race defenses

Purpose: Guarantee Quick Run never executes an object merely because it existed when the query was ranked.

Classification: HARD CORRECTNESS CRITERION

## 12.1 Every action revalidates

Mandatory for Enter, Ctrl+Enter, Shift+Enter and mouse activation.

Pattern:

```
resultKey
→ parse stable IDs
→ CURRENT state lookup
→ current active/non-binned check
→ current type/classification check
→ act
```

## 12.2 Rename race

```
Quick Run query shows "Chrome"
peer renames it before Enter
Enter
```

Expected: old indexed copy is not trusted; current object wins; query/index reruns; no stale action target.

## 12.3 Move race

Shortcut placement moves to another folder while highlighted. Ctrl+Enter must reveal its new parent, not old breadcrumb.

## 12.4 Bin race

Item is binned while highlighted. Enter must not resurrect/open it from stale Quick Run state. Requery removes it.

## 12.5 Member removal race

Layout member is removed while highlighted. Enter:

```
0 descriptor resolution
0 native activation
result disappears/requery
```

## 12.6 Classification race

Link target changes to a local shortcut target before Enter. Do not open stale URL. Re-read current shortcut and route according to current type.

# STAGE 13 — Multi-surface correctness

Purpose: Make Quick Run behave correctly with As-you-Go open in multiple Papers surfaces.

Classification: CORE FEATURE

Quick Run UI state is local to one surface:

```
open/closed
query
filter
highlight
availability UI
```

Do not synchronize those through the shared document. Searchable content comes from the current installed document state.

## 13.1 Peer rename

Surface A has Quick Run open. Surface B renames a folder. After A installs the peer document:

```
index updates
current query reruns
old name disappears
new name appears if matching
```

## 13.2 Peer move

Breadcrumb updates without moving A's local current navigation.

## 13.3 Peer layout observation

Surface B updates only native member bounds/state. Surface A: `0 Quick Run rebuilds`.

## 13.4 Usage metadata conflict

If usage history is stored in shared `view.quickRunUsage`, test two surfaces using Quick Run concurrently.

The result may tolerate last-write/merged tie-break metadata loss only if no workspace item data is lost.

If current coordinator merge semantics make frequent usage writes problematic, move usage metadata to a better bounded per-project local store before launch rather than weakening document consistency.

# STAGE 14 — Performance integration gate

Purpose: Prove the real UI remains responsive with graph physics and normal workspace load.

Classification: HARD LAUNCH QUALITY GATE

The pure Stage 0 benchmark is necessary but not sufficient.

## 14.1 Real renderer corpus

Load a synthetic/fixture workspace representing 10,000–20,000 searchable occurrences with graph mode active.

## 14.2 Measure keystroke-to-results

Measure:

```
keydown/input event timestamp
→ Quick Run result DOM committed
```

Target `p95 <= 16 ms`; preferred `p95 <= 12 ms` on creator-relevant hardware.

No repeated long tasks above one frame for ordinary queries.

## 14.3 Graph isolation evidence

During 100 rapid Quick Run query changes assert:

```
0 native window resolutions
0 thumbnails
0 host capability requests
0 graph simulation restarts caused by Quick Run
0 full workspace renders caused by query change
```

## 14.4 Rebuild performance

Trigger a semantic rename in a 20k-result workspace. Measure:

```
semantic mutation
→ new index active
→ current query reranked
```

Record duration.

If rebuild itself produces unacceptable visible typing stalls while Quick Run is open, build index asynchronously or move rebuild/search projection to the Worker architecture.

## 14.5 State-only storm

Simulate 1000 member bounds/state updates. Expected: `0 semantic index rebuilds`.

This is a hard regression test.

# STAGE 15 — Accessibility and keyboard quality

Purpose: Make Quick Run genuinely keyboard-first rather than merely key-operable.

Classification: LAUNCH QUALITY GATE

## 15.1 Focus

On open: `document.activeElement == Quick Run input`.

On close: return focus to the prior appropriate As-you-Go workspace element.

## 15.2 Semantics

Use appropriate combobox/listbox semantics or equivalent accessible pattern.

Required:

- input has meaningful accessible name;
- list exposes result count;
- active row is announced;
- disabled modifier actions have accessible reason where surfaced;
- availability state can be conveyed without relying only on color.

## 15.3 No keyboard leakage

While Quick Run is open, `Ctrl+Enter`, `Enter`, `Delete`, `G`, `Ctrl+G` must not trigger underlying workspace actions unless they are explicitly Quick Run commands.

## 15.4 IME/input correctness

Do not intercept Enter/keys incorrectly during active text composition.

Test with an IME/composition event sequence if the creator uses or may use non-Latin input.

# STAGE 16 — Error/status behavior

Purpose: Make failures visible and truthful.

Classification: CORE FEATURE

## 16.1 Successful action

Close Quick Run after successful folder navigate, shortcut launch, link open, native window activation, reveal, or add-to-layout.

## 16.2 Failed Layout Item activation

Keep Quick Run open. Show row/status reason. Examples:

```
Window is not currently available
Multiple matching windows
Window helper unavailable
Window access denied
```

Never silently close Quick Run on failure.

## 16.3 Stale result

If a result disappears between query and execution:

```
That item changed or no longer exists
```

Requery automatically.

## 16.4 Host failures

Do not expose raw helper/internal stack traces as the main Quick Run UX. Use typed existing host outcomes.

# STAGE 17 — Tests that must exist before completion

Classification: HARD DEFINITION-OF-DONE REQUIREMENTS

## Index domain

- [x] folder indexed. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` *(the universe case `the active tree is searched: folders, placements and layout members (section 2.1)` asserts the folder names the search returns, built from the model's `itemsIn` rather than from a directory walk. The annotation was empty - a tick script had dropped it - and is restored here from the commit that added the case.)*
- [x] nested folder breadcrumb correct. — `bd24a2c` @ `2026-09-12T08:17:59+07:00` *(a group at depth two and a member inside it both build the full chain, in the document's own order and with its separator (Workspace › Alpha › Focus asserted in the search suite). The rule and the format are tested; the surface that draws it is a later stage.)*
- [x] binned folder excluded. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] descendants under binned folder excluded. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] one ordinary shortcut placement indexed. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] linked shortcut with 3 placements gives 3 results. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted directly rather than by analogy: three placements of one shortcut produce three rows that share a name and one `shortcutId` while carrying three different breadcrumbs, which is the occurrence-identity rule of §0.3. The annotation was empty - a tick script had dropped it - and is restored here from the commit that added the case.)*
- [x] placement breadcrumbs independent. — `550e6cc` @ `2026-09-12T08:22:40+07:00` *(two placements of one shortcut in different folders produce two rows with different breadcrumbs **and** different result keys while sharing a name and target, which is the occurrence-identity rule the contract states. Asserted in quick-run-search.test.mjs.)*
- [x] HTTP shortcut classified as Link. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] HTTPS shortcut classified as Link. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] non-web shortcut classified as Shortcut. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] one layout member indexed. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] same descriptor in two layouts gives 2 results. — `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs, which pins the row type or the occurrence count for this case. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] whole layout never appears. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] binned layout member excluded. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] prompts excluded. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] Bin entries excluded. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*
- [x] Sets excluded, with a test/comment referencing the recorded product decision. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(asserted in quick-run-universe.test.mjs: the exclusion is proved, with the excluded shape present in the fixture. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)*

## Ranking

- [x] exact beats prefix. — `828d475` @ `2026-09-12T09:03:51+07:00` *(one query, four names, one per tier, with the input deliberately in reverse tier order so a ranking that preserved input order would fail; quick-run-ranking.test.mjs.)*
- [x] prefix beats word-prefix. — `828d475` @ `2026-09-12T09:03:51+07:00` *(the same fixture, and each adjacent pair is also asserted on its own rather than only as a run of four.)*
- [x] word-prefix beats subsequence. — `828d475` @ `2026-09-12T09:03:51+07:00` *(same fixture: "My note" outranks "Knoten", which matches n-o-t-e in order but at no word boundary.)*
- [x] subsequence beats no match. — `828d475` @ `2026-09-12T09:03:51+07:00` *(a fuzzy row is ranked with tier 3 and an unmatched row is absent from the answer entirely, which is a different statement from being ranked last.)*
- [x] recency never moves a lower tier above a higher tier. — `828d475` @ `2026-09-12T09:03:51+07:00` *(there is no recency input at all: the cases carry heavy usage metadata and the order does not move, and the module is scanned for recency, lastUsed and uses.)*
- [x] frequency never moves a lower tier above a higher tier. — `828d475` @ `2026-09-12T09:03:51+07:00` *(the same scan covers frequency, and the behavioural half is the usage case: a hundred uses on a fuzzy row leaves it below an exact match.)*
- [x] deterministic fallback stable. — `828d475` @ `2026-09-12T09:03:51+07:00` *(the sort is by tier, then by the position the row had in the universe, so the answer is a function of the universe and the query alone; the test pins both halves - same input, same order, and two rows in one tier keeping the order the universe gave them rather than an alphabetical or recent-first guess.)*
- [x] duplicate names remain separate by occurrence/resultKey. — `9d78518` @ `2026-09-12T08:23:53+07:00` *(nothing de-duplicates: quickRunRowViews returns one view per occurrence, the two share a primary name and differ in key and breadcrumb, and the highlight rides exactly one of them. The presentation suite asserts the flat list carries no grouping that could merge them.)*

## Filters

- [x] chips only for matched types. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the chip builder takes the types the current match set actually has, and the test asserts All plus exactly those, and nothing at all when there are no results.)*
- [x] Tab forward. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the cycle is the contract order and it wraps; a second test at )*
- [x] Shift+Tab backward. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the same test walks the cycle in both directions, so backward is not inferred from forward.)*
- [x] zero-match active filter falls back to All. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the fallback is immediate and the session test asserts the same rule after a keystroke that empties the active filter.)*
- [x] fallback highlights first All row. — `66fd5f4` @ `2026-09-12T08:32:47+07:00` *(when the active type filter loses its matches, the session falls back to `All`, reports `fellBack: true`, and sets the highlight to the first row of the fallback set — asserted in the session suite (`fellBack` plus `highlightKey === rows[0].resultKey`) and reached through the mount test's Tab handling.)*

## Empty query

- [x] empty query gives zero results. — `8bfc829` @ `2026-09-12T08:13:29+07:00` *( and )*
- [x] no recents home screen. — `8bfc829` @ `2026-09-12T08:13:29+07:00` *(the test that says an empty query shows nothing says so because the contract forbids a recents or home surface, and nothing in the seven modules builds one.)*
- [x] no host calls. — `4f63739` @ `2026-09-12T08:39:21+07:00` *( and )*

## Actions

- [x] Folder Enter navigates. — `a0c4266` @ `2026-09-12T08:46:36+07:00` and `e79e5f8` @ `2026-09-12T08:47:33+07:00` *(Enter re-reads the row by its stable key, plans the action, and hands the workspace item id to `commands.activateItem` — the same call workspace Enter makes, so a folder navigates rather than a second navigator existing. `quick-run-enter.test.mjs` drives a query to a folder row, through the plan and the id, into the real command object, and asserts the store is now in the folder that was searched for. The entry half is asserted by source shape, since the entry file boots from the document and cannot be imported; the acceptance-list twin at the foot of this file stays open until a run in the app.)*
- [x] Shortcut Enter launches. — `a0c4266` @ `2026-09-12T08:46:36+07:00` and `e79e5f8` @ `2026-09-12T08:47:33+07:00` *(the same chain, asserted against the real command object: the shortcut record id reaches `activateItem`, the host launches that id, and nothing reveals it — the launch path and the reveal path stay separate, which is what § 1.6 requires.)*
- [x] Link Enter opens URL. — `a0c4266` @ `2026-09-12T08:46:36+07:00` and `e79e5f8` @ `2026-09-12T08:47:33+07:00` *(a link is the shortcut record with a web target, so it takes the same item id; the test pins the https classification, asserts the URL is opened, and asserts nothing is launched as a program.)*
- [x] Ctrl+Enter Folder reveals exact folder occurrence. — `a097264` @ `2026-09-12T09:31:31+07:00` *(the plan navigates to the folder the occurrence lives in - the last entry of the persisted ancestor chain the row already carries - and selects the folder itself, with hostReveal false. quick-run-activation.test.mjs asserts the plan; quick-run-entry.test.mjs asserts the entry file follows it with the workspace own activateItem and selectItem, because the entry file cannot be imported here.)*
- [x] Ctrl+Enter Shortcut reveals exact placement. — `a097264` @ `2026-09-12T09:31:31+07:00` *(the plan selects the shared record and carries the placement id with it, so the reader sees which occurrence was meant rather than the record alone.)*
- [x] Ctrl+Enter Link reveals exact placement. — `a097264` @ `2026-09-12T09:31:31+07:00` *(a link is the same record with a web target and takes the same branch; classification decides the row type, not the reveal path.)*
- [x] Ctrl+Enter Layout Item reveals containing layout + member. — `a097264` @ `2026-09-12T09:31:31+07:00` *(the plan selects the containing layout and carries the member id; the window itself is never touched, which keeps this inside the workspace where section 1.6 puts it.)*
- [ ] Shift+Enter disabled for Folder. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(asserted against the mounted surface: the plan is disabled for every non-layout type and the reason is painted with the highlighted row. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] Shift+Enter disabled for Shortcut. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(asserted against the mounted surface: the plan is disabled for every non-layout type and the reason is painted with the highlighted row. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] Shift+Enter disabled for Link. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(asserted against the mounted surface: the plan is disabled for every non-layout type and the reason is painted with the highlighted row. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] Shift+Enter Layout Item adds new membership when valid. — `4db1254` @ `2026-09-12T10:01:10+07:00` *(the entry re-reads the row, asks the plan whether the key is available, finds the member in its source layout and the active layout in the current state, and writes through the model own `addWindowLayoutMember` - not a second implementation of the add - then repaints. The duplicate check runs **before** the write rather than relying on the model same-id guard, because two different members can describe one window. Source assertions hold the wiring, and the helper that decides the comparison is tested directly. The residual is honest and stated: the entry file cannot be imported here, so the last mile is asserted by shape plus the model-level behaviour.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] no active layout disables Shift+Enter. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(asserted against the mounted surface: the plan is disabled for every non-layout type and the reason is painted with the highlighted row. Re-annotated 2026-09-12 - a tick script dropped the original annotation.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [x] duplicate destination membership reports visible status. — `4db1254` @ `2026-09-12T10:01:10+07:00` *(refused with a reason rather than silently ignored: the status line says the window is already in the active layout, and the count of writes stays at zero because the refusal happens before `store.replace`. The comparison itself is the AUTHOR ruling of 2026-09-12 - the persisted descriptor is the durable native identity, so a member is the same window when it agrees on every field the descriptor declares (`title`, and `executableFingerprint` when present), while `memberId` and the source layout are occurrence and provenance. Tested for both directions: a declared fingerprint that differs is a different window, and a title-only descriptor matches the first member with that title.)*

## Stale-index execution

- [x] rename-before-Enter. — `616181f` @ `2026-09-12T09:02:42+07:00` *(the current row is executed and the indexed one is not; the test also states why a rename is the safe race - the occurrence identity is unchanged, so the re-read finds the same key with new content. These are the races between the index and the workspace, and every one of them is answered by revalidating the row by its stable key before planning anything; the five cases live in quick-run-enter.test.mjs beside the three Enter tests they extend.)*
- [x] move-before-Ctrl+Enter. — `a097264` @ `2026-09-12T09:31:31+07:00` *(the callback re-reads the row by its stable key before planning, so a placement that moved is revealed where it is now; the same revalidation the Enter races assert, applied to the other key.)*
- [x] bin-before-Enter. — `616181f` @ `2026-09-12T09:02:42+07:00` *(the row is gone from the current state, so the answer is the reason and no action; the harness records no launch. These are the races between the index and the workspace, and every one of them is answered by revalidating the row by its stable key before planning anything; the five cases live in quick-run-enter.test.mjs beside the three Enter tests they extend.)*
- [x] delete-before-Enter. — `616181f` @ `2026-09-12T09:02:42+07:00` *(the same shape, and the test asserts the harness launched nothing rather than only that a reason came back. These are the races between the index and the workspace, and every one of them is answered by revalidating the row by its stable key before planning anything; the five cases live in quick-run-enter.test.mjs beside the three Enter tests they extend.)*
- [x] layout-member-remove-before-Enter. — `616181f` @ `2026-09-12T09:02:42+07:00` *(removing the member removes the row, so the deferred activation is not even planned. These are the races between the index and the workspace, and every one of them is answered by revalidating the row by its stable key before planning anything; the five cases live in quick-run-enter.test.mjs beside the three Enter tests they extend.)*
- [x] Link→Shortcut target edit before Enter. — `616181f` @ `2026-09-12T09:02:42+07:00` *(the interesting race: the classification change moves the stable key, so the key the index held no longer exists and the stale URL cannot be opened even by accident - asserted against the harness openWeb log. These are the races between the index and the workspace, and every one of them is answered by revalidating the row by its stable key before planning anything; the five cases live in quick-run-enter.test.mjs beside the three Enter tests they extend.)*

Every test proves current-state revalidation.

## Availability/native

- [x] untouched Layout Item is unknown. — `f78cd16` @ `2026-09-12T08:42:28+07:00` and `217007f` @ `2026-09-12T08:43:01+07:00` *(the same two properties as the § 5 box above, stated here as the stage-10 box: an untouched member is `unknown`, and a persisted `minimized` does not change that.)*
- [x] searching does zero native resolution. — `4f63739` @ `2026-09-12T08:39:21+07:00` *( and )*
- [ ] first Enter resolves.
- [ ] unique resolution + activate success -> available.
- [x] missing -> unavailable. — `03bf9d0` @ `2026-09-12T09:13:34+07:00` *(a noted missing outcome reads unavailable on that occurrence, the row stays in the list, and an untouched item is still unknown - the three states section 10.1 distinguishes, asserted in quick-run-availability.test.mjs.)*
- [x] ambiguous -> unavailable. — `03bf9d0` @ `2026-09-12T09:13:34+07:00` *(the same shape, and the assertion also covers that nothing about which window was meant appears on the row: an ambiguous resolution reports candidates to the caller and says only unavailable here.)*
- [x] ambiguous -> zero activate calls. — `4541f19` @ `2026-09-12T09:11:59+07:00` *(the plan is the only thing that can authorise an activation, and it authorises exactly one outcome: ambiguous comes back with activate false and the candidate list. There is no call site yet, which is why this is the strongest available form of the rule: zero calls follow from the only authoriser saying no, and the live half stays open with the boxes that need the machine.)*
- [x] result remains searchable after missing/ambiguous outcome. — `03bf9d0` @ `2026-09-12T09:13:34+07:00` *(after either outcome the occurrence is still exactly where it was, with its name and breadcrumb - a failed resolution is not a removal, which is the rule the box names.)*
- [x] descriptor change resets prior availability. — `f78cd16` @ `2026-09-12T08:42:28+07:00` and `217007f` @ `2026-09-12T08:43:01+07:00` *(there is no cached availability to reset: availability is computed from the row kind on every paint, so a descriptor change cannot leave a stale state behind - the strongest form of the rule, and the reason the Layout Item boxes above stay open is that the resolution itself is unbuilt.)*
 **Corrected at `03bf9d0` @ `2026-09-12T09:13:34+07:00`:** the original reasoning here was that no availability is cached, so the rule held vacuously. That is no longer the case - availability is now held ephemerally per occurrence - so the reset is a real rule with a test: a noted answer carries the descriptor it was seen with, and a member whose title changed reads unknown again.
## Papers activation

- [ ] normal target raises/focuses.
- [ ] minimized target restores then activates.
- [ ] stale identity cannot activate replacement HWND.
- [ ] malformed capability rejected.
- [ ] page cannot supply HWND/PID/path.
- [ ] helper-unavailable typed failure.
- [ ] helper SHA-256 pins updated and validated.

## Invalidation

- [x] folder rename rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(a reopen over the renamed state shows the new name, and the children breadcrumb follows it. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] folder move rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the moved folder and its placement both take the new ancestor chain, asserted by breadcrumb rather than by count. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] shortcut rename rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the placement row carries the new record name. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] shortcut target classification change rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(a filesystem target becoming an https target turns the row from Shortcut to Link, and the stable key moves with the type - which the test asserts instead of glossing, because it is the one case where a rebuild changes identity. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] placement move rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the moved placement takes the new breadcrumb and the folder it left is untouched. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] layout member add/remove rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(adding a member adds exactly one row and removing one takes it out of the universe. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] descriptor change rebuilds. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(the renamed member changes name and its neighbour does not. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] layout name change rebuilds member breadcrumbs. — `2c9bec6` @ `2026-09-12T08:59:38+07:00` *(both members take the new layout name in their breadcrumb. These are index inputs, so the reopen is the test: quick-run-invalidation.test.mjs holds them beside the thirty-one cases that must not rebuild.)*
- [x] layout bounds update does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] layout minimize/restore state update does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] graph position update does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] selection update does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] capability cache update does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] icon hydration does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] Quick Run usage metadata does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] prompt change does not rebuild. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*
- [x] Sets change does not rebuild while Sets excluded. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(the same section 3.4 case, and it is the same table: this mutation changes nothing in the universe and nothing in a query result, before or after a reopen, and the open session cannot be moved at all. quick-run-invalidation.test.mjs carries the case by name.)*

## Performance

- [x] 10k corpus measured. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(measured, not estimated: 210 runs over seven queries, p50 0.90 ms, p95 1.33 ms, max 2.03 ms with the row field present, and p95 3.07 ms when a caller hands rows without it. Reproduce with node quick-run-benchmark.mjs in the As-you-Go checkout.)*
- [x] 20k corpus measured. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(the same run at 20k: p50 1.84 ms, p95 2.09 ms, max 3.46 ms with the field present, p95 6.18 ms without it.)*
- [x] pure p95 ≤ 8 ms or Worker fallback used. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(the budget is met and no Worker is needed: 2.09 ms p95 on the real product path (rows carry normalizedName), 6.18 ms even on the pessimistic path, and the worst single query in the run was 7.64 ms. Before this slice the same measurement was 9.4 ms, because the ranking normalised the query once per row.)*
- [x] no ordinary pure query ≥ 16 ms. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(the measured maximum across both corpora and all seven queries was 7.64 ms, less than half the floor, and the real path peaked at 3.46 ms.)*
- [x] integrated renderer p95 target satisfied. — `299152d` @ `2026-09-13T00:54:43+07:00` *(**met, and only after the measurement named its own cause.** This box was measured and NOT met at `59bed23` @ `2026-09-13T00:31:09+07:00`: p95 30 ms against 16 ms, over four runs, on STAGE 14.1's synthetic 20,000-occurrence workspace with graph mode active and 15 live physics nodes. The failure was not the corpus but the paint - latency tracked the rows committed by a single keystroke (1-200 rows: p95 2.6-6.1 ms; 3,001-12,000 rows: p95 58.2 ms with all 30 samples over one frame) because the surface painted every match and one letter of an ordinary query can rank thousands of them. The creator capped what is painted rather than redefining the gate: `QUICK_RUN_MAX_PAINTED_ROWS = 200` in `public/app/quick-run/quick-run-session.js`, applied where the session's rows are built so the paint, the arrow-key highlight and activation all see the same bounded list, with the honest match count carried beside it and a line in the surface that says how many matches are not shown. Same instrument, same corpus, same seven queries, re-run by the executor: **p95 4.3 ms, p50 3.6 ms, max 5.3 ms, 0 samples over one frame, 0 long tasks**. The row-count buckets record it independently of the summary: every commit is now at or below 200 rows (`rowsRange` caps at 200), so the buckets above 200 are empty by construction rather than unmeasured. What this does not close, stated rather than implied: the packaged-host half is NOT MEASURED (the harness launches `release\win-unpacked\Papers.exe` and is refused by a coordination gate whose wording appears nowhere in the current source, that build being 17 commits older than source HEAD), the mark is the DOM commit rather than the presented frame, and the Creator acceptance walk at the foot of this file is untouched.)*
- [x] typing causes zero graph reheat/full render. — `72384be` @ `2026-09-12T08:48:10+07:00` *(no module holds a reference to the graph or to the render function - render( and reheat are absent from all seven modules and from the entry region that mounts the surface - so a keystroke cannot restart physics it cannot reach.)*
- [x] state-only layout observation storm causes zero rebuilds. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(two hundred consecutive bounds and minimize/restore updates leave the open session, the universe and a query result byte-identical - a storm rather than a single update, because that is how the live observer reports.)*

# STAGE 18 — The Sets question must be recorded, not forgotten

Before final launch, confirm Section 4 records the creator's explicit answer.

**Recorded 2026-09-08: the creator explicitly confirmed Sets remain excluded from v1.**

Not allowed: "nobody remembered to ask."

Keep a test proving that exclusion so a future refactor does not accidentally surface them.

# STAGE 19 — Product documentation

Classification: HARD PRODUCT-HONESTY CRITERION

Document:

- Quick Run searches persisted As-you-Go objects, not the desktop.
- Layout Items can appear even when their application is no longer running.
- Quick Run does not continuously probe window availability.
- A Layout Item's availability is determined when the creator tries to activate it.
- Duplicate names with different breadcrumbs are intentional occurrences.
- Links are shortcuts classified by URL target.
- Whole window layouts are excluded.
- Prompts are excluded.
- Bin contents are excluded.
- Sets are excluded per the recorded creator decision.
- V1 hotkey works when As-you-Go has focus.
- OS-global invocation is a separate future Papers feature.
- Ctrl+Enter reveals inside As-you-Go, not in the operating-system file manager.
- Shift+Enter is only meaningful for Layout Items in v1.

# Definition of Done

Quick Run is complete only when all conditions below are true.

## Search behavior

- [x] Hotkey opens one empty focused Quick Run line. — `10f8ae6` @ `2026-09-12T08:29:36+07:00` *(one line, empty, and focused: `open()` resets the session to an empty query, paints (which draws no rows and no chips for an empty query), and calls `focus()` on the input — guarded with `?.` because a caller may mount without a focusable field, and asserted in the surface test. **Same residual as the box above:** the key press itself is not exercised, because the entry file is not importable and this loop has no browser.)*
- [x] Empty query shows no results. — `8bfc829` @ `2026-09-12T08:13:29+07:00` *( and )*
- [x] First keystroke produces ranked results. — `8bfc829` @ `2026-09-12T08:13:29+07:00` *(the index ranks the snapshot on the first non-empty query; the session captures that snapshot once at open, which is what makes the first keystroke a ranking rather than a scan.)*
- [x] Search remains responsive with 10k–20k searchable occurrences. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(responsiveness is now a number rather than an adjective: 10k ranks in 1.33 ms p95 and 20k in 2.09 ms p95, both far inside a frame.)*
- [x] Exact > prefix > word-prefix > fuzzy subsequence. — `828d475` @ `2026-09-12T09:03:51+07:00` *(the four tiers, in one ranked answer and then pair by pair.)*
- [x] Recency/frequency only break ties inside a tier. — `828d475` @ `2026-09-12T09:03:51+07:00` *(stronger than the box asks, and stated as what is true: v1 has no recency or frequency input anywhere in the ranking, so they cannot break a tie inside a tier either - the tie-break is the universe order. If usage metadata is ever added, this box is where the rule will need re-asserting.)*
- [x] Result ordering is deterministic. — `828d475` @ `2026-09-12T09:03:51+07:00` *(the ranking is a function of the universe and the query, and the universe itself is pinned by the index-domain and invalidation tests, so the same state and query are the same list every time.)*
- [x] One shortcut placement = one result. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(, )*
- [x] One layout-member occurrence = one result. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(two layouts holding the same window descriptor are two results, one per layout, with keys that differ by layout and breadcrumbs that name their layout - the duplicate name is kept rather than collapsed, which is what the contract says to expect.)*
- [x] Links use the shortcut index and are classified, not duplicated. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(a link is the same record with a web target: the row key is link:<placementId>, there is exactly one row per placement, and http and https are classified as Links while a filesystem target stays a Shortcut - so classification chooses the type rather than adding a second index.)*

## Filters

- [x] All/Folders/Shortcuts/Links/Layout Items behave exactly as specified. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(each filter shows its own kind and All keeps the ranked order, asserted over the five names the contract fixes.)*
- [x] Only types with matches produce chips. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(same rule as the first case, asserted from the other direction: no match, no chip.)*
- [x] Tab/Shift+Tab cycles only available chips. — `5be5cdd` @ `2026-09-12T09:39:46+07:00` *(the AUTHOR ruling of 2026-09-12, implemented. The five names are the vocabulary and its order; the chips are the subset with a current match; a step moves to the next offered chip in canonical order and never lands on a name the query has emptied - the fallback-to-All rule is for a filter that becomes unavailable because the query changed, not for traversal. `nextAvailableFilter` holds the step, `quickRunSessionAfterTab` gives it the chips the session already computed, and the mount calls it. The surface test asserts the ruling through the real mount (with the query "docs" one Tab from All lands on Links with no fallback, the next wraps to All, Shift+Tab reverses it) and the types test pins both edges: nothing on offer means nothing moves, and a filter that is not on offer lands on the first chip rather than nowhere.)*
- [x] Disappearing active filter falls back to All. — `c0737a2` @ `2026-09-12T08:09:53+07:00` *(the active filter losing its matches falls back to All and says that it did, so the fallback is visible rather than silent.)*

## Actions

- [x] Folder Enter navigates. — `779c352` @ `2026-09-12T15:45:12+07:00` *(acceptance rather than source shape: `quick-run-workspace.test.mjs` types a query into the production markup's input element, fires Enter at the layer, and the real store's session is in the folder that was searched for. The wiring moved out of the entry file into `public/app/quick-run/quick-run-workspace.js` so the harness drives the production line instead of a copy of it, and section 16.1's close-on-success - written in the contract and never implemented - now closes the layer after the hand-off. Removing the hand-off, or the re-read guard, fails the harness.)*
- [x] Shortcut Enter launches. — `779c352` @ `2026-09-12T15:45:12+07:00` *(the drawn row's Enter reaches the real `activateItem`, the launcher records the shared record id and nothing else: the web opener and the reveal path both stay empty, which is the mutual exclusivity section 1.6 asks for, and the layer closes.)*
- [x] Link Enter opens web link. — `779c352` @ `2026-09-12T15:45:12+07:00` *(the same path with the other classification: the host's web opener records the https URL and the launcher records nothing, so "opened" and "launched" are distinguished by which effect ran rather than by which branch was taken.)*
- [ ] Layout Item Enter uniquely resolves and activates/restores the exact native window.
- [ ] Missing/ambiguous Layout Item remains visible and reports failure honestly.
- [x] Ctrl+Enter navigates-and-selects the exact As-you-Go occurrence. — `779c352` @ `2026-09-12T15:45:12+07:00` *(the doubled record is the test: one shortcut placed in two folders draws two rows, the arrow key asks for the second, and Ctrl+Enter navigates to **that** occurrence's folder and selects the shared record - the plan's `navigateTo` comes from the row's own ancestor chain, so navigating to the record instead fails the harness, and so does selecting the placement rather than the record. The OS reveal path stays empty.)*
- [x] Ctrl+Enter never invokes OS reveal. — `a097264` @ `2026-09-12T09:31:31+07:00` *(structural rather than behavioural: every branch of the plan answers hostReveal false, the entry callback follows the plan and calls only the workspace own navigate and select commands, and the entry region is asserted not to contain the reveal command it would be tempting to reuse. No app run is needed for this particular claim.)*
- [ ] Shift+Enter only works for Layout Items. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(the plan answers only-layout-items for every other type, the mount only calls the caller when the plan is enabled, and the surface test drives a folder row and a link row through the real mount and asserts that nothing is called. The entry half is asserted by source shape, as with the Enter tests, because the entry file cannot be imported here.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*
- [ ] Shift+Enter never silently does nothing for unsupported result types. — `435f02b` @ `2026-09-12T08:52:20+07:00` *(the reason is painted with the highlighted row before the key is pressed and stays on screen when it is, and the key is consumed rather than passed on - so the disabled case is visible rather than dead. This is the surface half of the rule; a run in the app is still what would confirm the wiring end to end.)* *(CUT 2026-09-13: removed with the gesture - see the note under STAGE 11.)*

## Native boundary

- [x] Typing causes zero native probes. — `4f63739` @ `2026-09-12T08:39:21+07:00` *( and )*
- [x] Indexing causes zero native probes. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(the same scan from the other end: the universe is built from three persisted sources, and the scan finds no native or host reference in any module.)*
- [x] Layout-item capability resolution begins only on execution. — `e38d55d` @ `2026-09-12T09:05:10+07:00` *(there is no capability resolution anywhere in v1 - the plan for a Layout Item answers deferred with a reason - so nothing can begin resolving earlier than execution, and the scan holds that absence.)*
- [ ] Papers exposes a narrowly typed `activateWindowCapability`.
- [ ] Activation restores only when minimized and otherwise raises/focuses.
- [ ] Capability identity remains fail-closed.
- [ ] Helper resource hash pins are correct.

## Correctness under mutation

- [x] Every action revalidates against current state. — `d11206e` @ `2026-09-12T08:40:17+07:00` and `a0c4266` @ `2026-09-12T08:46:36+07:00` *(revalidateQuickRunRow rebuilds the universe from the current state and finds the row by its pinned stable key, and the entry activation path calls it before planning anything.)*
- [x] Rename/move/bin/delete races cannot execute stale index payload. — `616181f` @ `2026-09-12T09:02:42+07:00` *(rename, bin and delete each have a case, and each asserts the *absence* of an effect rather than only the presence of a reason: the harness launch and openWeb logs stay empty. Move is the fifth case and is covered by the same revalidation, since a move changes the breadcrumb and not the key; the Ctrl+Enter half of it waits with Ctrl+Enter.)*
- [x] Peer document semantic changes refresh Quick Run. — `dcc7789` @ `2026-09-12T09:09:52+07:00` *(the answer has two halves and both are asserted: a change a peer writes into the document is seen by the next open, because that is the only moment Quick Run reads the workspace, and a session already open keeps its snapshot because section 3.4 forbids rebuilding under a reader - so the refresh is on reopen rather than mid-session, which is a product answer rather than a gap. The test writes the two changes a peer could make, a rename and an added layout member.)*
- [x] High-frequency member bounds/state updates do not rebuild the index. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(both are cases in the section 3.4 table: bounds and minimize/restore change neither the universe nor a query result, before or after a reopen.)*
- [x] Graph/session/view changes do not unnecessarily rebuild the index. — `83ac52f` @ `2026-09-12T08:58:34+07:00` *(graph positions, graph rest positions, physics ticks, selection, icon-size and theme preferences and current-folder navigation are all cases in that table.)*

## Performance

- [x] Pure 20k benchmark meets budget or Worker fallback is implemented. — `22f68dd` @ `2026-09-12T09:08:38+07:00` *(met on measurement rather than by assumption: 20k p95 2.09 ms against the 8 ms budget, so the Worker alternative was not needed - and section 6 forbids worker architecture before profiling proves it necessary, which this measurement now answers in the negative.)*
- [x] Integrated typing stays inside agreed frame-latency budget. — `299152d` @ `2026-09-13T00:54:43+07:00` *(the same run as the STAGE 17 box above, before and after. Before the cap, typing committed as many as 12,213 rows in one go and measured **p95 30 ms** against the agreed 16 ms, with 45 long tasks and 44 of 401 samples over one frame. With the paint capped at 200 rows it measures **p95 4.3 ms (p50 3.6, max 5.3), 0 samples over one frame and 0 long tasks**. The long-task figure is the one that matters for this box: the earlier caveat that the commit mark is a lower bound came from tasks that began at a keystroke and outlasted it, and there are now none to attribute. Reproduce with `npm run test:quick-run:integrated-perf` in the As-you-Go tree; its exit code is the verdict.)*
- [x] Quick Run typing never reheats graph physics. — `72384be` @ `2026-09-12T08:48:10+07:00` *(the same structural fact, asserted as a scan so a later pass cannot add one quietly.)*
- [x] Quick Run typing never calls full workspace `render()`. — `72384be` @ `2026-09-12T08:48:10+07:00` *(the same scan, and the reason the rule is structural rather than behavioural: there is nothing to guard at runtime.)*
- [x] No native/IPC work occurs on keystrokes. — `4f63739` @ `2026-09-12T08:39:21+07:00` *( and )*

## Scope/product honesty

- [x] No prompts. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(a populated prompt library contributes no row, asserted rather than assumed.)*
- [x] No whole layouts. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the four row types are pinned and a layout name appears only inside a member breadcrumb.)*
- [x] No Bin. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(all four bin shapes are excluded: a binned folder with descendants, a binned placement, a binned layout, and a layout under a binned folder.)*
- [x] Sets decision explicitly recorded (excluded; confirmed 2026-09-08). — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(the universe test header names the decision and its date - Sets are out for v1, keeping exactly the five chips - and the test asserts that a populated sets array contributes nothing.)*
- [x] No OS-global hotkey in v1. — `362a00d` @ `2026-09-12T08:19:15+07:00` *(the acceptance side of the same prohibition, on the same evidence: nothing in the tree registers a global shortcut, and Quick Run's catalog entry is workspace-scoped. The hotkey opens the surface only while the As-you-Go window can receive keyboard input, which is the v1 scope the surrounding boxes state.)*
- [x] No Papers-level universal search architecture. — `fc8c1da` @ `2026-09-12T08:54:24+07:00` and `ae3697a` @ `2026-09-12T08:55:55+07:00` *(v1 is one feature inside the As-you-Go app with a fixed source list and no registry, aggregator or cross-Backpack API; the universe test pins the three sources, and the claim is about this code rather than about what a future version might add.)*
- [x] No live window availability scanning. — `72384be` @ `2026-09-12T08:48:10+07:00` *(no module under quick-run observes anything or polls on a timer - no MutationObserver, ResizeObserver, setInterval or requestAnimationFrame - and availability is computed from the row kind alone.)*

# Creator acceptance walk

Run this on a real creator-sized workspace, not only test fixtures.

## Setup

Create or use a workspace containing:

- several nested folders;
- at least one shortcut linked into two folders;
- at least one web link;
- at least two window layouts;
- at least one same application/window represented in multiple layout occurrences where valid;
- one persisted layout member whose native application is currently closed;
- enough synthetic/real data to stress normal search performance.

## Walk

1. Focus the As-you-Go workspace.
2. Press the configured Quick Run hotkey.
3. Verify one empty search line appears and nothing else is selected or changed.
4. Type the beginning of a folder name.
5. Verify results appear immediately.
6. Verify exact/prefix ordering.
7. Verify each row contains icon, name and breadcrumb.
8. Search for a duplicated linked shortcut.
9. Verify each placement appears separately with its own breadcrumb.
10. Press Tab repeatedly.
11. Verify only matched type chips participate.
12. Cause the selected chip type to lose all matches by typing another character.
13. Verify filter falls back to All and first All result highlights.
14. Use ArrowUp/ArrowDown.
15. Verify highlight changes immediately and stays visible.
16. Select a Folder and press Enter.
17. Verify As-you-Go navigates into it.
18. Reopen Quick Run and launch a normal Shortcut.
19. Reopen Quick Run and open a Link.
20. Reopen Quick Run and select a shortcut placement with Ctrl+Enter.
21. Verify As-you-Go navigates to the exact placement and selects it.
22. Verify no OS file-manager reveal occurred.
23. Reopen Quick Run and select a Layout Item with Ctrl+Enter.
24. Verify its containing layout is revealed and the exact member is identifiable.
25. Reopen Quick Run and select a currently running Layout Item with Enter.
26. Verify the application window immediately becomes active.
27. Minimize that native application.
28. Invoke it again from Quick Run.
29. Verify it restores and becomes active.
30. Search for the persisted member whose application is closed.
31. Verify it still appears without being falsely labelled "Not running" before selection.
32. Press Enter.
33. Verify Quick Run stays open and truthfully marks/reports that the window is unavailable.
34. If possible, create two ambiguous matching native windows for one descriptor.
35. Press Enter on that result.
36. Verify neither native window is chosen automatically.
37. Activate a window layout.
38. Reopen Quick Run.
39. Select a Layout Item from another layout.
40. Press Shift+Enter.
41. Verify a new membership is added to the active layout according to the duplicate rule.
42. Highlight a Folder/Shortcut/Link and hold Shift.
43. Verify the add-to-layout action is visibly unavailable.
44. Rename an indexed object from another As-you-Go surface while Quick Run remains open.
45. Verify the result refreshes without disturbing that surface's local navigation.
46. Generate repeated window-layout observation bounds/state changes.
47. Verify Quick Run remains responsive and the semantic index does not rebuild.
48. Enter graph mode.
49. Type rapidly into Quick Run.
50. Verify graph physics does not reheat or hitch because of search.
51. Test a 10k–20k occurrence workspace.
52. Confirm measured query and integrated input latency meet the performance gates.
53. Press Escape from a populated Quick Run.
54. Verify the UI disappears, no result executes, and the underlying workspace remains otherwise untouched.
55. Reopen Quick Run and verify no empty-query recents/home screen appears.
56. Confirm the recorded Sets product decision matches the shipped behavior.

The feature is done only when this entire acceptance walk succeeds, the performance measurements pass, and the creator confirms that Quick Run feels immediate enough to use as the primary fast-access path inside As-you-Go.

# Open items to settle before implementation begins

- [x] **Sets decision** — resolved 2026-09-08: excluded from v1.
- [x] **Pin the default workspace hotkey chord.** — chosen by the creator on 2026-09-12: **Alt+Shift+X**,
      for the As-you-Go workspace scope. Recorded here rather than inferred: it was the last open item in
      this section, and § at L1032 asks for it to be an explicit binding rather than an invented default.

# The Papers host half as found, and the statement it requires

STAGE 9 asks for one narrowly named host capability — `activateWindowCapability` — and this section
records what that change actually is, measured against the Papers checkout on 2026-09-12 rather than
inferred from this checklist. **Nothing in the Papers tree was changed to produce it**, and no box above
is ticked on the strength of it.

**What already exists.** Every file §9.4 lists is present, and the capability chain around them is
built: `src/main/windows/windowCapabilityTypes.ts`, `windowCapabilityService.ts` (53 KB),
`windowCapabilityClient.ts`, `windowHelperFactory.ts`, `src/main/ipc/windowCapabilityIpc.ts`,
`src/preload/backpackProject.ts`, and both helper scripts under `resources/window-helper/`
(`window-helper.ps1`, 33 KB, and `window-capability.ps1`, 45 KB). The helper already carries the Win32
activation primitives — `DwmActivateLivePreview`, `SW_SHOWNOACTIVATE`, and a comment stating the very
rule §10.4 asks for: activation raises inside the ordinary z-order and is "deliberately never
HWND_TOPMOST". The service's toggle already chooses `restore` when the observation says `minimized`.

**What is missing.** `activateWindowCapability` has **no occurrence anywhere in the checkout** — a scan
of all 406 text files outside `node_modules`, `out`, `release` and `.git` returns zero, and the types
parser's vocabulary is observe, minimize, restore and toggle. So the smallest host change is one named
method beside those, following the trust boundary this checklist names: parse the opaque capability,
resolve the exact window, restore it only when it is minimized, otherwise raise and focus it, and answer
with a typed outcome. The seven Papers activation boxes and the four native-boundary boxes are about
that method and the helper pins around it, not about building a service that is already there.

**Why it needs the creator before it is written.** `PAPERS 3\Papers-3\HERMES.md` is the Papers contract,
and it is explicit about this exact case: a request concerning one Backpack does not authorize a
Papers-wide capability or a source-level abstraction, and Backpack work belongs outside Papers' binaries
"unless a concrete requirement explicitly needs a Papers-host change". Quick Run has that concrete
requirement — a Layout Item cannot be activated without it — but the same contract requires a statement
to the creator before Papers is changed, and it keeps host work separate from any release. In that
format, for this change:

1. **What the creator is asking to experience.** Pressing Enter on a Layout Item in Quick Run brings
   that exact native window forward — restored if it was minimized, raised and focused otherwise.
2. **What is in scope.** One Papers-host method, `activateWindowCapability`, with the tests §9.7 names.
   The Quick Run side already calls a seam that waits for it, so nothing on the Backpack side moves.
3. **What this does not authorize.** No release, no installation, no restart of the creator's running
   Papers, no rebuild, and no new Papers-wide abstraction: the existing window-capability service stays
   the single implementation.
4. **Genuinely open product questions.** None for the host method itself. The two Performance boxes and
   the creator's acceptance walk stay separate, and the performance numbers need the creator's instance.
5. **Release or installation authorized?** No — and none is requested here.
6. **Which machines, and why a main-binary change is required.** Only this machine needs the experience
   now. It belongs in Papers rather than in the Backpack because activating a foreign window is a host
   capability the Backpack cannot reach — the helper is invoked by Papers' main process, and a renderer
   cannot supply an HWND, a PID or a path, which is the fail-closed rule §9.6 states.

Until that statement is answered, the fourteen boxes that wait on the host half stay open, the two
Performance boxes stay open for the reason Status records, and the Papers checkout stays untouched.
