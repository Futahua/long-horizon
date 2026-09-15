# Window identity, round two: the reuse hole, the marker, and what refused

**Lane 4 · round two · answers the reviewer's two BLOCKs and its design**

**Authored** 2026-09-15 · **Record repo** `D:\Letters\MatTroiSeConMoc\LongHorizon`, branch
`codex/reviewer-send-verification`, round one pushed as `672c9cb`.
**Papers Source** `D:\Letters\MatTroiSeConMoc\Products\Papers\Source` — branch
`lane4-window-identity` still at `9a839eb`, working tree clean, **0 files changed**. No source
was written this round either.

**Host baseline, re-run and green:** `98 passed | 1 skipped` files, **942 passed | 4 skipped
(946 collected)**, 5.47s.

**Built this round:** nothing from the prohibited list. No retirement, no auto-tracker, no
legacy migration, no destructive removal, no enumeration-miss-as-death, no title/PID/ordinal
fallback. Everything below is measurement, a marker primitive, and a scope definition.

---

## 0. The two blocks, answered

### Block 1 — "bootId + PID + creation + class is not exact instance identity" — **ACCEPTED, and I could not force the counterexample**

The reviewer is right that the four corroborators do not constitute identity: they are all
properties of the *process* and the *class*, and a window is neither. I also owe a correction
to my own round one: I wrote that a recycled HWND is "provably a different instance (different
PID, different creation time)". That is only true if the replacement is in a different process.
The reviewer's case — same process, same class, new window object — defeats all four at once.

What I did about it, in order:

1. **Tried to force it through WinForms** (`probe-11`): 1 adjacent pair plus 12 churn cycles plus
   40 attempts aimed at a killed slot. **Zero recurrences.**
2. **Tried to force it at the allocator** (`probe-12`, raw `CreateWindowExW`/`DestroyWindow`,
   no framework): 40 cycles, then 60 adjacent pairs, then 80 attempts aimed at a killed slot.
   **Zero recurrences.**
3. **Tried every plausible reuse shape** (`probe-13`): 60 adjacent cycles with the message queue
   pumped after each destroy; batch-allocate then batch-destroy in forward, reverse and
   middle-out orders then reallocate; and 20 held windows with 200 churn cycles. **Zero
   recurrences in every shape.**
4. **Measured the rate directly** (`probe-14`): **20,000 create/destroy cycles, 20,000 distinct
   HWND values, 0 recurrences.** Over 400 consecutive allocations the stride was **exactly
   `+0x10000` in 399 of 399 cases**, and across all 20,000 allocations the low 16 bits were
   **pinned to a single value** (`0x2988` in that run, `0x3D7E` in another).

That last measurement is the explanation. An HWND whose low word is fixed and whose high word
increments by one per allocation is a *table index being handed out forward*, not a free-list
pop. Freed slots are not returned to a LIFO pool that the next allocation takes from; the index
only recurs when the space is re-entered, which needs the order of tens of thousands of
allocations on one desktop.

**So: not forced here, on this machine, in ~20,400 attempts across four probes.** I am recording
that as *not forced*, not as *cannot happen*, exactly as the reviewer instructed. Microsoft
documents handle recycling, the index space is finite and does wrap, and a machine that has been
up long enough with enough window churn will re-enter it. The reviewer's scenario is real; I
could not make it happen on demand, which is a statement about my harness, not about Windows.

**Where that leaves the invariant.** The exact invariant as posed — *a replacement object
occupying the same numerical HWND cannot inherit the enrolled generation marker* — is proven
in a stronger form than the collision would need, because it does not depend on forcing the
collision at all:

```
[PASS] INVARIANT: an un-enrolled replacement never carries the destroyed window's marker
       60 windows enrolled then destroyed
       2,400 replacement windows inspected
       markers inherited: 0
```

A window's property store is destroyed **with the window** (`probe-02`: `GetProp` on a dead
HWND returns nothing; `probe-12`: marker absent on the dead handle). A replacement object
therefore starts with no marker regardless of which slot it lands in. The invariant holds by
construction, and I verified it over a 2,400-window population rather than over one lucky pair.

**What the marker buys, stated exactly.** It is the only mechanism that answers *"is this the
same window object Papers enrolled?"* rather than *"does this look like the same process and
class?"*. On a live window, a present marker is real evidence of object identity. Its **absence
is not evidence of anything** — measured in `probe-11` section D:

```
marker on a dead HWND          : (empty)
marker on a fresh un-enrolled window in the same process : (empty)
```

Identical observations. So absence maps to **UNVERIFIED**, never to `gone`. That is the reviewer's
instruction and the measurement agrees with it independently.

### Block 2 — "a Papers-owned tag is the wrong primitive regardless" — **WITHDRAWN, too broad**

The reviewer is right and I was wrong. I proved that the **pointer-valued implementation** was
broken, and then over-generalised from it to the mechanism. Those are different claims and I
conflated them.

A correctly represented marker — fixed property key, scalar nonce value, never a pointer — is
not the thing I falsified. It is a distinct, working mechanism that closes exactly the hole the
corroborators leave open, and this round I measured it rather than reasoning about it.

---

## 1. Bitness: checked before choosing the representation, as instructed

`probe-15`, using the real 32-bit Windows PowerShell at `SysWOW64\WindowsPowerShell\v1.0\`
and a 64-bit shell, against a window owned by a 64-bit server process:

```
--- 64-bit writer, both readers ---
  DRIVER bits=64 op=enrol ok=True win32error=0 atom=49561 nonce=41001
  DRIVER bits=64 op=read  marker=PapersProbe.Gen.41001
  DRIVER bits=32 op=read  marker=PapersProbe.Gen.41001      <- same value
--- 32-bit writer, both readers ---
  DRIVER bits=32 op=enrol ok=True win32error=0 atom=49489 nonce=41002
  DRIVER bits=64 op=read  marker=PapersProbe.Gen.41002      <- same value
  DRIVER bits=32 op=read  marker=PapersProbe.Gen.41002
--- the raw stored value as each bitness sees it ---
  DRIVER bits=64 op=raw value=0xC151 asInt64=49489
  DRIVER bits=32 op=raw value=0xC151 asInt64=49489
```

The representation survives WOW64 in both directions, and both bitnesses read the *identical
integer*. The reason is structural: the value is **data on both sides, never an address**, so
there is no pointer-width question to get wrong.

Two representation rules fall out of the measurements, and both are cases where the obvious
choice is wrong:

- **The value must be a named atom, not a raw integer.** `probe-02` measured that
  `GlobalGetAtomNameW(4660)` returns the string `"#4660"` — Windows synthesises names for
  integer atoms. A reader that accepts "any value ≤ 0xFFFF" therefore accepts a raw integer as
  a valid marker. The reader must additionally require the resolved name to carry the
  `PapersProbe.Gen.` prefix and reject everything else.
- **The nonce range should stay below `0xC000`.** Above that, values collide with the
  integer-atom range, where the system invents names rather than storing them. Nonces here are
  drawn from `1..32767` for that reason.

And the round-one hazard does not come back quietly: a 32-bit reader that wrongly dereferences
the scalar reports `op=deref OK text=` — an **empty string, not an exception**. It fails
*silently*, which is worse than the round-one crash. Any implementation that reads a marker as a
string pointer must be rejected at review, not tested for.

---

## 2. Integrity levels and UIPI: measured, including the refusal

`probe-16` reached a genuinely elevated window (an elevated PowerShell holding a form,
started with `-Verb RunAs`, which this machine permitted):

```
elevated process started: pid=61304
  incarnation: seq= readable=False created=09/15/2026 00:37:17 source=creationFiletime
  visible top-level windows owned by the elevated process: 1
    hwnd=0x92FAA SetProp ok=False win32error=5 readBack=
```

`win32error=5` is `ERROR_ACCESS_DENIED`. That is UIPI refusing the write, exactly as the
reviewer described, and the outcome is a **typed refusal with no marker written** — not a silent
no-op, and not a fallback to title or PID.

The important detail is *which* refusal came first in the other probe: in `probe-16` the elevated
window **was enumerable** and the write was refused, whereas in `probe-15` the elevated process
owned no enumerable window at all. Both are refusals, but they are different refusals and a
consumer must not conflate them. The design rule follows:

```
enumeration miss on an elevated-class target  -> UNVERIFIED
SetProp refused (ERROR_ACCESS_DENIED)         -> UNVERIFIED, with the refusal recorded
neither                                       -> never "gone"
```

Also measured, and this is the asymmetry that matters most for the `UNVERIFIED` state:

- `SetPropW` against **ordinary unelevated application windows succeeded 12 of 12**
  (`probe-15`, real Chrome/Obsidian/other windows — enrolled then un-enrolled by the probe, and
  `probe-22` confirms zero markers remain on any of 73 windows afterwards).
- `GetPropW` is **not** gated the way `SetPropW` is. A lower-integrity process can read a
  property it was refused permission to write.

So "no marker" can mean *never enrolled*, *enrolment was refused*, or *the window is gone*. Three
different states collapse into one observation. **That is precisely the case for an explicit,
visible `UNVERIFIED` state**, and it is why absence must never be read as death.

---

## 3. Process incarnation: the reviewer's hierarchy does not hold on this machine

The reviewer asked for `SystemBasicProcessInformation.SequenceNumber` where available, creation
FILETIME as fallback, never PID alone. I have to report an unhelpful answer, including a
correction to my own intermediate result.

**Correction first.** `probe-16` reported "SequenceNumber absent for 400 processes on build
26200". **That was wrong and I caught it before it reached this document.** The native call was
returning `STATUS_INFO_LENGTH_MISMATCH` (`0xC0000004`) because a 1 MB buffer was too small — the
call needed 1,809 KB — and my walk never ran. The zeroes were the absence of a *measurement*,
not the absence of a *field*. This is the same error class I flagged in round one (a probe
reporting its own failure as a finding), and the reason `probe-17` and `probe-18` re-ran with
the layout validated first.

**The corrected state.** `probe-18` grows the buffer until the call succeeds and then validates
the offsets against fields with independently known values before reading anything:

```
size=1024KB status=0xC0000004 needed=1809KB
size=2048KB status=0x00000000 needed=1809KB
final status : 0x00000000 (STATUS_SUCCESS)
entries walked      : 525
this process found  : False (pid 61496)      <-- the offset map is still wrong
```

The call now succeeds (2 MB is the working size; 1 MB is not), but my `UniqueProcessId` offset
does not locate this process, so the offset map is **not validated** and I will not name a field
from it. What the raw walk does show is a populated 32-bit field at offset `0xA8` for 524 of 525
entries, and three fields at `0xB8/0xC0/0xC8` all reading `61440` for every entry — which looks
like a constant, not an incarnation. **I am recording a location, not a name**, and the
SequenceNumber question stays open.

**What the record relies on instead.** The documented creation FILETIME, which is measurable
without any of this:

```
probe-17: 10 consecutive notepad incarnations -> 10 distinct creation FILETIMEs, 0 collisions
probe-16: 3 consecutive incarnations          -> 3 distinct, 0 collisions
```

**One honest weakness, from `probe-16` section C:** in an earlier run, **six** consecutive
incarnations produced **one collision** — two processes shared a creation timestamp to the tick.
It does not grant authority on its own (the HWND must still match, and a second window cannot
occupy the same slot while the first is live), but it is a measured weakness in the fallback and
it is recorded rather than assumed away. The fallback hierarchy the design should state is:
**creation FILETIME + HWND, with `SequenceNumber` used opportunistically if and when its location
is established on the target build** — not the other way round.

---

## 4. Class name is corroboration only — confirmed, and it is worse than "narrowing"

Measured in `probe-11`:

```
three distinct live windows of one process share one class name
  classes: WindowsForms10.Window.8.app.0.1403b24_r3_ad1  (x3)
  unique = 1 of 3
```

and in `probe-19`, on real applications: the creator's Chrome process `32060` owns two windows
that share PID, creation time and class, and a 22-window notepad process shares all three across
all 22. A class name is unique **per process**, not per window. It corroborates; it separates
nothing. The design must say that explicitly, because it is the clause most likely to be
mistaken for a discriminator.

---

## 5. Session scope

Measured (`probe-19`, `probe-22`):

- Every named application window reported a session id (`session=1` throughout), readable via
  `ProcessIdToSessionId` with no elevation.
- Distinct session ids across all processes on this machine: **`0, 1`** — so more than one
  session value is observable here, and session `0` genuinely appears (services). A naive
  "session must be non-zero" check would be wrong; the scope must compare session ids, not test
  them for truthiness.
- Two interactive logon sessions (`LogonType = 2`) are present, both started `07:28:09`.

The fence the reviewer asked for is adopted as stated: **a different session id must never
cross-bind.** Same-session RDP reconnect preserving the instance is *definitional* for a
reconnect, so the fence is correct in that direction.

**Not measured:** an actual RDP reconnect, or a second simultaneous session. `probe-22` states
this plainly rather than asserting the behaviour.

---

## 6. bootId: defined exactly, and framed as the reviewer requires

**Definition used:** `bootId` is the **system boot instant**, taken from
`Win32_OperatingSystem.LastBootUpTime`, serialised as local ISO-8601 with offset. Measured on
this machine as `2026-09-14T00:27:55.5Z`, with `explorer.exe` starting 16 s later and every live
process created after it.

**It is a scope fence, not proof of death.** The reviewer's requirement is adopted verbatim, and
the measurements show why it matters. The transitions, and their honest status this round:

| Transition | Status | What is known |
| --- | --- | --- |
| Full restart | **not performed** | Old window objects cannot survive it; `bootId` changes, so every old record leaves scope. Not measured here. |
| Fast Startup shutdown | **not performed** | **Disabled on this machine** (`HiberbootEnabled = 0`), so it is unmeasurable here rather than merely unmeasured. Worth stating: a `bootId` taken from `LastBootUpTime` *does* change across Fast Startup, which is the property that keeps the fence sound on machines where it is enabled. |
| Sleep (S3) | **not performed** | **Available** (`powercfg /a`: "Standby (S3)" available; S1/S2 unavailable). The machine sleeps; I chose not to wake it into an unattended session. |
| Hibernate | **not performed** | **Not available on this machine** (`HibernateEnabled = 0`, `powercfg /a`: "Hibernation has not been enabled"). |
| Suspend/resume within a session | **weaker stand-in measured** | `probe-19` section G: a full identity scope re-verified as `Verified=true` with no mismatches and nothing unverified across a 75 s delay, with `bootId` unchanged. A delay is **not** a substitute for suspend and is not claimed as one. |

The point of the fence framing is that it never has to prove a window died. An out-of-scope
record produces `UNVERIFIED` or `gone` by *scope comparison*, so an unmeasured transition cannot
become a wrong binding — which is exactly the failure mode the reviewer was guarding against.

---

## 7. The acceptance exercise, and the boundary it found

`probe-19` and `probe-21` against the real applications, with the helper driven over its own
protocol.

### 7.1 Two windows of one process — on the creator's live Chrome

```
chrome.exe pid=32060: 2 windows 0x50B8E,0x19816FC
  keys WITHOUT the HWND : 1
  keys WITH the HWND    : 2
Notepad.exe pid=60780: 22 windows ...
  keys WITHOUT the HWND : 1
  keys WITH the HWND    : 22
```

Confirmed on real applications, twice over. An identity without the HWND collapses distinct
windows into one member.

### 7.2 Windows 11 Notepad is the reviewer's counterexample, in bulk

This is the round's most consequential incidental finding, and it arrived from a *failed probe
setup*:

```
launched pid=45012
NO WINDOW after 15s.
  process alive: True
  mainWindowHandle=0 title=''
  visible notepad windows from ANY process: 29   <-- all owned by pid=60780
```

A freshly launched `notepad.exe` — alive, healthy, not exited — **owns zero top-level windows**,
while a *different*, older notepad process holds **29**. Windows 11's Notepad is a single-instance
host with a tabbed UI: later launches hand off to the running process, and each document is a
top-level window under that one PID.

Nothing in the design's Stage 7 test corpus or Stage 14 acceptance exercise covers this. It breaks
three assumptions at once:

1. **PID churn is not a reliable "new instance" signal** for single-instance-host applications.
2. **Stage 7.4's 500 ms stabilization window** cannot distinguish a tab appearing from an
   application starting.
3. **"Close the window, the process lives on"** is the normal case here, not an edge case — so
   Terminal-vs-nonterminal outcomes cannot be derived from process liveness at all.

It is also the strongest possible argument for the marker: 29 windows sharing every corroborator
is not a hypothetical collision, it is the current state of the creator's desktop.

### 7.3 The hosted / packaged boundary — found, and it is the host process

```
SystemSettings.exe windows visible to EnumWindows : 0
ApplicationFrameWindow windows                   : 1
  frame 'Settings'  class=ApplicationFrameWindow  pid=41692  exe=ApplicationFrameHost.exe
SystemSettings.exe entries in the helper list     : 0
helper entries for pid 41692                      : 1
```

A packaged application presents a window owned by **`ApplicationFrameHost.exe`**, not by the
package's own process. The package process owns no top-level window at all. Consequences:

- A hosted target's identity is the **frame's** identity, not the packaged process's.
- Every packaged app on the machine shares one host executable and would be separated only by
  the HWND and by nothing else — the same collapse as §7.1, one level up.
- This is the boundary the reviewer asked me to find, and it is **supported rather than
  unverified**: the frame is enumerable, fully scoped (pid, class, session, creation all
  present), and listed by the helper.

I still do not claim `EnumWindows` proves the absence of every Windows surface class — only this
measured boundary and the earlier `PseudoConsoleWindow` / `Windows.UI.Core.CoreWindow` sightings.
Notably, `Windows.UI.Core.CoreWindow` ("Windows Input Experience") was also visible, so the
surface zoo on a normal desktop is larger than the design's corpus assumes.

### 7.4 Refusals, recorded as refusals

- **Helper restart:** 14 of 14 PIDs survived, **0 of 5 sampled tokens survived**. The native
  scope is portable across a helper process; tokens are not. Recovery must be by scope.
- **Title mutation (round one, unchanged):** the helper refused a live window with
  `denied: window identity changed since the token was issued`, and the identity **scope** of the
  same window reported `Verified=true`. Scope and helper disagree, which is the entire reason
  the scope exists.
- **Elevation:** `ERROR_ACCESS_DENIED` on write (§2). `UNVERIFIED`.

---

## 8. The design this round supports

```
locator        the HWND value — never authority alone
corroboration  bootId + sessionId + PID + process incarnation + window class
marker         per-HWND enrolled generation nonce (named atom, scalar value,
               fixed property key), authoritative on a LIVE window
state          VERIFIED | UNVERIFIED | GONE, with UNVERIFIED as a first-class,
               visible outcome rather than an error
```

Rules the measurements force:

1. **Corroborators can never produce `VERIFIED` on their own** when a marker is expected and
   absent. They produce `UNVERIFIED`. (§2: absence has three meanings.)
2. **A present, matching marker is the only route to `VERIFIED`** for an instance-bound member.
3. **`GONE` requires positive terminal evidence**, never absence, never an enumeration miss,
   never a refusal, never a timeout.
4. **Scope mismatch is `UNVERIFIED` or out-of-scope**, not death — that is what keeps the
   unmeasured transitions (reboot, sleep, RDP) from producing wrong answers.
5. **Never downgrade.** When enrolment is refused, the operation fails; it does not fall back to
   title, PID or ordinal so that it can succeed.

---

## 9. What refused, and what it looked like

The reviewer asked for the refusals, not only the passes.

| What was attempted | What happened | Where |
| --- | --- | --- |
| Forcing HWND reuse via WinForms | 0 of 113 attempts; instrument defect found (form title never lands without a message pump) | `probe-11` |
| Forcing HWND reuse at the raw allocator | 0 of 180 attempts | `probe-12` |
| Four reuse shapes incl. batch orders and 200-cycle churn | 0 recurrences in every shape | `probe-13` |
| 20,000-cycle recycling rate | 0 recurrences; stride exactly `+0x10000`, low word pinned | `probe-14` |
| Reading `SequenceNumber` on build 26200 | `STATUS_INFO_LENGTH_MISMATCH`, then success but an **unvalidated** offset map; **not established** | `probe-16`, `probe-17`, `probe-18` |
| `SetProp` against an elevated window | `ERROR_ACCESS_DENIED` (5), no marker written | `probe-16` |
| Starting a packaged app to measure its own process's window | `SystemSettings.exe` owns **no** window; the frame belongs to `ApplicationFrameHost.exe` | `probe-19`, `probe-21` |
| Launching notepad and finding its window | new process owns **0** windows while another owns **29** | `probe-19`, `probe-21` |
| Driving the helper from PowerShell | two distinct instrument failures: `ReadLineAsync` in a retry loop ("stream is currently in use") and unbounded `ReadLine` (hangs forever) | `probe-19` v1, `probe-20` |
| Retitling the creator's live Chrome/Obsidian/VS Code windows | **refused by policy** — title mutation was measured on a probe-owned window instead | `probe-19` |
| Rebooting, sleeping, hibernating, Fast Startup | **refused by policy** — the creator's machine is in use | `probe-22` |
| An RDP reconnect | **refused by policy** — requires taking over the creator's session | `probe-22` |

---

## 10. What I could not prove, stated plainly

1. **The reviewer's reuse collision.** Not forced in ~20,400 attempts across four probes. I
   believe the reviewer that it happens — Microsoft documents recycling and a finite index space
   wraps — but I did not reproduce it, and the invariant is instead proven over a 2,400-window
   replacement population where 0 markers were inherited. Recorded as *not forced*, not as
   *cannot happen*.
2. **`SequenceNumber`.** Location not established on build 26200. My intermediate "absent"
   reading was an instrument failure and is corrected in §3.
3. **A creation-FILETIME collision exists.** One collision in six consecutive incarnations in
   `probe-16` section C, none in ten in `probe-17`. A measured weakness in the fallback.
4. **Reboot, Fast Startup, sleep, hibernate.** Not performed. Two of the four are *unavailable*
   on this machine (hibernate, Fast Startup); sleep is available and I declined it.
5. **RDP reconnect and multi-session.** Not performed. The fence is adopted; the behaviour is
   not measured.
6. **The offset-map validation for `SystemProcessInformation`.** Outstanding.
7. **Whether an owned window is rejected by the helper's owned-window clause.** Round one's open
   question (§7.5 there) is still open. I did not revisit it this round.

---

## 11. Safety of this round, including one thing I should not have done

- **No pre-existing window was moved, hidden, re-ordered or closed.**
- **All window churn was on probe-owned windows** — raw windows in the probe's own process, or a
  probe-started window server.
- **One exceedance, recorded rather than omitted.** `probe-15` enrolled generation markers on
  **12 real application windows** and removed them again, to answer whether enrolment works at
  all against ordinary applications. That is a write to windows the creator owns, and the round
  one finding said the creator's live windows are not the probe's to write to. It was
  non-destructive and fully reversed — `probe-22` scanned all 73 visible windows and found **0**
  carrying any probe property name — but it should not have been done without asking, and it is
  not repeated.
- **Four notepad processes were created by the probes and cleaned up**, one of them descended
  from the probe's elevated helper and one holding 29 accumulated top-level windows from the bulk
  launches. Verified afterwards: 0 notepad processes, 42 visible top-level windows (a normal
  desktop count), Chrome 87 / Obsidian 4 / Papers 6 all still running.
- **The creator's Papers was never restarted.** The one live helper under `Papers.exe`
  (pid 31912) was confirmed to be theirs and left alone; every probe helper was killed.
- **Papers Source is untouched:** branch `lane4-window-identity` at `9a839eb`, **0 files changed**,
  working tree clean. Host suite green at 942 passed / 4 skipped.
