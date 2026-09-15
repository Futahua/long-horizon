# Alt+A targets a project that declares a command surface, and the gate that refused every channel

**Lane 4 · round seven · branch `alt-a-launcher-overlay`, on top of the installed `4a6120a`**

**Committed** `15a668f4136e5e4670e2e13af83989d44bcfd4e3` at `2026-09-15T10:50:40+07:00`, branch
**`alt-a-launcher-overlay`**. Not pushed, **not installed**.

**Host suite at that SHA:** `106 passed | 1 skipped` files, **1075 passed | 4 skipped (1079)**,
5.06s, and `npx tsc --noEmit` exit 0. Baseline on `4a6120a` was `103 passed | 1 skipped` files,
`1025 passed | 4 skipped (1029)` — measured by stashing, not assumed. **50 tests added, 0 removed,
0 newly skipped.** New e2e file `tests/e2e/launcher-target.e2e.ts`: **4 passed (4)**, driven
against a real Papers.

**Working trees.** This round's tree is `D:\Programs\evTEMP\papers-overlay-build` (a git worktree
of `Products\Papers\Source`) because `alt-a-launcher-overlay` is checked out there — that is the
branch holding the installed build. `Products\Papers\Source` carries
`backpack-local-service-bridge` @ `5d039f7` and was left alone. The creator's install is
`D:\Letters\MatTroiSeConMoc\Papers\App` (asar-packed, main at `523ad79`).

---

## 1. Two defects, and only one of them was a nuisance

The creator reported the launcher rendering **Proxima's task board** — a project with no command
surface at all — inside the 640×220 letterbox. Lane 3 reported the reason it had no items:

```
Error invoking remote method host:backpack-project:state-load:
Error: host channel called from non-host sender
```

The second is the one that matters. The first is a wrong answer; the second is **no answer at
all**, and it is why the feature could not be used. Lane 3's diagnosis was correct in every
particular I checked, and their reading of the guard — that it throws before the facade — is what
the code does.

---

## 2. What Alt+A means

> **Alt+A launches the project that DECLARES a command surface.** Not the project in front.

The old rule read the **active tab** of the first live Papers window. That is invisible to the
creator *by construction*: the entire point of the chord is that they are not in Papers when they
press it, so whichever tab they left in front three hours ago is effectively random. A chord cannot
have one meaning if its target is chosen by state the creator cannot see.

**Declaring is the project's act, not the host's inference.** A project states it in its own
control record by naming the marker the host should append:

```json
{ "schemaVersion": 1, "backpackId": "bp-…", "entry": "public/index.html",
  "launcherSurface": "command-surface" }
```

The host carries that string and never learns what it means — the same opaque-marker mechanism the
compact widget already uses (`?papers-surface=compact-widget`). Nothing about any Backpack is
compiled into Papers, and **Proxima is not special-cased: it simply declares nothing.**

### The rule, and every hard case

| Situation | What happens | Why |
| --- | --- | --- |
| Exactly one open project declares one | **that one** | No configuring and no explaining. The common case is invisible. |
| The creator has nominated one | **that one**, always | A nomination outranks everything, so the chord means one thing forever. |
| Several declare one, none nominated | **refuse, naming the candidates** | See below. |
| None declares one | **refuse, naming the Backpacks it looked at** | The creator cannot check the front tab themselves, so the message must. |
| The nominated project is closed | **refuse** | Never a silent substitution to a different project. |
| The nominated project no longer declares one | **refuse** | A stale nomination must not fall back into rendering a project with no command surface. |
| A declaration cannot be read | treated as **no declaration** | It can never make a project launchable by accident, and never fails the chord open. |

**Why "several declare one" refuses.** Every alternative is a rule the creator has to know in order
to predict the chord, and the two obvious ones are both wrong. *The front one* is the defect. *The
most recently used one* means switching tabs between two presses makes one chord two features —
which the creator named explicitly as unacceptable. A refusal is not a dead end: it **names the
candidates**, and one press settles it permanently by nominating.

**Tab changes cannot change the answer.** With one declared project the target is fixed. With
several, the answer is a refusal regardless of which is in front; a test asserts the refusal is
*identical* under both tab orders.

---

## 3. Why there were two registries, and why reconciling was the fix

This is the question the round was asked to answer rather than patch around.

- **`surfaceContexts`** answers **who a request is from** — sender → project, window, kind. It is
  written for *every* Papers-owned surface without exception. That is precisely what a guard asking
  *"may this sender act for this project?"* needs.
- **`BackpackSurfaceRegistry`** (one instance for detach, one for compact widgets) answers **which
  surfaces exist for a feature** — the detach path looks one up by project, the widget path by
  layout key. Those are feature questions.

**The guard asked the feature registries.** So a surface Papers owned and bound, but for which no
feature had a lookup, was invisible to it — which is exactly the launcher. It had been bound as
`widget`, on this recorded reasoning, quoted from the code it replaced:

> "the gate treats every non-detached kind alike, and the widget-only lookup additionally requires a
> layout key that the launcher never carries… Adding a third kind would mean changing the registry,
> the sender gate and the snapshot schema for no behavioural difference."

**Both halves of that were wrong**, and the comment is now replaced with the truth: the gate did
*not* treat kinds alike (it never consulted the registry the launcher was in), and the kind is not
cosmetic (it decides capabilities; see §4).

So: **trust is asked of the registry that binds every surface**, and the feature registries keep
answering their own questions. The URL must still carry the bound project, so a surface bound to one
project still cannot act for another.

### Is the guard weaker?

**No — narrower in one direction and wider in exactly one, and both are deliberate.**

- **Narrower:** a sender is no longer admitted merely for appearing in a feature registry. The
  binding is now load-bearing.
- **Wider:** it admits a surface the host owns and bound for which no feature has a lookup. That is
  the bug.

The property the check exists for is asserted directly: a page with a **correct project URL** that
the host never bound is **refused**, and a bound sender whose URL is not a project URL is refused.

---

## 4. Which channels the launcher may use, and which it may not

Admitting the launcher under the `widget` kind would have handed it a compact widget's window
picking and state writing. So it has **its own kind**, and admission is split into two questions
that used to be one: *is this an owned project surface for the project it is showing*, **and** *may
a surface of its kind use **this channel***. The capability is looked up from the real channel name,
so a caller cannot ask for permission it names itself. **An unknown kind and an unknown capability
both get nothing** — the opposite of the arrangement where a new kind inherited every channel the
moment it appeared in a registry.

| Capability | Channels | Launcher |
| --- | --- | --- |
| read | `state-load`, `state-load-versioned`, `shortcut-icon`, `resolve-web-link-icon` | **yes** |
| invoke | `launch-shortcut`, `run-action` | **yes** |
| clipboard | `copy-text` | **yes** |
| reveal | `pick-target`, `reveal-shortcut`, `open-web-link` | no |
| mutate | `state-save`, `state-save-checked` | **no** |
| native | `native-source-*`, `resolve-dropped-targets` | no |
| delegate | `delegate-wave` | no |

### A launcher does not write project state — argued, not assumed

**Against granting it.** The launcher is transient: it closes on blur, has no draft, no undo and no
conflict UI. A write from it is unrecoverable the moment focus moves. `state-save-checked` rewrites
the **same document a real workspace surface may be editing**, and the launcher is the one surface
the creator will have forgotten about by the time they notice. Reading stale state is harmless;
*writing* stale state is destructive — the optimistic-concurrency check makes a write safe only
against a concurrent writer, not against the writer being a surface with no way to take it back.

**For granting it.** The optimistic-concurrency check means a stale write is refused rather than
applied, so it is not inherently unsafe, and a launcher that could toggle a todo or mark an item
done would be more useful.

**Decided against**, on the asymmetry: the read half is what makes the feature work, the write half
buys a capability the creator has not asked for, and the failure mode of being wrong is lost work
rather than a missing convenience. This is recorded so it can be revisited deliberately.

**Copy text is granted; activating something on the desktop is not.** Those were one group until
this round, and grouping them would have handed a text box a file manager. `reveal` is now its own
capability.

---

## 5. The repeat press

Pressing Alt+A again previously **closed** the overlay, and the overlay's own already-open path only
refocused the window — so either way the project received no event, and the creator had nothing to
clear their line on. Now the chord **re-invokes**: the window is not reloaded and not re-placed (that
would discard a half-typed command), and the host sends the invoke again so the project can clear
itself. The host cannot clear a project's input — it does not know what one is. Escape still
dismisses; a new unit test asserts the invoke count rises by one and the URL is unchanged.

---

## 6. Driven verification, and exactly what it does not cover

Run against a real Papers, with two real bound projects — one declaring a command surface, one not —
and the **non-declaring** one left as the active tab, which is the creator's reported arrangement.
`tests/e2e/launcher-target.e2e.ts`, 4/4 passing:

- the launcher loads the **declaring** project with the mode marker, and never the front tab's;
- with only a non-declaring project open, the chord **refuses, names that project**, and **no overlay
  window is created**;
- with both open and the non-declaring one active, the answer does not change;
- `state-load` reaches the project's own handler and returns its real document — **the reported
  guard error is gone** — `launch-shortcut` and `copy-text` are admitted, and `state-save-checked` is
  refused with *"not available to this kind of project surface"*.

For `launch-shortcut` the assertion is that the **project's own error** comes back
(*"shortcut was not found"*), with a target that does not exist, so no test launches anything on the
creator's machine.

### Not verified — this needs a person at the machine

**That the invoke the host issues actually reaches the page.** In the automated harness the host's
send **is** issued (counted directly, twice per double press) and the overlay preload's relay **is**
registered (confirmed through the context bridge), yet the page never receives the payload. That was
reproduced with a direct `webContents.send` **outside the product path entirely**, so it is a
property of that environment and not of the launcher. The unit tests cover the host half and say
nothing about the wire.

Evidence that it works in the product: Lane 3 observed the *second* press delivering no invoke, and
the creator sees the launcher open and take a typed character — neither is possible if the first
invoke never arrives. So the round's own bar — *type, see it, Enter, it runs* — is **not**
established by this round for the delivery half. It needs the creator to press Alt+A twice at the
machine.

A test-only flag (`PAPERS_TEST_INVOKE_CHANNEL=1`) publishes the chord's own open path and disables
blur-dismiss, which is correct host behaviour an unattended machine cannot satisfy; it is absent
from any normal build.

---

## 7. Housekeeping

18 files: 2 new modules, 1 new e2e file, 3 new unit test files, 12 modified. Working tree clean. Six
temporary diagnostic markers added while chasing the delivery question were all removed before the
commit, and `src/preload/backpackProject.ts` was restored byte-exact after being used as a probe
(`git status` clean on it). No leftover test Electron processes; the creator's six Papers processes
and `proximad` untouched. `Papers-3` not pushed; this branch not pushed at all.
