# Window identity: what Windows actually gives you

**Lane 4 · subject: window layouts that stay honest · round 1 — identity only**

**Authored** 2026-09-14 · **Papers Source** `D:\Letters\MatTroiSeConMoc\Products\Papers\Source`
(`Futahua/Papers-3`), branch `lane4-window-identity` cut from `9a839eb`, working tree clean,
**not merged, no source modified**. **Record repo** `D:\Letters\MatTroiSeConMoc\LongHorizon`.

**No removal, no retirement, no auto-tracking was built.** This round measures and proposes
identity, because the design's own hard gate says identity must land first and this round is
where I found out whether the gate's premise is even true.

---

## 0. What this round concluded, in five lines

1. The design's safety premise **reproduces exactly**: a live, healthy, non-elevated window
   becomes unusable to the shipping helper when only its title changes, and becomes usable
   again when the title changes back. Five independent identity paths today are title-keyed
   or title-dependent, not two.
2. **`SetProp`/`GetProp` as the design specifies it does not work.** Passing a string pointer
   stores a *pointer*, and the next reader in any process dereferences freed memory. I
   reproduced an access violation. A corrected mechanism (a global atom stored as an integer)
   does work and I verified it across real process boundaries.
3. **A tag is not enough anyway**, and is the wrong primitive for this feature: a Papers-owned
   tag cannot be assumed present on the windows the creator already has open, and cannot be
   re-derived by a restarted helper on a window it never tagged. The design's Stage 0 premise
   ("trusted native layer attaches it to the exact top-level HWND") is unachievable here.
4. **Windows already gives a sufficient identity, and it does not involve storing an HWND as
   authority.** Measured: `bootId + PID + process creation time + window class` is stable
   across helper and Papers restarts on the same boot, changed by a process restart, and
   necessarily changed by a reboot. The HWND is required to *separate two windows of one
   process* — which is the common case, not an edge case: the creator's Chrome has two
   top-level windows in one process right now.
5. So the primitive is: **a persisted HWND hint accepted only when corroborated by
   `bootId + PID + process creation time + class` on the same live HWND** — and where the
   corroboration cannot be performed, refuse rather than guess.

---

## 1. Baseline, measured

`npm test` from the source root, on `lane4-window-identity` @ `9a839eb`:

```
 Test Files  98 passed | 1 skipped (99)
      Tests  942 passed | 4 skipped (946)
   Duration  5.38s (transform 5.52s, setup 0ms, import 10.40s, tests 19.36s, environment 9ms)
```

Exact host claim (`942 passed / 4 skipped`, about 5.4s) confirmed, not assumed.

Environment the probes ran in: boot `2026-09-14T00:27:55.5Z`, unelevated shell, session 1,
28–35 visible top-level windows depending on what the probes had open.

---

## 2. How identity, membership and retirement work TODAY

Two different identity systems exist, in two different repositories, and the design's gate
concerns both. Only one of them is on this machine.

### 2.1 The live capability layer (Papers — verified here)

| Where | What it is |
| --- | --- |
| `resources/window-helper/window-helper.ps1:213-216` | `Get-WhIdentityKey` = `"$Hwnd\|$PidValue\|$Title"` |
| `resources/window-helper/window-helper.ps1:235-245` | `New-WhSessionToken` — token minted per that key, reused for an unchanged key, keyed by `HWND\|PID\|exact title` |
| `resources/window-helper/window-helper.ps1:268-286` | `Test-WhTokenIdentity` — revalidates `IsWindow` **and** `PID` **and** **exact title** before every observe and mutation; line 282 is the title comparison, line 283 returns `denied` |
| `resources/window-helper/window-helper.ps1:424`, `:446` | `list` and `hover` both mint tokens from the title-bearing key |
| `resources/window-helper/window-capability.ps1:488-510` | `Get-WhWindowObservation` — exposes title, PID, **processPath**, bounds, state. No process creation time, no class on the wire |
| `src/main/windows/windowCapabilityService.ts:500-516` | persisted descriptor = `{version:1, executableFingerprint, title}`; `executableFingerprint` is a hash of `processPath` |
| `src/main/windows/windowCapabilityService.ts:887-901` | `resolvePersisted` — exact `executableFingerprint` **AND exact title**, `0 matches → missing`, `>1 → ambiguous`, `1 → bind` |

So the design's §1.2 and §1.3 are **accurate**, with one addition it misses: the miss path in
`windowCapabilityService.ts:275` rejects an observation whose title is empty, and
`window-capability.ps1:706` requires at least two identical title samples for capture. Title is
load-bearing in five places, not two.

### 2.2 The membership and retirement layer (As-you-Go — NOT on this machine)

The design's §1.1, §1.4, §1.5 and Stage 3 point at
`as-you-go-backpack@8000c88`, `public/workspace-model-20260730b.js` and
`public/app/window-layout-runtime.js`. **No as-you-go-backpack checkout exists on this
machine** (`Products/` holds `Apers, Companion, DelegateWave, Hermes, Papers, proxima,
reference`; no `workspace-model-20260730b.js` anywhere within four levels of the workspace
root). **I did not verify those claims and I am not treating them as established.** Every
statement in this document about membership, `removeClosedWindowFromAllLayouts`, and
two-miss retirement is therefore **unverified by me** and does not appear in my findings.

This matters for scoping the next round: the identity change has a Papers half that is
buildable and testable here, and a Backpack half that is not on this machine at all.

---

## 3. What Windows actually gives you — measured, not recalled

Probe scripts and raw outputs: `probes/` beside this document (`probe-0*.ps1`,
`out-probe0*.txt`). Every read/write in the tag experiments happened in a **fresh OS
process**, which is the helper-restart condition rather than a simulation of it.

### 3.1 The three mutations that matter

| Signal | Title change | Helper/Papers restart, same boot | App process restart | OS reboot |
| --- | --- | --- | --- | --- |
| **HWND** | unchanged | unchanged (owned by the app's process, not Papers) | **new** (old one dies) | **all gone** |
| **PID** | unchanged | unchanged | **new** (or reused number) | **all gone** |
| **Process creation time** | unchanged | unchanged | **new** (100 ns resolution) | **all gone** |
| **Process path / executable** | unchanged | unchanged | usually same path | usually same path |
| **Window class** | unchanged | unchanged | usually same | usually same |
| **Title** | **changes** | unchanged | changes | gone |
| **Papers-owned tag** | unchanged | unreadable (see §4) | destroyed with the window | gone |

Measured directly: `probe-02` (tag survives 5 title mutations; HWND and PID unchanged),
`probe-03` (derived key unaffected by title change, identical when recomputed in a different
process), `probe-10` (same key from three separate helper processes).

### 3.2 The load-bearing measurement: two windows of ONE process

This is the fact that decides the primitive, and it is not hypothetical.

From `probe-04`, against the creator's live Chrome — a new window launched and then closed by
the probe, nothing pre-existing touched:

```
distinct chrome.exe PIDs owning windows : 2
  pid=22888 windows=1 hwnds=0x11119C created=11:19:36
  pid=32060 windows=2 hwnds=0x2513EE,0x50B8E created=00:29:32
FINDING: one Chrome process owns 2 top-level windows.
         PID + process creation time + class name is IDENTICAL for both.
         Only the HWND separates them.
```

`probe-03` reproduces the same thing under control, and `probe-10` shows it on two Notepad
windows of one process deriving a byte-identical key
(`…|51372|2026-09-14T16:09:25.5350523Z|Notepad` twice).

**Consequence:** any identity that is "PID + creation time + class" silently collapses
Chrome's two windows into one member. The HWND must be part of the identity. That is a
measured requirement, not a preference.

### 3.3 HWND reuse — what I could and could not show

`probe-03` destroyed four probe windows and created replacements; **no replacement inherited
the dead window's HWND** in that sample, and none reproduced the dead window's derived key.

I am **not** claiming HWNDs do not get recycled. They demonstrably do, over time, in a 32-bit
handle space. The finding is the opposite of reassurance: it is precisely because HWND reuse
is real that a bare HWND must never be authority. The mitigation is not "hope reuse doesn't
happen" — it is that corroboration makes a recycled HWND *provably* a different instance
(different PID, different creation time), which turns the hazard into a typed terminal result.

---

## 4. The design's own tag mechanism fails — and a corrected one works

The design's Stage 0 prefers "Papers assigns a random opaque `windowInstanceId` … trusted
native layer attaches it to the exact top-level HWND … candidate mechanism: `SetProp`/`GetProp`".
The Status block records that this was answered at `825154a`: "a window property carrying the
tag in its value survives the writer process's death and is destroyed with the window, while a
pointer-valued property and `GWLP_USERDATA` each fail for a recorded reason."

**I could not reproduce the claim that a window property carrying the tag in its value
survives the writer process's death.** What I measured is the opposite. I want to be exact
about what this does and does not show, because the distinction is the whole finding:

- `SetPropW` takes an `IntPtr`. There is no overload that copies a string. Whatever that
  pointer points at is the *caller's* responsibility, and the property store simply holds the
  number.
- Therefore a tag stored as "a string" is a pointer into the **writer's** address space, and
  the moment the writer exits, every later reader in every process is dereferencing freed
  memory. That is not a lifetime limit on the tag; it is a memory-safety defect.
- What I did **not** separately test is a property whose value is a pointer into
  user32-owned memory that outlives the writer. I could not construct one through this API,
  which is itself the point: the API gives you nowhere safe to put a caller-owned string.

### 4.1 The failure, reproduced

Storing `Marshal.StringToHGlobalUni(...)` leaves that pointer in the window's property store:

```
[PASS] SetProp with a caller-allocated pointer succeeds   pointer=0x22ABE038620 text=DANGLING-VALUE
[PASS] the stored value is a memory address, not a portable identifier   raw=0x22ABE038620 looksLikeAtom=False
[PASS] safe read REFUSES a non-atom value instead of dereferencing it   tag=<non-atom-value:0x22ABE038620>
[PASS] dereferencing the stored pointer after the writer died           Fatal error.
       System.AccessViolationException: Attempted to read or write protected memory.
         at System.SpanHelpers.IndexOfNullCharacter(Char*)
         at System.Runtime.InteropServices.Marshal.PtrToStringUni(IntPtr)
```

The writing process had exited. The *reading* process died. On the very first run this took
out my probe process, which is how the defect announced itself.

### 4.2 A mechanism that does hold up

Replacing the pointer with a **global atom** gives a pointer-free reading path — the stored
value is an integer the system resolves:

> `GlobalAddAtomW("PapersProbe.InstanceId.<guid>")` → store the returned `ushort` via
> `SetPropW(hwnd, "PapersInstanceId", (IntPtr)atom)` → any process reads it with
> `GetPropW` + `GlobalGetAtomNameW`.

Measured (`probe-02`, 16/17 verdicts PASS; the one FAIL was my own assertion bug, corrected):

```
[PASS] a NON-OWNER process can tag a foreign HWND                       atom=OK atomValue=49312
[PASS] tag readable by a FRESH process (different PID)                  tag=PapersProbe.InstanceId.88493dfc…
[PASS] a SECOND fresh process reads the identical tag                   tag=PapersProbe.InstanceId.88493dfc…
[PASS] tag survives 5 title changes on the same HWND
[PASS] a fresh process rediscovers the tagged window by enumerating the desktop
[PASS] HWND is dead once the owning process dies                        alive=False
[PASS] tag is unreadable once the owning process dies                   tag=(empty)
[PASS] dead window disappears from a fresh enumeration
```

Two Windows surprises found while doing this, both of which a naive implementation would get
wrong:

- **A small integer is indistinguishable from an atom by range.** `GetPropW` returning `4660`
  resolves through `GlobalGetAtomNameW` to the string `"#4660"` — Windows synthesises integer
  atoms. A reader that trusts "0 < value ≤ 0xFFFF ⇒ atom" will accept a raw integer as a
  valid tag. The reader must additionally require the resolved string to carry the
  `PapersProbe.InstanceId.` prefix and reject anything else.
- **`GlobalGetAtomNameW` returns empty for a dead window**, so "tag unreadable" and "tag
  absent" are the same observation. Death cannot be distinguished from never-tagged by the
  tag alone — which is fine for identity (both mean "not this instance"), but must not be
  read as proof of destruction.

### 4.3 Why the tag is the wrong primitive regardless

Even with the atom mechanism working, a Papers-owned tag does not solve this feature:

- **It cannot be assumed present.** The creator's Chrome, Obsidian and VS Code windows were
  carrying no tag of any kind (`probe-01`: "named-app windows carrying the probe tag: 0 of 5").
  A tag only exists on windows Papers has already tagged.
- **It cannot be re-derived after a restart on a window Papers never tagged in this session**
  without persisting the HWND — which the design forbids and which §3.3 says is unsafe alone.
- **Tagging every eligible window on sight is a different, much larger feature** (it means
  writing properties onto the creator's live application windows), and the design's §5
  scope control does not authorize it.

So the tag mechanism is a legitimate *hardening* option for windows Papers has already bound,
but it is **not** the identity primitive. It cannot be, because the feature's job starts with
windows that have no tag.

---

## 5. The identity primitive I propose

### 5.1 What is stored

Per layout member, alongside the existing descriptor:

```
member.windowInstanceKey = {
  bootId,            // this Windows session's boot instant, canonically serialized
  hwnd,              // the window handle value, as a hint
  pid,               // owner process id, at bind time
  processCreatedUtc, // owner process creation time, at bind time
  className          // GetClassName at bind time
}
```

`descriptor.title` stays, as **display metadata only**, exactly as the design already says.
`descriptor.executableFingerprint` stays as a display/eligibility hint. Neither is identity.

### 5.2 What is compared

To accept a slot as the same instance, all of the following must hold **in one atomic check
against one live HWND**:

```
Test-WhWindowAlive(hwnd)                       — the handle is still a window
AND GetWindowThreadProcessId(hwnd) == pid      — it is still the same process
AND ProcessCreationTime(pid) == processCreatedUtc
AND GetClassName(hwnd) == className
AND CurrentBootId() == bootId
```

and only then is the window's *current* title read, as fresh display metadata.

The one addition the wire protocol needs is a way to corroborate the last two clauses, because
the helper today exposes neither. `Get-WhWindowObservation`
(`window-capability.ps1:488-510`) must additionally expose:

```
windowClass              — GetClassNameW, already declared at window-capability.ps1:90
processCreatedUtc        — from a process handle (GetProcessTimes), not from WMI per call
bootId                   — per helper session; the helper's parent process is Papers, so
                           it can be supplied once at startup, not recomputed per window
```

`Get-WindowThreadProcessId` and `GetClassName` are already P/Invoked in this file; the
creation time is the only genuinely new native call, and it must be obtained by opening the
process with `PROCESS_QUERY_LIMITED_INFORMATION` (which succeeds unelevated for ordinary
non-elevated applications — verified: every real window measured here, including the creator's
Chrome, Obsidian, VS Code and Papers, yielded a creation timestamp).

### 5.3 Why boot id is included

`bootId` is redundant against a live window (a window's process cannot predate the boot) but it
is what makes a **dead** record honest. After a reboot, the old record's `bootId` differs, so
the member is `gone` on the first enumeration without Papers having to reason about uptime,
wall-clock or restart detection — which Stage 15.6 explicitly forbids. It is obtained from
`Win32_OperatingSystem.LastBootUpTime` (measured on this machine as
`2026-09-14T00:27:55.5Z`, with every live process created after it).

### 5.4 Ambiguity, and the refusal rule

The design's Stage 5.1 says "ambiguous should not occur unless the tag mechanism itself is
broken". **That is false, and it is false in the ordinary case**, per §3.2. Two Chrome windows
of one process have identical PID, identical creation time, identical class, identical
executable. Without the HWND, that is a genuine, everyday ambiguity, not corruption.

With the HWND in the key the ambiguity disappears — a live HWND resolves to exactly one
window — so the resolution outcomes become:

| Observation | Result | Meaning |
| --- | --- | --- |
| stored HWND is alive and all four corroborations match | **bound** | same exact instance |
| stored HWND is not a window | **window-gone** (terminal) | the instance died |
| stored HWND is alive but any corroboration differs | **instance-mismatch** (terminal for the stored instance) | the HWND was reused by a different window; never grant authority over the replacement |
| `bootId` differs | **window-gone** (terminal) | a different Windows session |
| creation time or class unreadable (e.g. elevated target) | **denied / unsupported** (never terminal) | refuse; do not bind, do not retire |
| corroboration succeeds but the *same* key appears on two live HWNDs | **protocol error**, bind neither | fail closed, per design Stage 5.1 |

The last row is the design's own integrity rule and it stays. Note what changed: the
"ambiguous" case moved from "should not occur" to "occurs whenever the HWND is dropped", and
the refusal rule is what keeps that from being resolved by guessing.

**This is the "refuse, never coerce" line.** An unreadable creation time is `denied`, not
"treat PID as good enough". A reused HWND is `instance-mismatch`, not "rebind to the new
window that looks similar".

---

## 6. What I would build first, and what I refuse to build until identity is proven

**Build first — narrow, reversible, and provable without touching anything the creator uses:**

1. **A helper-level identity predicate**: add `windowClass`, `processCreatedUtc` and `bootId`
   to `Get-WhWindowObservation`, and a `Test-WhWindowInstance($key)` gate that performs the
   §5.2 check atomically before observe/mutate. This is the single change that makes a title
   change stop killing a healthy capability, and it is testable entirely with probe-owned
   windows plus the existing fake seams.
2. **Replace the token key** `HWND|PID|title` with the instance key, so line 282's title
   comparison disappears. Regression test: the `probe-09` sequence, asserted.
3. **Typed outcomes** — `window-gone` / `instance-mismatch` / `session-token-unknown`, because
   destructive removal needs a protocol fact strong enough to justify it, and today's `missing`
   conflates all three (`window-helper.ps1:274-275`).
4. **The descriptor/member field and its migration**, once the Backpack repo is available and
   the Papers half is proven.

**Refuse until identity is proven, on the creator's machine, with their windows:**

- Any change to retirement, pruning or "remove invalidated processes immediately". This is the
  design's own hard gate and this round strengthens it rather than discharging it: I found
  *five* title-keyed paths, not two, and I found that a healthy `observe` fails on a title
  change and then *succeeds again when the title changes back* — the exact intermittency that
  makes a destructive consumer dangerous rather than merely broken.
- Auto-tracking. It needs the eligibility classifier, and §7 below shows the classifier's
  behaviour is not what the design assumes.
- Anything that writes to the creator's real layouts, or that moves, hides or re-orders a
  window the creator is using.

---

## 7. Findings that are not identity but change the plan

These came out of the same measurements and belong in the ledger whether or not they get
actioned this round.

1. **The eligibility classifier does not capture what the design's test corpus claims.**
   `probe-09` showed the real helper **lists two top-level windows for a single Notepad
   process** — Windows 11's tabbed Notepad exposes one top-level window per open tab under one
   PID, so "close tab A" destroys a top-level window while the process lives on. Stage 14 has
   no test for this, and Stage 7.4's stabilization window cannot distinguish it.
2. **`PseudoConsoleWindow` is task-worthy by the current predicate** (`probe-03`, `probe-03`'s
   replacement windows): it is visible, unowned, not cloaked, and carries no
   `WS_EX_TOOLWINDOW`/`WS_EX_NOACTIVATE`. The predicate's own comment
   (`window-capability.ps1:730-742`) claims "visibility plus a title is not enough (the
   creator's picker leaked system surfaces)" — this is a live counterexample, and it is a
   console window, i.e. exactly the kind of surface that would appear and vanish during
   ordinary CLI work.
3. **The helper lists the *same* process three times.** `probe-05` and `probe-06` both show my
   probe shell (one process, one console window) appearing as three separate list entries.
4. **A listed window can carry a NULL `processPath`.** `probe-06`: "pid=41128
   title='sloptop_engine.ahk' state=normal" with no path. `executableFingerprint` is a hash of
   `processPath` (`windowCapabilityService.ts:505`), so that window's fingerprint is a hash of
   the empty string and it can never be re-resolved by descriptor. Any member added from it is
   permanently unrebindable through the current path.
5. **The helper's owned-window clause was not confirmed to accept a WinForms-owned window**
   (`probe-06`, `probe-08`): a probe window passed every clause I evaluated individually
   (visible, unowned-clause satisfied, class fine, ex-style clean) and was still not listed.
   I did not isolate the cause. This is a live question about what the auto-tracker will miss,
   and it is stated here as unresolved rather than explained away.
6. **Prior art on this machine disagrees with the design in a useful way.**
   `D:\Letters\MatTroiSeConMoc\PowerToys-MWB-FreeLayout` contains the PowerToys **Workspaces**
   module, which solves the same problem by persisting `{name, title, packageFullName,
   commandLineArgs}` per app and matching live windows **by title, disambiguated by PID**
   (`WorkspacesSnapshotTool/SnapshotUtils.cpp:112-113`, comment: "searching for the window with
   the same title but different PID"). It can afford title-keyed identity because it
   *relaunches* applications to rebuild a workspace. Papers must not relaunch (design §5:
   "no automatic app launching"), so it needs the identity PowerToys never needed. That is a
   real difference in requirements, not a difference in quality.

---

## 8. What I could not prove

Stated plainly, because a claim nobody can re-run is not evidence.

1. **The As-you-Go half of the baseline.** `as-you-go-backpack@8000c88` is not on this
   machine, so the design's §1.1, §1.4, §1.5 and the Stage 3 retirement claims about
   `workspace-model-20260730b.js` and `window-layout-runtime.js` are **unverified by me**. My
   §2.1 statements are verified at the lines given; my §2.2 is a pointer, not a finding.
2. **OS reboot.** I did not reboot the creator's machine and would not. The reboot row of §3.1
   is deduced from two measured facts — process creation times are boot-scoped (all live
   processes postdate `2026-09-14T00:27:55.5Z`) and process death destroys windows
   (`probe-02`, `probe-03`) — not from a reboot. The deduction is sound; it is still a
   deduction, and §5.3 is designed so that a wrong deduction becomes a visible `gone` rather
   than a wrong `bound`.
3. **Papers restart while the app survives.** I did not restart the creator's running Papers.
   I substituted three separate helper processes (`probe-10`), which exercises the same
   property — a fresh process with no shared memory recovering the same instance — and is
   strictly the harder case. It is not literally a Papers restart.
4. **Elevated targets.** Nothing here was elevated and I did not create an elevated target.
   The claim that an elevated window's creation time is unreadable, and that this must produce
   a typed `denied`, is **untested**; it is a design requirement in §5.4, not a measurement.
5. **HWND recycling.** Not observed in a four-window sample. Not proven absent, and §3.3
   explains why the design must not depend on its absence.
6. **The owned-window rejection** (§7.5) has a reproduction but no root cause.
7. **`probe-02`'s remaining FAIL** was my own assertion error (I asserted a window carried no
   tag after my own earlier step had tagged it). Corrected in the script; the corrected
   assertion is not re-run in the saved output, and I am saying so rather than editing the log.

---

## 9. Probe inventory (all committed beside this document)

| File | What it measures | Result |
| --- | --- | --- |
| `win-identity-lib.ps1` | shared P/Invoke + per-PID process facts cache | instrument; first version cost 8.7 s per enumeration and was fixed |
| `probe-01-identity-signals.ps1` | what identity Windows exposes per visible window | 5 named apps, all `Chrome_WidgetWin_1`, 0 carrying any tag |
| `probe-02-tag-mechanism.ps1` | the `SetProp` mechanism across real process boundaries | pointer form crashes a reader; atom form PASSes 16/17 |
| `probe-03-marker-mechanics.ps1` | derived-key stability, two windows of one process, HWND reuse | 9/9; one process → one key (collision reproduced) |
| `probe-04-chrome-multiwindow.ps1` | one Chrome process owning two top-level windows | confirmed on the creator's live Chrome; window opened and closed by the probe |
| `probe-05-shipping-helper-identity.ps1` | driving the real helper over its JSON-lines protocol | instrument validated; target-selection lesson recorded |
| `probe-06-eligibility.ps1` | what the real helper's `list` actually contains | 14 of 35; NULL `processPath`; classifier gaps |
| `probe-07-launch-shape.ps1` | whether launch shape changes helper visibility | no — all four shapes see the same 35 windows |
| `probe-08-owned-vs-unowned.ps1` | owned-window clause | unresolved (§7.5) |
| `probe-09-title-sensitivity.ps1` | **the gate's claim, on the real helper** | **reproduces; 5 PASS 2 FAIL by design** |
| `probe-10-helper-restart.ps1` | identity across three separate helper processes | 9/9 |

**Safety of the probes:** no pre-existing window was moved, hidden, re-ordered, retagged or
closed. Every window written to was created by the probes and destroyed by them. The only
creator-visible side effect was one extra Chrome window in `probe-04`, opened with
`chrome.exe --new-window about:blank` and closed by the probe; all pre-existing Chrome windows
were verified still present afterwards. `Papers` itself was never restarted, and the live
helper found running afterwards (pid 31912, parent `Papers.exe`) was confirmed to be the
creator's own, not a leftover of mine. The Papers source tree is unmodified.

**One instrument lesson worth carrying:** in `probe-02`'s section D I killed the scratch
process and observed that the window and its tag both died. That conflates two events — the
Windows Forms window was *owned* by its process, and an owned window is destroyed with its
owner. The lesson is useful in its own right (an owned window's lifetime is bounded by its
owner's), but it means section D measures "window destroyed" and not "process alive, window
gone". The pointer hazard in §4.1 is unaffected: it was written by a non-owner process and read
after that writer exited, which is exactly the scenario claimed to be safe.

**Credit where the record already had it:** the design's safety gate is correct, and the Status
block's reviewer items were the reason this round knew which experiment was decisive. Where I
contradict it — the `SetProp` tag, and "ambiguous should not occur" — I have said so with the
measurement attached rather than around it.
