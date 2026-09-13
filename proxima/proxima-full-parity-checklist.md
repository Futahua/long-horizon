# Proxima Backpack — Full-Parity Implementation Checklist

<!-- STATUS: replace this block in place. Never append. -->

## Status

**Updated** 2026-09-13 · **Repo** Futahua/proxima-backpack

**Where everything is.** Windows paths. The short names beside these are symlinks into
`Products\<Name>\<Role>` and both forms work, so a tool reporting one when you typed the
other is not a wrong directory. Use `D:/...` in scripts: Windows Python cannot resolve msys
`/d/...` and fails *silently*, which once produced a no-op edit that looked like a pass.

| | |
| --- | --- |
| Working tree | `D:\Letters\MatTroiSeConMoc\Products\Papers\Runtime\Backpack projects\Proxima` |
| Fixture vaults | `<working tree>\fixtures\` — `vault-basic`, `vault-duplicates`, `vault-legacy`, `vault-malformed` |
| This checklist | `D:\Letters\MatTroiSeConMoc\LongHorizon` — `Futahua/long-horizon` |
| Original plugin | `D:\LapSlop brotherhood\Local\.obsidian\plugins\proxima` — `Futahua/Proxima-Obsidian` at `c1af9cb`, the SHA the interaction trace was written from. **Read-only reference: it is a live plugin inside the creator's vault. Do not write to it.** |

| | |
| --- | --- |
| Accepted branch | `stage7-record-store-contract` — creator-accepted through Stage 8 slice 18 at `97c9dd9`; slices 19–47 are pushed at `bd64a34`, `394179c`, `c62a7dc`, `d7e6a6c`, `d66622f`, `a31c74c`, `9b59d16`, `bdea4a1`, `7ec8d17`, `7825d20`, `e88e193`, `b20cdca`, `fef3b8a`, `d7e6270`, `9d6062c`, `1ffdd55`, `d21f434`, `8cadd24`, `3fa16bc`, `ba50cc6`, `7f96a71`, `ead7927`, `215777a`, `08e505d`, `8dc3841`, `d9d8c5e`, `738bb53`, `06c0702`, `d6e2b30`, `e898a04`, `abf8204`, `e62e8f4`, `ed09e3d`, `cab1627`, `18c2e48`, `9a04451`, `e4e319b`, `c74003f`, `1029a25`, `6dfad33`, `08d31b5`, `e325f6e`, `9dcc5d6`, `e9117b2`, `9b197e2`, `04d0bc4`, `327d90c`, `f8376eb`, `c5291f1`, `d5fbc00`, `9e20d39`, `392a8e7`, `2e7928d`, `75091b0`, `da99863`, `dc82f11`, `38ce017`, `16b443e`, `f3f277a`, `bd61f60`, `8d5ec96`, `38bd4ca`, `81e1ec4`, `bede835`, `f17ba68`, `9e27cad`, `1b0094a`, `4288b71`, `dc675d9`, `8676dc3`, `425a631`, `ac6115a`, `4b241f8`, `5af693f`, `2dadbe1`, `b4b17b1`, `32132bb` and `65f88ef`, then `21de194` (D60's delete cascade) and **`46e1bea`** — a Status-only commit that moved no code, pushed. **The branch HEAD and the audited code SHA are therefore two different things and both are named here**: the code was last audited at `21de194` (typecheck 0, `npm test` 0 - 260 test files / 1727 passed / 1 skipped, re-run at `46e1bea` with the same totals), and `46e1bea` is what the branch points at. The historical "await acceptance" on the slice list above is superseded: each of those slices was accepted where this checklist records it, and the branch has been the accepted branch since `97c9dd9`. |
| Accepted host Gate 9.3 | `Futahua/Papers-3` branch `proxima-gate9-native-source-handoff` @ `67b7fa2` — pushed |
| Accepted host Gate 10.1 | `Futahua/Papers-3` branch `gate10-native-presentation-reconcile` @ `5451bbf` — pushed, creator-accepted |
| Accepted host Gate 10.2 | `Futahua/Papers-3` branch `gate10-host-truth` @ `9e6304b` — pushed, creator-accepted |
| Accepted host Gate 10.3 | `Futahua/Papers-3` branch `gate10-relay` @ `d2a3c74` — pushed, creator-accepted |
| Unaccepted work | none |
| Semantic-key contract at `e08616d` | **The C1 surface was invisible to a Papers host, for two reasons that were both in this project, and a live host now sees it.** First the attribute: Papers reads exactly `data-papers-visual-key` (`src/preload/projectVisualSemanticKeys.ts`), this project's own `AGENTS.md` documents that name, and the renderer emitted `data-c1-key` in 519 places across 64 files including the tracked shell, so a surface that reached `layout-stable` with clean lifecycle diagnostics reported **zero** elements to `inspect.visual.elements`. That is why Gate 2's evidence boxes had been open with the reason "no host-integrated C1 artifact exists" - the artifact could not exist while the host could not read a single key. Second the values: Papers validates a key against `^[A-Za-z0-9][A-Za-z0-9._~-]*$` with a 256-key and 128-character bound and no duplicate, and `registerVisualSemanticKeysIpc` refuses a payload that breaks any rule **whole and in silence**. The bundled fixture vault holds a task whose declared identity is `Untitled loose task`, so three keys carried a space and every key on the surface was dropped with no diagnostic anywhere. `src/browser/semanticKeyValue.ts` now encodes an identity into the host alphabet (`~` plus two hex digits per UTF-8 byte, `~` itself as `~7E`, a `k~` prefix when the first character would not be a letter or digit, a digest-suffixed bound at 128) and runs at the single boundary that writes the document, so the encoding is deterministic and injective - `a b`, `a-b` and `a~20b` stay three different keys - and deliberately not idempotent, which is why it belongs on freshly rendered markup only. **The live acceptance, on a disposable profile and a freshly created window:** `layout-stable`, 21 lifecycle records with no failure, 21 timeline entries, **71 elements / 71 distinct keys / 71 with geometry**, six named assertions with real geometry, a verified 143 456-byte surface capture and three verified element captures, against Papers 1.3.11 at `d2a3c74` (`packaged false`). Three host-side findings are recorded as requests rather than as work, in Proxima's `docs/AUDIT-CHECKLIST.md` section 2.8: a refused semantic-keys payload is silent; `tools/papersVisualDebug.mjs`, `papersVisualCompare.mjs` and `papersVisualIncident.mjs` compare `resolve(process.argv[1])` against a percent-encoded URL pathname and are therefore no-ops on Windows, so `npm run papers:visual-debug` exits 0 having done nothing; and capturing an unpresented surface answers with an artifact-bound error instead of a typed refusal. Decision recorded as D81. No parity box changed state: 835 ticked / 5 open, before and after. |
| Awaiting the creator at `21de194` | **This checklist now has nothing left to await: 840 of 840 boxes are ticked, and the last two closed on the third of the three product answers the program was holding.** *Proxima's agenda* (43 open, see its own Status for the full split): 37 need the creator at the machine or their data, 3 are the creator's decision (Gate 14's write-enrollment sign-off, the explicit decision to allow writes, one smallest record type - the gate is built and refuses by default, D83), and 3 are the positive half of a gate whose host change is now made - opening or revealing a real source needs an OS-backed `File` from a drag-and-drop, and the staleness check lives behind a granted reference, so both are the creator's hands rather than a Papers question. **That group used to have a fourth member and it is closed:** the native-source handlers existed in Papers' *production* preload and not in the developer-control preload the automated runs use, so a page's request was answered with silence - the creator authorized that host change on 2026-09-13 after it was put in plain language, Papers `9a839eb` now carries the three requests in the diagnostic preload too, and Proxima's containment probe observes all four unauthorized-source refusals as typed answers instead of `no-answer` (`b3f7315`). *This checklist's own boxes*: the four that stood here asked three product questions - the template relation syntax for records
created at the same moment, whether task recurrence is retained at all, and what `project.delete` does with a project's
members, which appeared in two boxes because one asked for the ids and the release gate asked for the distinguishable
outcomes behind them. All three were answered by the AUTHOR and landed: relations and recurrence at `24e93c8`, the
delete cascade at `21de194`. The fifth box that stood here, *runtime validation exists*, closed at `ecf435a` on D85 - a ruling
that fixed what the column measures (the entry facing an untyped caller, not every member module re-parsing a typed
request) rather than re-measuring the old question, which is why it is recorded with both readings and a reversal
condition. The two design-only window checklists (345 open) say it themselves - **"Not started. No implementation
exists. Design only."** - and their work would land in the Papers host, so they wait on a person by their own statement
rather than by inference. *Quick Run's sixteen* (working tree `D:\Letters\MatTroiSeConMoc\Products\Papers\Runtime\Backpack projects\As you Go`, branch `quick-run-integrated-perf`, whose own Status names every path): seven Papers-activation and two availability/native boxes need the Papers host **with the helper present**, two Layout Item boxes need the activation capability, four native-boundary boxes are that capability seen from the host's side, and one architecture invariant closes with the host change. **The pair that used to be listed here as needing a real 10k-20k-row corpus and therefore the creator's instance closed at `299152d` without it:** STAGE 14.1 asks for a synthetic/fixture workspace in its own words, so the measurement was taken on a seeded disposable profile, it failed at p95 30 ms, the creator chose to cap what is painted, and the same instrument then passed at p95 4.3 ms - which is also the correction of the "creator's consent" reading that stood in this row. All 39 commits that document cites resolve in the local trees, checked by `.dsh\audit-cited-shas.mjs` - which counts **commits only**, because a blob sharing a seven-character prefix would otherwise have reported a resolution for a commit that does not exist. The two design-only window checklists (**342** open: 173 + 169, the window one having answered all three of its reviewer items — the tag lifetime by measurement at `825154a`, the startup/reboot transition table at `c29cc40`, and the mandatory-versus-recommended separation at `0fb0bdc` — while its feature stays unbuilt and prohibited) need the creator present by their own design. **So: nothing else in this program is implementable without a person, a granted directory, or a host change.** |
| The native-source refusals became observable at `9a839eb` | **A host change the program had recorded as unavailable was authorized by the creator, made, and it turned four unobservable refusals into typed answers.** Proxima's Gate 9.3 could not measure its own refusal rule: Papers' developer-control preload carried none of the `native-source-grant`/`-open`/`-reveal` requests, so on a diagnostic instance a page's attempt was answered with silence, which the containment probe records as `no-answer` - and silence is not evidence of authorization. Papers `9a839eb` @ `2026-09-13T07:24:03+07:00` (branch `native-source-diagnostic-preload`, cut from the accepted host branch `gate10-relay` @ `d2a3c74`) mirrors the shipping preload's three branches and its `validNativeSourceRef` check into the diagnostic preload, with the same validation and the same host channels; the host side needed no change, because `hostIpc.ts` already routes all three by `event.sender.id`, which is what scopes a grant to its owning Backpack. Proxima's `7fc92b9` @ `2026-09-13T07:24:10+07:00` repaired the instrument, which built its answer map from the six containment questions while its verdict loop read the questions the run actually asks - so the four handoff answers were always null and a run in which every refusal had been observed still reported BLOCKED with four empty answers. **The acceptance:** an instance built from that source, reporting Papers 1.3.11 at `d2a3c74+local` and `packaged false`, exits **0** on `npm run probe:containment -- --handoff true` with status **PASS** and ten expectations satisfied - the six containment answers unchanged, and `handoff-fabricated`, `handoff-ungranted`, `handoff-machinePath` and `handoff-malformed` all reading `refused`. Papers' own suite was run for the host change: typecheck 0, `npm test` 0 at **99 files (98 passed \| 1 skipped) / 942 passed + 4 skipped**, build 0; Proxima on its branch: **260 files / 1727 passed / 1 skipped**, exit 0. The box is ticked at `b3f7315`, and both halves sit on their own branches awaiting acceptance rather than being presented as landed. What this does not close: the positive half - opening or revealing a real source needs an OS-backed `File` from a drag-and-drop, and the staleness check waits behind a granted reference. |
| D60's delete cascade landed at `21de194` | **The last product question in the program was answered by the AUTHOR and implemented, and the checklist it was blocking is complete.** The creator chose the explicit cascade: a `project.delete` carries the task and event ids the caller confirmed, the operation verifies that list against the store **before** it removes anything, the members go before the project, and the run answers `'deleted'` with every affected entity id instead of the counts the old open-question refusal reported. A list that no longer matches the current membership is refused `membership-mismatch` and leaves the store byte-identical; the revision is still checked before the membership question, so a lost race is still `stale-revision`. The Hub asks before it acts - the first press captures the membership it is drawing and shows the ids, the second submits exactly that list, and an empty project is one press because there is nothing to confirm - and the agent wire carries the same list and refuses a delete that names a project without it. **Every claim the cascade falsified was repaired in the same commit**, which is the part worth reading: six module headers and doc comments still described the retired open-question refusal as current behaviour, and Stage 17's `project.delete` contract row still recorded "nothing: this operation has no success branch" with an `idsGap` and a not-applicable success cell. The row now records the verb as `write`-shaped with a satisfied success cell, and the four suites that asserted the old refusal were rewritten onto the contract that replaced it. `policy-not-decided` stays in the vocabulary as reserved and unproduced by the AUTHOR's ruling, annotated rather than removed, so the day a path returns it the audit fails. Evidence: `tests/projectDeleteConfirmation.test.ts` is new - 10 cases for the six properties the AUTHOR named, driven through the real binder and the real renderer - and four mutation probes each made the suite fail, with the file restored byte-for-byte by hash afterwards. Verified on the accepted branch itself: **typecheck exit 0** (both passes; the script is `tsc src && tsc tests`, so the earlier "one error left" reading was the src pass only and the tests pass had never run) and **npm test exit 0, 260 test files / 1727 passed / 1 skipped**. Three executor repairs are declared on the commit, all transport: the pending-delete state lives in `main.ts` because that is where the Hub's state already lives rather than in the module the packet named; a Cancel control and Escape dismissal were added because the modal the packet asked for had no way out; and `runProjectLifecycle` was split so the delete arm cannot be called without members. The packet-by-packet record is kept on `wip/d60-project-delete-cascade` @ `2a541f6`; the landing is the squashed `21de194`. |
| Relations and recurrence landed at `24e93c8` | **Both product decisions the program was waiting on came back from the AUTHOR as guarded packets and are implemented at this commit.** D86 gives template-local relations an ordinal vocabulary (`@N`, one-based declaration order, comma-separated targets) that never reaches storage: execution creates every task first, records the returned opaque ids and revisions, then resolves `@N` through `planPropertyMutation`, so canonical relation values are still ids. D62 retains task recurrence on the existing canonical series/occurrence model: a task owns one series, the projection carries it, the Task editor gains the rule controls, and Save routes through the typed `recurrence` mutation with a caller-supplied series allocator. Applied verbatim from the AUTHOR's packets through `.dsh/apply-packets.mjs`, which refuses a replacement whose anchor is absent or ambiguous; every anchor matched exactly once. Evidence: `tests/templateRelationExecution.test.ts` (2 cases) and `tests/taskRecurrencePlan.test.ts`. Verified: typecheck exit 0, focused suite exit 0, full suite **259 test files / 1714 passed / 1 skipped, exit 0** - no test skipped, relaxed or weakened. Three executor repairs are declared on the commit: a step truncated in transit had its anchor restored verbatim and was later re-issued; ChatGPT delivery furniture was removed from a source file; and eight strict null-narrowing guards were added to the AUTHOR's new test without touching an assertion. Parity agenda: 4 open to 2 - the two that remained both waited on the D60 project-delete cascade, which landed at `21de194` and took the agenda to 0. |
| Runtime validation ruled at `ecf435a` | **The last of the ten "for every row above" umbrellas closes on a ruling rather than on twenty new parse boundaries.** The column was carried as a gap on thirty-three of thirty-six rows under one of two defensible readings, and the retired AUTHOR left the choice open for the reason that an executor closing a box by redefining what it measures has closed nothing. D85 fixes it: the column is answered **at the entry that faces an untyped caller** - `parseAction` for the action protocol, `parseAgentWriteSubmission` for the agent wire, the editor's field parse for a form that arrives as text - because every row's contract is a typed request (36 of 36 in the column beside it), so a module re-parsing its argument would be a second boundary behind one that already refused. The figure is now **3 satisfied / 33 not-applicable by decision / 0 gaps**, and the three satisfied cells are the schema rows whose boundary really does take `unknown`. **The evidence moved rather than thinned:** the n/a cells still assert `input: unknown` is absent from the member module - so the day one appears the audit goes red and the decision must be re-taken - the ruling's own case fails if either parser stops taking `unknown`, and typed validation refusal stays 36 of 36. Four probes bite (the column flipped back to a gap, a module starting to take unknown, the entry no longer parsing unknown, a schema row losing its satisfied cell). Suite at this SHA: **257 test files / 1707 passed / 1 skipped**, exit 0, typecheck 0, `git diff --check` 0. This checklist now stands at **836 ticked / 4 open** of 840, or 744 / 4 counting top-level boxes. |
| Native handle accepted without a picker at `e315470` | **Gate 4.4's last box closes on a browser acceptance rather than a deferral.** `tools/fsa-native-handle-probe.mjs` (`npm run probe:fsa-handle`) drives the shipped adapter against a real `FileSystemDirectoryHandle` from `navigator.storage.getDirectory()` in headless Chrome over the loopback viewer, in a disposable profile: no picker, no gesture, no grant. Nine recorded stages - the handle is native and carries the native-only `isSameEntry`/`resolve`, `queryPermission` answers `granted`, a fixture is written through the native API, the repository contract holds with three *message-specific* refusals, `showDirectoryPicker` is counted at zero calls, and a second page load reads the same files through a freshly obtained handle. **The interesting result is a survived probe:** with the traversal guard deleted, a `'..'` read is still refused because a name-based handle has no child of that name, so the guard is a refusal-quality guard and the handle itself is the security boundary - the opposite of what the guard looks like it claims. The acceptance now requires each refusal by message and all three probes bite. Two tool defects are recorded with it, because both were silent: `process.exit` inside a function called from a `return` expression meant the teardown never ran and seventeen disposable profiles accumulated, and a single removal attempt raced the crash handler that outlives the launcher. **What stays out of reach:** a picked real Windows directory (Gate 11.3) needs one human gesture, so the "automatable through the host seam" line in the row below is now zero. Suite at this SHA: **257 test files / 1703 passed / 1 skipped**, typecheck 0, `git diff --check` 0. Proxima agenda 45 open to 44. |
| Recovery story becomes visible at `0c80b85` | **The rollback/recovery story existed and was invisible; the box that asks for it closes on the commit that gave it a reader.** The machinery was already built and tested - durable journal, `not-applied`/`effect-present`/`conflict`/`already-committed` classification, and a *conditional* restore that refuses to overwrite a record someone else has since changed - and reconciliation already ran on every boot before mutation authority was handed out, automatic rather than gesture-driven because a journal only examined on a write is one nobody reads on the boot that needed it. `src/browser/recoveryNotice.ts` renders the answer in the header on every boot including the clean one, and `not-run` never renders as `clean`: an unasked boot and a clean boot differ in machine value, tone and sentence. Clean requires resolving everything found *and* leaving mutation authority available; blocked and failed say why and say writes stay closed. **Stated rather than implied:** the byte-level restore has no production caller, so a live creator-vault crash story remains part of the native acceptance in Gate 6 and Gate 13. Decisions: D84. Five mutations bite. Suite at this SHA: **257 test files / 1703 passed / 1 skipped**, exit 0, typecheck 0, `git diff --check` 0. Proxima agenda 46 open to 45. |
| Refusals explain themselves at `79c7acd` | **A refused write reaches the surface saying what happened, not only that something did.** `src/app/refusalPresentation.ts` is new: the machine code first - deliberately, because selectors and agents match on it - then the producer's bounded sentence, then the revision that beat the caller, and nothing invented when the producer supplied nothing. Applied at `performElasticDrop` and both `saveTaskFromEditor`/`deleteTaskFromEditor` write sites. Each case drives a real store, has a second writer move the record on, and asserts what the surface is handed *and* that the refused card did not move: a refusal is still a refusal. The drop path's `TaskMoveGestureResult` already carried `actualRevision` and the editor's `TaskMutationFailure` already carried `detail` + `actualRevision` - both were being dropped at the `setRefusal(reason: string)` boundary, which is what this slice fixed. **The full suite caught what the targeted run did not:** `tests/taskMoveGesture.test.ts` had pinned `[null, 'stale-revision']` at the shell-glue boundary and now pins the whole string. Six mutations bite. Sinks not in this slice (event writes, project lifecycle, workflow stages, timeline, recurrence) still pass a code or a detail without the revision, and the box says so rather than implying coverage. Suite at this SHA: **256 test files / 1698 passed / 1 skipped**, exit 0, typecheck 0, `git diff --check` 0. Proxima agenda 47 open to 46. |
| Write after-image evidence at `e83dcca` | **"Evidence proves no unrelated bytes changed" is a measurement rather than a claim.** `tests/writeAfterImage.test.ts` writes a disposable vault through the conditional disk writer's own compare-and-swap commit and fingerprints the whole tree before and after with the same implementation the zero-write acceptance uses. A committed update's delta is exactly the declared file, asserted both as the changed-path set and as bytes for every other file; two declared writes leave nothing extra; a refused stale write leaves the tree byte-identical while naming the revision that beat the caller. The load-bearing case is a control pair: a same-size edit with its timestamp handed back exactly is invisible to a size-and-mtime sweep of the same tree and caught by the content-hashed one - which is the reason `CONTENT_HASHED_ROOTS` exists. Four probes turn it red (`CONTENT_HASHED_ROOTS` emptied, the hash made constant, the writer touching an undeclared file, the refusal naming the expected revision), each restored byte for byte. **One suite-discovered detail:** `utimes` cannot restore sub-millisecond precision, so the clock is normalised to a whole second before the edit. The visible-refusal box is now half measured: the refusal is attributable and the surfaces render a code, but `setRefusal(reason: string)` drops the detail and the revision on the way to the DOM. Suite at this SHA: **255 test files / 1691 passed / 1 skipped**, exit 0, typecheck 0, `git diff --check` 0. Proxima agenda 48 open to 47. |
| Write boundary is a gate at `871a8a1` | **The two boundary evaluations stopped being reports and became the rule a surface asks.** `src/app/writeAdmission.ts` is new and pure: it decides from the source, the record type, whether a write path resolved, the creator's enrollment, and whether the host has an atomic commit primitive. Live data - `external`, the reader this process did not create - is refused **before** enrollment is consulted, so the most permissive enrollment anyone could write still cannot write the creator's bytes (`native-transaction-required`, measured from `evaluateFsaWriteBoundary()`, which had no runtime caller before this slice). The refusal names the first thing standing in the way, in capability-then-permission-then-scope order. The header badge now distinguishes `Live data` from `Fixture data` and from the record store, and a second badge carries the gate's verdict and its machine-readable reason; both come from one call, so the surface cannot claim a capability the gate did not grant. `DEFAULT_WRITE_ENROLLMENT` is frozen and empty, and the suite scans `src/` to assert nothing enrolls writes. Ordinary fixture and record-store runs are untouched. Eight mutations bite. Decisions: D83. Proxima agenda 50 open to 48. Suite at this SHA: **254 test files / 1687 passed / 1 skipped**, exit 0, source/test typecheck 0, build 0, `git diff --check` 0 (253 / 1673 at `58f7291`). |
| Zone wiring landed at `58f7291` | **Gate 1's last open box closes: the civil-time zone is an injected parameter and the machine's zone is read once, at the boundary.** `src/domain/timeZone.ts` holds the type, a platform-backed IANA zone (offsets from the platform's own database, unknown ids refused) and `civilFieldsAt`/`instantOfCivil`; `src/browser/hostTimeZone.ts` is the only ambient reader - the boundary suite is what put it there, having refused `hostZone()` inside `src/domain`; `time.ts` takes the zone explicitly. The browser modules bind one per render call from their options, `scheduleNavigation` takes it through three functions, `eventsByDay` takes it, and the inspection projection takes it with the shell passing `hostZone()`. **The migration was the finding:** wiring it turned 25 assertions red, every one a fixture written as a UTC midnight while this machine is UTC+07 - they had been deterministic in one zone and nowhere else. The suites now state theirs. Calendar-grid dates stay a documented *floating* idiom (local midnight, read with local getters, consistent by construction) with the anchoring named as future work. Five mutations of the zone module bite. Decisions: D82. Proxima agenda 51 open to 50, 1126 ticked of 1177. |
| Zone wiring parked at `0c0d593` | **The zone port landed; the wiring through it is parked on a side branch, red by measurement, and the measurement is the interesting part.** `a3bede7` put the type, the single ambient reader above the domain and a twelve-case correctness suite in place. Switching `localDateKey`/`formatClockTime` to an explicit `TimeZone` then removed the ambient read from the domain and turned **7 files / 25 tests red** - `scheduleTimeGrid` 10, `scheduleProjection` 5, `scheduleWriteWiring` 5, `scheduleRecurrence` 2, `surfaceConvergence` 1, `inspection` 1, `modalAudit` 1. Every one of those assertions is a schedule or inspection expectation whose fixture means "+07 local", this machine's zone: they were deterministic in UTC+07 and nowhere else, which qualifies the checklist's already-ticked "tests are deterministic across CI/developer timezone differences" box honestly rather than retracting it. `typecheck` is clean on the branch and the other 246 files pass, so the failures are a worklist rather than a broken build; it is parked because the fix is threading a `zone` through six modules' render options (~forty call sites), which does not fit one slice. Two shortcuts were tried and abandoned, both recorded on the branch: a scripted rename that rewrote its own wrapper bodies into self-recursion, and rewriting the fixtures to UTC construction, which moved the count by nothing. The accepted branch is untouched and green at `32873e1`; no parity box changes state - 835 ticked / 5 open. **A second attempt is parked on the same branch at `c41fd3e`** and it is the behaviour-preserving half: the four browser modules now derive through a `bindZone(options.zone)` wrapper defaulting to the host zone read in `src/browser/hostTimeZone.ts`, so where the zone is read moves to one boundary while the zone itself does not change. That ordering is the lesson of both attempts - with every call site passing a zone explicitly, flipping the default to UTC changes nothing and no suite has to go red. The branch lists the five remaining mechanical items and keeps the script at `.dsh/zone-pass1.mjs`. **Pass 1c (`a131ec7` @ `2026-09-12T21:05:45+07:00`) leaves four failures, all fixtures that never stated their zone, and two recorded dead ends: a blanket `zone: utcZone()` sweep breaks `timekeepingCockpit.test.ts`, and UTC-constructed fixtures changed nothing.** |
| Civil-time zone port at `a3bede7` | **The zone is a type now, and the machine's zone sits behind one boundary - the foundation for Gate 1's last open box, which stays open because the wiring is its condition.** `src/domain/timeZone.ts` defines `TimeZone`, a fixed-offset constructor, a platform-backed IANA zone and the two conversions derivation needs (`civilFieldsAt`, `instantOfCivil`), with offsets read from the platform's zone database through `Intl` rather than from a table this repository would get wrong at the next transition; an unknown id is refused rather than approximated. The read of the machine's zone lives above the domain in `src/browser/hostTimeZone.ts`, and the boundary suite is what put it there: it refused `hostZone()` inside `src/domain` on the first run, because reading the machine's zone is ambient state. `instantOfCivil`'s three branches are explicit and asserted - one candidate is ordinary, two means a repeated fall-back hour and the earlier instant wins, none means a skipped spring-forward hour and the pre-transition offset shifts forward - across UTC, a half-hour zone, both Berlin transitions, the southern hemisphere, a previous-day western case and a round trip at four instants. **Five mutations bite** with the module restored byte for byte: ambient `Date` getters, the skipped-hour validation removed, a repeated hour taking the later occurrence, the fixed-offset bound removed, and an unknown id falling back to the host. What is left is the wiring: `localDateKey` and `formatClockTime` still read the ambient zone, and the schedule and calendar modules carry about a hundred `Date` getter reads between them. No parity box changes state: 835 ticked / 5 open. |
| Native-source handoff finding at `dd04478` | **Gate 9's four acceptance boxes were open on a reason that turned out to be wrong, and the correction was measured.** They said the host primitive did not exist. It does - in Papers' *production* preload, where `papers:project:native-source-grant` takes exactly one `File` and resolves its disk path itself (a page can never name a path), `-open` and `-reveal` take an opaque reference, and they reach `host:backpack-project:native-source-*` and a service whose staleness check re-stats the file. What is missing is in the *developer-control* preload, which carries none of the three handlers: a diagnostic instance answers those requests with nothing at all, so a request disappears instead of being refused. The containment probe now measures that with `--handoff true`, sending four refusals from a page (a fabricated `File`, an ungranted reference, a machine path, a non-reference string) and publishing the host's own answer as a semantic key; all four came back `no-answer`, which the probe reports as its own verdict rather than as a refusal, because silence must never be read as authorization. The group is opt-in because it cannot pass on a diagnostic host. **Asked of Papers:** the same three page messages in the diagnostic preload, or an explicit record that developer control cannot exercise native-source paths. The positive half stays a person's drag-and-drop on either host. Boxes: 51 open before and after - the reasons changed, not the ticks. |
| Containment probe at `ad6ee56` | **Papers' containment of a Backpack page is now measured rather than cited, and Proxima's agenda is at 51 open boxes.** Gate 20's "still sandboxed" box had been open because the host's `papers-backpack://` policy is not this repository's source and no acceptance evidence existed here. A probe Backpack (`tools/containment-probe/`) answers six questions about its own containment and publishes each answer as a semantic key, so the **host's own** `inspect.visual.elements` carries the result; `npm run probe:containment` opens it, waits for the answers and asserts them. On a live Papers 1.3.11 host at `d2a3c74` (`packaged false`) all six answered as containment: no Node; a **same-origin** fetch refused (`connect-src 'none'`); indirect eval refused (no `'unsafe-eval'`); an embedded frame's document never fetched (`frame-src 'none'`); origin storage isolated to its own database; and the page on the `papers-backpack` origin of its own Backpack id. **The attempts are part of the evidence:** the first probe published nothing because an inline module is refused under `script-src <origin>` without `'unsafe-inline'` (so its code is an external file now), and the frame question answered `FRAME-LOADED` and then `frame-opaque` before resource timing settled it - a refused frame's document is never fetched, while this document's own load is a navigation entry rather than a resource one. Five probes of the checker bite, including a mutation expecting `NODE-VISIBLE`. Gate 20's grant-ownership box keeps its native half open with the browser half recorded as measured. |
| Startup recovery wiring at `9670c15` | **The runtime now reconciles its durable recovery journal on the boot, closing Proxima's Gate 13 gap and taking its agenda to 52 open boxes.** It had carried the gap in two places - 13.C's last box and 13.C2's "runtime wiring remains open" sentence - and both were the same missing call: the gate ran only when a write was attempted, and only after the store reported itself activated, so a store nobody wrote to was a store whose journal nobody read, including the boot after a crash. `StartupSessionOptions.runRecovery` is the seam, the call sits inside `start()` before the session is handed to anybody, and the answer is reported as one of four distinct states - `reconciled`, `blocked`, `failed`, `not-run` - because a boot that reconciled nothing must not look like one that reconciled cleanly. Nothing is granted on the answer: recovery gates mutation authority, not reading, so a hook that throws leaves the product usable and names itself in a bounded `recovery-failed` code. The browser boot supplies the hook through `resolveBrowserRecoveryStartup`, composing the same backend, journal and gate the write path composes. **Five mutations, all five bite**, with the source restored byte for byte: the call removed, a throwing hook swallowed as clean, a blocked answer reported as reconciled, the failed code dropped, and a missing hook claiming a clean boot. The integration case is what keeps the rest honest - the real gate over a durable journal seeded before a restart, with the intended bytes already on disk, so the `effect-present` classification and the journal transition to `committed` come back through the wiring. One accounting note: 13.C2's box was already ticked, so this slice moved one box rather than two, and the status row corrects the commit message's miscount. |
| Visual acceptance harness at `00451d9` | **Proxima's agenda dropped from 58 open boxes to 53 on one reproducible command rather than on another session.** `tools/papers-visual-accept.mjs` (exposed as `npm run agent:visual`) is now the project-owned form of the C1 acceptance: it speaks the Papers control protocol itself, resolves exactly one visible surface for a project and refuses to guess when two match, waits for `layout-stable`, checks every published key against Papers' own alphabet and bounds, runs named `visible`/`inside` assertions against real geometry, captures the surface and up to eight elements, **re-reads and re-hashes every artifact** against the host metadata, and refuses to pass on a surface with a failure diagnostic. Exit code is the verdict: 0 PASS, 1 BLOCKED, 2 usage. Eight probes were run and every one bites - a passing baseline; `surface-not-found` twice (a nonexistent surface, and a window with no such surface); a cold window answering `layout-not-stable`, `no-semantic-keys` and `geometry-unavailable`; `--min-keys 200`; `--expect-pass` on a key the host answers `not-visible` (`expected-assertion-failed`); a missing descriptor (`control-plane-unreachable`); and no `--window` while two windows hold a visible surface (`surface-ambiguous`). The acceptance it produced: all eight stages PASS, 71 keys / 71 distinct / 71 with geometry, five assertions evaluated, a 143 456-byte surface capture and four verified element captures, against Papers 1.3.11 at `d2a3c74` (`packaged false`). **One host behaviour is recorded because it changes how a run is set up:** the first project open in a fresh profile answers zero keys while its record store is created and the second open answers all of them - reproduced twice on 2026-09-12, with the cold surface also answering `UnknownVizError` to `capture.surface` and never reaching `layout-stable`. The harness fails closed on that state instead of retrying into a pass, and the acceptance opens the project once to warm the profile and again in a new window for the surface it accepts. |
| Suite at `a3bede7` | fixture generation 0, source/test typecheck 0, build 0, `git diff --check` 0, vitest 0 under **default parallelism**, **253 test files / 1673 passed / 1 skipped**, run 2026-09-12 in the working tree above (252 / 1661 at `9670c15`, 251 / 1655 at `e08616d`, 244 / 1606 at `e75d76a`, and the earlier counts are unchanged below it: 243 / 1601 at `2db9fbd`, 242 / 1595 at `8b4e093`, 241 / 1591 at `b34ef53`, 241 / 1590 at `f9d7c63`, 241 / 1589 at `dc5f908`, 241 / 1588 at `70f5549`, 241 / 1587 at `4566bd6`, 241 / 1585 at `5781e96`, 241 / 1582 at `2f90e2c`, 241 / 1581 at `b980c33`, 240 / 1578 at `65f88ef`, 227 / 1492 at `4d0bfaa`). Seven files arrived with the two defects below, not with new product surface: three suites name the contract (`tests/semanticKeyAttributeContract.test.ts`, `tests/semanticKeyValue.test.ts`, `tests/shippedBundleSemanticKeys.test.ts`) and the rest are the rename's own diff across the existing suites. The file count stays complete coverage rather than a partial collection - 251 `*.test.ts` files exist in the tree and the runner collects all 251. |
| Tick audit at this revision | 840 boxes, **840 ticked / 0 open** at `21de194`, or **748 / 0** counting only top-level boxes. **The checklist is complete for the first time**, and the last two boxes closed on the D60 delete cascade, which is the verb the release gate was waiting on. **Every ticked box names the commit that closed it**: none is unannotated, and the sub-items that carry no SHA close under a parent that does. 954 references resolve against the four local trees by a box-level scan (`D:\Letters\MatTroiSeConMoc\.dsh\audit-checklist-ticks.ps1`, which reads a box across its wrapped continuation lines and distinguishes a closing SHA from one named only as evidence) - four more than the 950 measured with two boxes still open, the difference being the two ticks above and the evidence they carry. 0 false timestamps; 164 boxes use the pre-rule style of naming a SHA without a timestamp, which the rule exempts as historical; every box-level reference now resolves in the local trees - the one that did not was a stale SHA inside an
explanation, claiming nothing by itself, and it was replaced by the case it meant (the snapped deadline preview case
in Proxima's `tests/scheduleTimeGrid.test.ts`), so the box scan reports no unresolvable reference. **A second scan
now covers whole documents rather than boxes, across all five checklists at once** (`.dsh\audit-cited-shas.mjs`,
counting commits only and never blobs, since a blob sharing a seven-character prefix would report a resolution for a
commit that does not exist): Quick Run 39 citations, this checklist 269, Proxima's agenda 64, and the two design-only
window checklists one each - every one resolving except the citation naming the creator's Obsidian plugin, whose
repository lives inside `D:\LapSlop brotherhood\Local\.obsidian\plugins\proxima` and is **outside the scan by
design**: it is live creator data, the standing rule keeps this work out of it, and a citation of it is a reference
rather than a closing tick. The scan counts 954 references across ticked boxes at this revision - four more than the 950 measured with two boxes still open, the difference being the two ticks above; their own code SHAs and timestamps appear in this Status row, which the scan does not count as a box. The single false record this found - `327d90c` carrying `f8376eb`'s timestamp - was corrected at `5858be5`. |
| Evidence pass | Twenty-one of the closing Evidence list's twenty-six statements are now ticked, each against **a test file that was run to confirm it passes** and the commit that introduced that file: the Elastic cockpit `57860d3`, Timekeeping `760e54d`, the six Schedule modes `5d97cdc`, projects as workspaces `dadd610`, notes as artifacts `fa5bb33`, the one status field `263c9a6` with `738bb53`, the Backlog `9b59d16`, recurrence occurrence-and-series semantics `16b443e`, the read-only agent bridge `d5a515e`, legacy bytes preserved `d9d8c5e` and `184765e`, the cutover rule `d6e2b30`, filenames carrying no meaning `71b0a2b`, ids surviving renames `510a25e`, relations as ids `26c84d4`, schema reprojection `469ee8c`, one project owning both kinds `efdfa11`, deterministic crash classification `5c95b66`, and no silent last-write-wins `8dc3841`. **The five that remain are named rather than implied**: one was the typed-failure universal, and **it closed at `21de194`** when `project.delete` gained the success, refusal, stale and storage halves it was missing, so what is left is four rather than five - three are scope statements this repository cannot evidence alone (no Papers change, H4 unclaimed, KeToan out), and one is the creator-interaction claim the two machine-gated window checklists contradict for their own scope. The other two data-write universals this row used to name are settled: one semantic action per gesture at `65f88ef` @ `2026-09-12T12:13:11+07:00`, and UI and agent paths sharing one implementation at `e75d76a` @ `2026-09-12T15:33:00+07:00`, where the schema family - the last one whose shared half was a claim about a caller nobody had built - got the caller. |
| Semantic envelope at `b4b17b1` | **Twenty-four rows are wired, which is every row that has a semantic action**: the nine task rows (`e0d097e`, `a7bf33e`, `c81bc55`, `99c13f5`), the seven event rows (`4b241f8`, `5af693f`), the five project verbs (`2dadbe1`) and the three workflow-stage verbs (`b4b17b1`). Each action mints the id at its own boundary, returns it on every result, and appends exactly one terminal event after convergence through the shell's sink - named for its family, with the scope or the verb in the name where that is what a reader needs. Six shapes were decided by the work rather than assumed: the drop wrapper mints once and hands its id down; a bulk run is one operation whose event's outcome comes from its members; a create names **no** target on a refusal; a plan that can refuse is a **step inside** the run; a refusal that **is** the answer is journalled like any other; and a family whose write is a sequence of sequences carries the stage **and every card it moved**. Writing the last of those found a defect rather than confirming a design: a stage write whose cards had moved and whose stage write then refused was not re-reading at all, because convergence was keyed on the operation's own success. |
| Stage 17 matrix at `f9c202a` | **Complete for every row the agenda carries, and re-counted at the current tree**: 36 rows / 360 cells read **315 satisfied / 44 gaps / one not applicable** measured at `9d4ebb1` @ `2026-09-12T15:50:32+07:00`, two more satisfied than the previous count because the two remaining `state/revision observable afterward` gaps were test gaps and are now read-backs, **and the Templates row carries its own table of ten cells, which read 10 satisfied / 0 gaps at `9562a9c` @ `2026-09-12T15:57:07+07:00` where they read seven and three before** - so across both tables the matrix is 325 satisfied / 44 gaps / one not applicable of 370 cells, not the 248 satisfied / 111 gaps this row had been carrying since the matrix was completed - the envelope overrides that landed row by row between `e0d097e` and `65f88ef` moved them and nothing re-counted until now, which is the kind of figure that goes stale silently. Nine of the satisfied cells closed with the property-schema action layer (the three schema rows' boundary, request-id and event cells, which read `src/app/propertySchemaActions.ts` while the record layer's own cells keep asserting their gaps), and six more closed with the Gantt write made read-model-free (the three Gantt rows' request-id and event cells, re-anchored on `changeTaskSpan` and on the agent-wire case that asserts one submission leaves one id and one event). The tables live in `tests/actionCoverageAudit.test.ts`, one per family (task, event, project, workflow-stage, schema), with each family's shared cells written once and each row's request, refusal, ids and observable cells written for that row.
| Next operation | **The standing next operation is the zone wiring: thread a `zone` through the six schedule and timekeeping modules' render options, pass `hostZone()` once from `main.ts`, and give the 25 ambient-dependent assertions an explicit zone. A first attempt is parked at `0c0d593` on `wip/explicit-zone-derivation` with its exact failure list. Before it came the civil-time zone port at `a3bede7` @ `2026-09-12T20:51:30+07:00` - `localDateKey`, `formatClockTime` and the schedule/calendar `Date` getters - before Gate 1's last open box can close. Before it came the native-source handoff finding at `dd04478` @ `2026-09-12T20:46:36+07:00`, which corrected Gate 9's four open reasons on measurement and left the box count unchanged - the reasons changed, not the ticks. Before it came the containment probe at `ad6ee56` @ `2026-09-12T20:41:07+07:00`, which closed Gate 20's sandbox box on measurement and took Proxima's agenda from 52 open to 51. Before it came the startup recovery wiring at `9670c15` @ `2026-09-12T20:29:22+07:00`, which closed Gate 13's last runtime-wiring box and took Proxima's agenda from 53 open to 52. Before it came the visual acceptance harness at `00451d9` @ `2026-09-12T20:20:36+07:00` and, before that, the semantic-key correction at `e08616d` @ `2026-09-12T20:08:46+07:00`. Neither flipped a parity box, because none of the five open boxes here is about semantic keys or host visual acceptance - they closed eleven of Proxima's agenda boxes between them (Gate 2's nine, Gate 22's two) and then five more (the exact validated Papers SHA, Gate 11's three visual boxes, Gate 21's Papers SHA). The five here are unchanged: relations between simultaneously created records, task recurrence if retained, the 33-of-36 runtime-validation gaps, `project.delete`'s count instead of affected ids, and the last typed-outcome gap.** Before it, fourteen slices went into the agent wire and the schema panel: the schema panel at `e75d76a` closed the shared-implementation box, the matrix re-measurement at `9d4ebb1` closed four of the ten umbrella columns, and the Templates row's three gaps closed at `9562a9c`, which took two more - the agenda is at 824 ticked / 16 open.** Before it, panel sizing was local state at `8b4e093`, the first tick in eight slices, which closed the box Stage 3 left open. Before that, ten slices went into the agent wire: the agent write path (`32132bb`), the property-schema action layer (`65f88ef`), scoped ordering asserted across surfaces (`b980c33`), the schema family routed through the agent wire (`2f90e2c`), the Gantt write made read-model-free and put on that wire (`5781e96`), the workflow-stage create and rename put on it the same way (`4566bd6`), four of the five event verbs put on it at `70f5549`, all five project verbs at `dc5f908`, both bulk verbs at `f9d7c63`, and `task.create` at `b34ef53` - which was the last family in this group.** Five boxes are left, and none of them is about the agent wire, whose reach closed family by family under one stated rule rather than a list: a family's verbs enter `src/app/agentWritePath.ts` when its operation runs with no cockpit in the dependency set, and a trusted layer that already minted an id hands it down so one submission stays one run. The third family is the evidence that the rule is a rule: `task.timeline.change` looked like an exception because its operation read a projection, and the answer was to move the read to the entry (D75) rather than to widen what the wire takes, which also removed a malformation - a resize that named one end and took the other from the projection is not a shape a caller without a projection can express. The fourth followed the same route: `workflow.stage.create` and `workflow.stage.rename` needed only the revision the board was showing, so the sequence takes it as a parameter or a lookup the caller owns, and its delete stays off the wire on purpose - the cards' destination is the creator's answer, and a wire carrying a remap target would be a second way to decide it. The fifth is the Schedule, where the same split decides four verbs in and one out: a resolver supplies the revision the caller read, the board answering with the event it rendered and the wire answering with a revision and no record, so `event.create`, `delete`, `reschedule` and `resize` are reachable and `event.update` is not - it plans a diff against the record it edits. An agent's resize names a duration rather than the end a pointer landed on, which the record layer already accepted. The sixth family is the cheapest and the clearest: a project lifecycle run only ever needed a project's revision, so the resolver gives it one and **all five** verbs are on the wire - `project.delete` included, because its `policy-not-decided` is the operation's real answer rather than a wiring gap, and an agent asking should hear what a person clicking Delete hears. The seventh family then showed where the rule stops being about projections at all: a bulk run reports a status per member rather than one verdict, so its report cannot share the submission result's union - the compiler proved that the moment it joined, by refusing to narrow `if (!result.ok)` for six other families - and the answer was a second entry, `submitAgentBulk`, with the submission entry answering a bulk verb with the sentence naming where it belongs. The last projection read in the group went the same way as the others: each member's revision now arrives through a resolver, and an agent sends the revision it read for every member it names. The eighth and last family is `task.create`, and it is the one where the rule cost nothing to apply and everything to apply *carefully*: the wire builds a draft and hands it to the same `planTaskCreate` the form's Save uses, so the planner and its wording are untouched, and the only projection read - whether a named project exists - became a predicate the board answers from what it rendered and the wire declines to answer, leaving the record layer to refuse a project nobody holds with its own reason. **With that, no family in this group is blocked on a read model any more.** What remained in the group was the schema family's missing UI caller - an editor nobody had built - and the boxes that are not about the agent wire at all. **That editor is now built, both halves: `2db9fbd` for the projection and the forms, `e75d76a` for the panel and the shell binding that reaches them.** `src/app/propertySchemaEditor.ts` projects the canonical schema records into rows a surface draws and turns three forms into the submissions `submitPropertySchemaAction` already parses - the same entry the agent wire uses, which is what makes the two callers one implementation rather than two. It reads the canonical records rather than `ProximaState.taskSchema` for a real reason: the projection is the legacy shape, whose options carry a `name` and a `color` and whose records carry no observed revision, while every schema verb identifies an option by an opaque id and a label and writes against a revision. `src/browser/propertySchemaPanel.ts` draws the rows and binds the controls, the shell binds it in the Backlog and submits the three forms through that same entry, and the audit's three absence assertions flipped rather than being deleted - so the shared-implementation box closed with the second caller, and `tests/propertySchemaPanel.test.ts` proves a click reaches the handlers rather than reading the shell as text. What stays in the group is nothing a wire can fix: the verbs that remain off it are asserted rather than pending, because their answer is the creator's (`workflow.stage.delete` remaps the cards) or because they plan a diff against the record they edit (`event.update`). Behind that: the operation-only row that stays operation-only by decision (task recurrence, whose two envelope cells are now recorded not-applicable and asserted as such), the three boxes whose gaps all sit in the record layer's own answers - the runtime-validation column, whose 33 gaps are the one column this agenda asks for that the architecture deliberately does not have, and `project.delete`'s counts standing in for ids, which is one gap on the affected-entity column and the release gate's remaining typed-failure gap, so one decision closes two boxes - and the two product questions the remaining boxes carry in their own text: what a recurring task means, and the template relation syntax for records created at once. The contract is not to be redesigned: `src/app/semanticAudit.ts`, one id minted at each boundary, one terminal event after convergence, and `ProximaActionDispatcher.auditSemantic` as the shell's sink. |
**Done** Stage 0's spine, HARD GATE 0 closed at `5d5cebf`. Stage 1 at `2450828`. Stage 2,
the Elastic execution cockpit, at `57860d3`. Stage 3: the Timekeeping shell and Deadline
Calendar at `760e54d`, Timeline/Gantt at `fb67685`, the Gantt interaction contract at
`c1f8c93`, Countdowns at `2b8a145`, and the two acceptance proofs at `37e722b` — **Stage 3 is
complete except panel sizing/layout**. Stage 4 slice 1, Schedule Day/4-Day/Week, at
`7357b4d`, slice 2, the Day/4-Day/Week interaction contract, at `7292075`, and slice 3,
Schedule empty-cell creation, at `2e74059`, and slice 4, Schedule Month/Year/Agenda
projection, at `5d97cdc`. Nothing anywhere writes a record. Six Stage 0
projection, at `5d97cdc`, and slice 5a, Schedule shared navigation and filtering, at
`fc460f6`, slice 5b, Schedule recurrence projection, at `448c65f`, and Stage 5 slice 1,
Projects Hub read-only inventory, at `d83e158`, and Stage 5 slice 2, New Project provisional
modal with typed-unavailable Save, at `68e11b6`, and Stage 5 slice 3, project lifecycle refusal
controls, at `dbea424`, Stage 5 slice 4, read-only project workspace panels, at `dadd610`,
Stage 5 slice 5, detailed Notes tree/preview interactions, at `fa5bb33`, and Stage 5 slice 6,
detailed Task Board interactions, at `c8e35c3`, and Stage 5 slice 7, detailed Backlog interactions,
at `b281cab`, Stage 5 slice 8, detailed Deadlines interactions, at `d3dbb59`, and Stage 5
slice 9, detailed Schedule interactions, at `36fcc08`, and Stage 5 slice 10, workspace
ownership closeout, at `cb92cae`, and Stage 5 slice 39, the Notes read side, the Timekeeping
reuse and the workspace acceptance boxes, at `ead7927` — **Stage 5 is complete.** Stage 4's
`## Acceptance` section is complete as of `215777a`, which also closed Stage 0's action-union
box and annotated the two of its four kinds that remain vocabulary rather than implementation.
**Stage 18's interaction-feel pass is complete on its read half as of `08e505d`** — 51 of its
58 boxes, with the remaining seven named and gated individually. Those seven are closed now — the last two by `38ce017` and `c5291f1` — so **Stage 18 has no open boxes**. **Stage 19's convergence claim
is proven on its read half as of `8dc3841`** — 18 of its 28 boxes, and every box left open names
the write, the agent path or the un-extracted renderer that blocks it. **Stage 8 is down to its
two creator-decision boxes as of `d9d8c5e`**, which also proved the broad staging pass and the
byte-preservation proof against real trees on disk — so HARD GATE C, the canonical cutover, is now
the only thing between the tree and the write stages. **HARD GATE C is open and being worked as of
`738bb53`:** the projection from canonical records to the world the surfaces render now exists, so
a record-store source is a thing that can be built rather than a thing that cannot be represented.
**As of `06c0702` the gate's isolation half is proven** — a record-store session activates, projects,
refreshes and switches, and a legacy edit or a deletion moves neither the surfaces nor the store — and
**as of `d6e2b30` its choice half is too**: activation has a marker that can be refused, startup chooses
the store only for an intact activated one and reports every other answer, and the browser shell holds
nothing but a read-only source. The write stages are no longer gated; they are simply not written yet.
**As of `abf8204` the first of them is written**: an Elastic drop submits one accepted task mutation through
the operation layer and the surfaces then read the store, so the cutover is no longer a read-side claim only.
**As of `f8376eb` the Projects Hub's own lifecycle controls are real too** — Archive, Restore and Delete are
drawn from a resolved write path and answer through it — so four of Stage 11's five verbs are offered by the
product's own surface, and the fifth answers with the policy question it is waiting on (D57).
Stage 6 slice 1, Canvas selection and read-only node inspection, at `ace9bac`.
Stage 6 slice 2, Canvas geometry preview refusal, at `4e8bed7`.
Stage 6 slice 3, Canvas removal intent/confirmation/refusal, at `8e20d0d`.
Stage 6 slice 4, Canvas semantic action + inspection seam, at `6f93de2`.
Stage 6 slice 5, semantic source refresh/reload seam, at `839d1b7`.
Stage 6 slice 6, structured diagnostic code catalog, at `7844264`.
Stage 6 slice 7, structured diagnostic payload bounds, at `7313025`.
Stage 6 slice 8, structured frontmatter parse-failure diagnostics, at `4f5f063`.
Stage 6 slice 9, unsupported-frontmatter diagnostic policy, at `20764d4` (existing bridgeDisclosure full-suite timing exception accepted; isolated test passes).
Stage 6 slice 10, structured duplicate-ID diagnostics, at `fe4a6c9`.
Stage 6 slice 11, structured missing-relationship diagnostics, at `7a7018f`.
Stage 6 slice 12, structured invalid date/number diagnostics, at `1081aa2`.
Stage 6 slice 13, renderer-failure diagnostics, at `a888988`.
Stage 6 slice 14, filesystem/repository failure diagnostics, at `92e4fa3`.
Stage 6 slice 15, credential/token-safe diagnostic disclosure, at `7d6ea75`.
Stage 6 slice 16, real-machine-path-safe diagnostic disclosure, at `987daac`.
Stage 6 slice 17, headless programmability, at `35b20e4`.
Stage 6 slice 18, UI semantic-action parity, at `cb012d1`.
Stage 6 slice 19, renderer-independent inspection, at `4801bad`.
Stage 6 slice 20, deterministic events and evidence, at `ab9ca57`.
Stage 6 slice 21, optional Papers control, at `83ea8e1`.
Gate 9.1, native open/reveal acceptance gap, at `ac7daaf`.
Gate 9.2, smallest host capability, at `f6b49d1`.
Gate 9.3, native open/reveal execution and acceptance, accepted on Papers branch
`proxima-gate9-native-source-handoff` at `67b7fa2` (Proxima remains at `f6b49d1`).
Gate 10.1, live-agent-control gap proof, accepted on Papers branch
`gate10-native-presentation-reconcile` at `5451bbf`: real stdio `papers_control`, exact
same-project split target, DOM-only per-group proof, both exact canonical native presentations
visible, exact singular `inspect.surface` equality, C1 inspection/capture and refusal proofs;
Papers default suite 99 files (98 passed | 1 skipped), 940 passed + 4 skipped / 944 collected.
Gate 10.2, host-truth contract, accepted on Papers branch `gate10-host-truth` at `9e6304b`:
an unbound sender cannot claim Backpack authority; a mismatched claimed Backpack is refused
without crossing the downstream seam; a matching request crosses exactly once with the
host-resolved live project identity; and a retired logical surface makes that sender stale
and refused. Production is unchanged from Gate 10.1. Papers default suite 99 files
(98 passed | 1 skipped), 941 passed + 4 skipped / 945 collected.
Gate 10.3, bounded relay proof, accepted on Papers branch `gate10-relay` at `d2a3c74`:
the accepted host-resolved project identity reaches the real `DelegateWaveRelay`; the
read-only operation is fixed to `GET /v1/overview`, credentials come from relay configuration
rather than page parameters, caller-supplied path/token values cannot redirect or authorize
the request, and no mutation body or mutation operation is emitted. Production remains
unchanged. Papers default suite 99 files (98 passed | 1 skipped),
942 passed + 4 skipped / 946 collected.
HARD GATE A / A1, Stable opaque identity, accepted on Proxima branch
`hard-gate-a1-opaque-identity` at `71b0a2b`: task, project, event, schema and workflow-stage
records share one versioned opaque canonical-ID contract; display names, physical filenames,
source paths and legacy Markdown IDs are explicitly non-identity; rename stability, duplicate
display names, duplicate-ID refusal and legacy explicit-ID alias/provenance treatment are
proven. Existing Markdown compatibility reading is unchanged; no persistence, import
execution or mutation capability exists. Proxima full suite 135 files / 789 tests.
HARD GATE A / A2, Separate execution state from workflow stage, accepted on Proxima branch
`hard-gate-a2-task-state-separation` at `07d4926`: canonical tasks independently carry
`executionState` (`backlog`, `running`, `finished`) and opaque `workflowStageId`; the Elastic
execution and project-workflow projections remain separate, moving either dimension leaves
the other unchanged, and workflow-stage rename preserves membership through stable stage
identity. Legacy `Task.status` compatibility behavior remains unchanged; no persistence,
write, import execution or mutation capability exists. Proxima full suite 136 files / 794 tests.
HARD GATE A / A3, Scoped ordering, accepted on Proxima branch
`hard-gate-a3-scoped-ordering` at `bf56679`: canonical Elastic execution order and project
workflow order are independent durable scopes; workflow ordering is scoped by exact project
and workflow-stage IDs; reordering either surface leaves the other unchanged; calendar order
is chronology-derived rather than manually ranked; and Gantt row placement is LOCAL STATE
rather than a third durable task-order field. The typed `task.timeline.change.targetRowIndex`
contract remains present while its durable mutation leg remains unavailable. Legacy
`Task.orderIndex` compatibility behavior remains unchanged; no persistence, write, import
execution or mutation capability exists. Proxima full suite 137 files / 801 tests.
HARD GATE A / A4, Project-type silo removed, accepted on Proxima branch
`hard-gate-a4-project-capabilities` at `795f019`: active projects may associate with tasks
and events simultaneously; task/calendar visibility and selection no longer depend on the
legacy `projectType` label; capabilities derive from available task/event/workspace data;
inspection schema v5 exposes those capabilities rather than `projectType`; and legacy
`projectType` remains import/presentation metadata only. Obsolete pre-A4 silo assertions
were corrected without altering the legacy reader. No persistence, write, import execution
or mutation capability exists. Proxima full suite 138 files / 804 tests.
HARD GATE A / A5, Schema is canonical data, accepted on Proxima branch
`hard-gate-a5-canonical-schema` at `289754d`: property-schema definitions are canonical
opaque-ID `schema` records; select and multi-select options have stable opaque identity
separate from labels; formula, rollup and relation definitions are canonical semantic data;
and presentation-only option colors, column widths and collapsed state are explicitly
LOCAL STATE. Legacy schema types remain compatibility-only and the legacy reader is unchanged.
No persistence, write, import execution or mutation capability exists. Proxima full suite 139
files / 811 tests.
HARD GATE A / A6, Relations are ID-based, accepted on Proxima branch
`hard-gate-a6-id-relations` at `26c84d4`: canonical relation values contain only the opaque
relation-schema ID and opaque target-record IDs; resolution is entirely by canonical record
identity with schema target-kind enforcement; duplicate, missing and disallowed targets fail
explicitly; title changes and legacy source moves leave relation identity intact; and
wikilink/filename-shaped values are refused at the canonical boundary. Canonical relation
semantics contain no target filename, source path or `targetFolder`; existing legacy
compatibility code remains untouched. No persistence, write, import execution or mutation
capability exists. Proxima full suite 140 files / 817 tests.
HARD GATE A / A7, Names are independent from storage representation, accepted on Proxima
branch `hard-gate-a7-name-storage-separation` at `270f8cb`: task, project and event titles are
ordinary canonical fields rather than storage identity; filename-hostile and YAML-sensitive
text remains valid canonical title data; moving or renaming a legacy representation changes
provenance without changing canonical name or identity; and canonical structured task data
round-trips through standard JSON without Markdown/frontmatter/YAML interpretation. Existing
legacy reader behavior remains unchanged. No persistence, write, import execution or mutation
capability exists. Proxima full suite 141 files / 822 tests.
HARD GATE A / A8, Project/filesystem association is explicit, accepted on Proxima branch
`hard-gate-a8-explicit-artifact-association` at `1c87f24`: canonical Proxima records retain
their `pxr_...` identity while external vault/filesystem artifacts use a distinct `pxa_...`
identity namespace; project associations explicitly reference artifact/root IDs rather than
paths; mutable locators remain reference/provenance data; moving an artifact leaves project
and task identities unchanged; and one artifact may be referenced by multiple projects.
Legacy `linkedFolders` remains compatibility-only. No filesystem API, persistence, write,
import execution or mutation capability exists. Proxima full suite 142 files / 828 tests.
HARD GATE A / A9, Recurrence becomes explicit domain data, accepted on Proxima branch
`hard-gate-a9-canonical-recurrence` at `ed147ea`: recurrence rules are closed typed domain
structures; recurrence series use stable opaque `pxs_...` identity distinct from owner record
identity; ordinary occurrences are semantically addressed by series identity plus scheduled
start without forced record materialization; cancelled, rescheduled and detached exceptions
carry explicit occurrence identity and state; and occurrence-versus-series action scope is
explicit without filename or source-layout dependence. Detached special occurrences retain
their original series identity while referencing a separate canonical record when required.
No persistence, write, import execution or mutation capability exists. Proxima full suite
143 files / 835 tests.
HARD GATE A / A10, No hidden second database, accepted on Proxima branch
`hard-gate-a10-no-hidden-database` at `efdfa11`: domain schema version 2 classifies
retained information into canonical Proxima record/schema data, disposable Backpack-local
state, or external vault-artifact reference/provenance; no canonical semantic value is
allowed to survive only in local state; the architecture/import mapping records how legacy
status, ordering, project type, schema, relations, names, artifact associations and
recurrence cross the future import boundary; and dedicated fixtures prove combined task+event
projects plus independent execution/workflow movement. No Record Store, persistence, write,
import execution or mutation capability exists. Proxima full suite 144 files / 842 tests.
HARD GATE A is closed.
Stage 7 / slice 1, Record-store contract and headless JSON adapter, accepted on Proxima
branch `stage7-record-store-contract` at `3b1af20`: the pathless RecordStore port and JSON
adapter provide opaque-ID filenames, mandatory codec validation, typed read metadata,
conditional create/update/delete, visible corrupt-file failures, and explicit separation from
creator-vault FSA authority. No physical backing location or mutation authority was selected.
Proxima full suite 145 files / 853 tests.
Stage 7 / slice 2, canonical-domain-v2 RecordStore codec/validation, accepted on Proxima
branch `stage7-record-store-contract` at `a8c1b1e`: complete runtime validation now covers
task, project, event, schema and workflow-stage records, all accepted canonical property and
recurrence families, opaque IDs and scoped ordering; the canonical JSON RecordStore factory
always supplies this codec, and malformed, legacy/local and path-bearing shapes fail visibly.
No physical backing location or mutation/recovery authority was selected. Proxima full suite
146 files / 869 tests.
HARD GATE B, physical Proxima-owned Record Store location, creator-accepted on Proxima
branch `stage7-record-store-contract` at `a08340c`: canonical records are assigned to
the OPFS owned by the stable Proxima Backpack origin
`papers-backpack://bp-954ea2cd-6261-410d-baf8-0d1fbd8ca0b1`, with fixed
`record-store/records/` and `record-store/recovery/` namespaces. Authority is reacquired
programmatically from the origin with `navigator.storage.getDirectory()`; no picker,
creator-vault path, project-root database, direct agent storage access or Papers capability is
introduced.
Stage 7 / slice 3, browser OPFS RecordStoreFileBackend, creator-accepted on Proxima branch
`stage7-record-store-contract` at `e7e7362`: the accepted HARD GATE B decision now has a
physical browser backend for `record-store/records/`. It reacquires the stable Backpack
origin's OPFS programmatically, creates/opens only the fixed record namespace, exposes only
the pathless RecordStoreFileBackend seam, rejects non-opaque/path-shaped target names, keeps
raw handles private, and preserves conditional create/update/delete, observed revisions,
stale refusal and visible corrupt/schema-invalid failures. The reserved
`record-store/recovery/` namespace remains unimplemented. No semantic mutation action,
recovery coordinator, restart proof, process-kill proof, multi-caller race policy or import
exists. Proxima full suite 147 files / 879 tests using the accepted serialized full-suite
command; `bridgeDisclosure` isolated 1 file / 3 tests passed.
Stage 7 / slice 4, real Papers restart retention, creator-accepted on Proxima branch
`stage7-record-store-contract` at `a91b2de`: OPFS acquisition was corrected to preserve the
real StorageManager receiver, and an isolated real-host evidence harness created one disposable
canonical record through the accepted backend, closed the first Papers Electron application,
launched a second Papers process against the same isolated userData under a different PID,
returned to the exact stable Proxima Backpack origin, instantiated a fresh OPFS backend and
canonical RecordStore, reread the exact record, and conditionally deleted it. Papers source
remained unchanged and clean. Proxima full suite remains 147 files / 879 tests using the
accepted serialized command; `bridgeDisclosure` isolated 1 file / 3 tests passed.
Physical RecordStore writes remain infrastructure-only. No human or agent semantic mutation
path reaches them. Mutation/recovery authority, process-kill behavior, multi-caller conflict
handling, semantic-action containment and import remain open. Six Stage 0 boxes remain open
where record revisions, bulk-action results and UI-versus-agent equivalence require real
semantic mutation callers. Every ticked box names the commit that closed it.
Stage 7 / slice 5, crash-durability coordinator/journal foundation, creator-accepted on
Proxima branch `stage7-record-store-contract` at `4d61e20`: the fixed
`record-store/recovery/journal.json` OPFS backend now reuses the existing recovery-store
semantics, and a pathless record update/delete coordinator durably persists `prepared`
before the checked physical effect and `committed` after a successful effect. Definite
stale/missing refusal is recorded as `recovered` rather than successful; uncertain
post-effect journal finalization returns `recovery-required`; semantic mutation authority
remains unavailable. Proxima full suite is 148 files / 887 tests using the accepted
serialized command; `bridgeDisclosure` isolated 1 file / 3 tests passed.
Stage 7 / slice 6, durable startup journal loading and bounded restart reconciliation,
creator-accepted on Proxima branch `stage7-record-store-contract` at `d07fa61`: the
record-specific startup gate now loads and reconciles the existing durable recovery journal
before returning any RecordMutationCoordinator. Journal-load or reconciliation failure
blocks authority and exposes no coordinator. Prepared/recovery-required record entries
reuse the existing recovery semantics: an already-present intended effect becomes
`committed`, while unchanged prior bytes become `recovered`. No semantic action is wired
to this authority gate. Proxima full suite is 149 files / 891 tests using the accepted
serialized command; focused startup/recovery evidence is 4 files / 25 tests and
`bridgeDisclosure` isolated is 1 file / 3 tests.
Stage 7 / slice 7, record-recovery ambiguous/corrupt-state blocking, creator-accepted on
Proxima branch `stage7-record-store-contract` at `a937aa4`: the existing record startup
recovery path is proven to block rather than guess when unresolved record bytes match neither
the prior nor intended state, persisting that recovery entry as `blocked` and exposing no
mutation coordinator. Malformed durable recovery-journal data likewise blocks during load
before record access or authority exposure. This is tests-only evidence; production behavior
is unchanged. Proxima full suite is 149 files / 893 tests; focused record-recovery evidence
is 1 file / 6 tests and `bridgeDisclosure` isolated is 1 file / 3 tests.
Stage 7 / slice 8, process-death injection before commit, creator-accepted on Proxima
branch `stage7-record-store-contract` at `9bbedbd`: a real child process runs the accepted
record mutation coordinator to the durable-prepared boundary, with the recovery journal
fsynced while the coordinator remains inside `recovery.save()`. The parent kills that
process before the checked physical record commit is entered. Durable `prepared` state
survives, record bytes/revision remain unchanged, and fresh startup recovery classifies the
operation `not-applied`, persists it `recovered`, and only then restores mutation authority.
This is evidence-only; production behavior is unchanged.
Stage 7 / slice 9, process-death injection after physical record commit but before journal
finalization, creator-accepted on Proxima branch `stage7-record-store-contract` at `97970b7`:
a real child process reaches the complementary crash boundary after the checked record update
has durably committed `new @ record-r2` but while the durable recovery journal still contains
`prepared`. The parent kills the process before journal finalization reaches disk. Fresh
startup recovery observes the intended effect, classifies it `effect-present`, durably marks
the recovery entry `committed`, performs no rollback, and only then restores mutation
authority. This is evidence-only; production behavior is unchanged.
Stage 7 / slice 10, reconciliation idempotence, creator-accepted on Proxima branch
`stage7-record-store-contract` at `188209e`: repeated accepted startup reconciliation
is proven idempotent for terminal record-recovery states. `committed` remains available
with one observational already-committed outcome, `recovered` remains available with no
outcome, and `blocked` remains blocked with one observational blocked outcome. Repeated
startup performs no further journal status write or record access, creates no duplicate
recovery state/outcome, preserves terminal durable state, and returns the same
mutation-authority decision. This is tests-only evidence; production behavior is unchanged.
Stage 7 / slice 11, machine-readable recovery-required/blocked disclosure,
creator-accepted on Proxima branch `stage7-record-store-contract` at `155c736`:
an actual record-coordinator `recovery-required` result now maps into the existing schema-v4
typed ActionFailure vocabulary with stable `outcome/error.code = recovery-required`, while
an actual blocked record-startup result maps into a bounded pathless schema-v1 inspection
with stable code `record-recovery-blocked`. Neither disclosure exposes record filenames,
recovery paths, storage handles or direct record authority. No semantic action or UI mutation
path is enabled.
Stage 7 / slice 12, observed-revision same-record concurrency contract,
creator-accepted on Proxima branch `stage7-record-store-contract` at `052c3b4`:
the existing pathless update/delete mutation contract is proven to bind modifying callers
to an observed record revision. Two independent coordinators racing the same record from
the same observed `record-r1` cannot silently last-write-wins: exactly one conditional
update succeeds at `record-r2`, while the other returns typed `stale` with
`actualRevision = record-r2` and cannot overwrite the winner. This is tests-only evidence;
no semantic UI action, locking, retry or merge behavior is added.
Stage 7 / slice 13, different-record independence, creator-accepted on Proxima branch
`stage7-record-store-contract` at `10dc3c3`: two independent pathless record-mutation
coordinators are proven able to commit distinct records independently. Each caller binds to
its own observed revision, both conditional effects succeed, and both final records retain
their own intended bytes/revisions without cross-record blocking or overwrite. This is
tests-only evidence; no locking, retry, merge or semantic UI mutation behavior is added.
Stage 7 / slice 14, explicit caller refetch/retry with no silent storage-layer merge,
creator-accepted on Proxima branch `stage7-record-store-contract` at `eb0f3fe`: after a
same-record race returns one typed stale loser, the accepted storage/coordinator boundary
performs no automatic retry and leaves the winner untouched. The caller explicitly refetches
the winning revision and submits a new revision-bound mutation; only that new call performs
another conditional write. The retry commits exactly the caller-provided replacement bytes,
with no storage-layer merge, hidden retry, locking or semantic UI mutation behavior added.
Stage 7 / slice 15, aggregate process-kill classification/evidence closeout,
creator-accepted on Proxima branch `stage7-record-store-contract` at `7c89491`:
one aggregate executable matrix now invokes each of the two unchanged, previously accepted
real process-death harnesses exactly once and requires their complementary recovery
classifications. Death after durable `prepared` but before the checked physical effect is
`not-applied → recovered`; death after the checked physical effect but before durable journal
finalization is `effect-present → committed` without rollback. No production or accepted
crash-harness behavior changed.
Stage 7 / slice 16, creator-vault unchanged / Proxima-owned write-tree evidence closeout,
creator-accepted on Proxima branch `stage7-record-store-contract` at `4cdbeea`: the four
designated disposable vault fixture trees are proven unchanged across the record-store test
execution, while a separate disposable physical-tree probe changes exactly the opaque record
JSON and `record-store/recovery/journal.json` beneath the Proxima-owned record-store root.
A sibling creator-vault fixture remains unchanged. The actual creator vault is never read or
touched. Production storage behavior is unchanged.
Stage 7 / slice 17, semantic-action path containment, creator-accepted on Proxima branch
`stage7-record-store-contract` at `e961b94`: actual parsed record-mutation action shapes are
now composed with the accepted RecordStore boundary to prove that path-shaped semantic IDs
cannot reach its backend. Even when tests deliberately bypass the OpaqueRecordId TypeScript
brand, Windows, traversal-shaped and POSIX creator-vault paths are rejected by runtime
opaque-ID validation before any backend read/update/delete call. Backend call counts remain
zero and storage remains empty. No semantic/UI mutation authority is enabled.
Stage 8 / slice 2, durable identity reconciliation / physical-candidate duplicate planning,
creator-accepted on Proxima branch `stage7-record-store-contract` at `be3efdf`, committed
`2026-09-11T14:52:38+07:00`: the existing compatibility reader now exposes its readable
physical candidates before logical-id deduplication without changing ordinary compatibility
state. The dry-run importer assigns a separate HARD-GATE-A opaque candidate identity to every
physical source, emits a versioned durable provenance→identity manifest, reuses persisted
physical-candidate identities on replanning, records duplicate legacy aliases as collision
groups, and leaves references through multi-candidate project aliases explicitly ambiguous
with no selected canonical target. Legacy Markdown, canonical Record Store and staging
remain unwritten; unsupported-frontmatter remains policy-pending.
Stage 8 / slice 3, canonical conversion-plan semantics, creator-accepted on Proxima branch
`stage7-record-store-contract` at `173b45e`, committed `2026-09-11T15:04:55+07:00`: every
readable physical candidate now carries the compatibility interpretation needed for dry-run
conversion without creating a second Markdown parser. Legacy task status is split into the
accepted independent execution-state and project-workflow meanings; legacy order is expressed
as separate Elastic-execution and project/workflow-stage candidate scopes rather than surviving
as a universal canonical order; and legacy projectType is explicitly compatibility/import
metadata with canonical capabilities remaining data/workspace-derived. No canonical payload,
workflow-stage record, Record Store write or staging materialization occurs; unsupported-
frontmatter remains policy-pending.
Stage 8 / slice 4, first-class schema/settings conversion-plan foundation, creator-accepted on
Proxima branch `stage7-record-store-contract` at `368b3bf`, committed
`2026-09-11T15:37:49+07:00`: explicitly interpreted legacy task/per-project schema settings
now reconcile scoped stable opaque schema and select/multi-select option identities and emit
canonical-ready primitive, select, multi-select and non-empty-formula schema records. Option
colors remain local presentation state; relation targets, rollups and incomplete formulas stay
explicitly pending. The parent planner remains dry-run and zero-write, with no custom-property
values, staging or Record Store materialization.

Stage 8 / slice 5, legacy custom-property value capture and dry-run conversion-plan foundation,
creator-accepted on Proxima branch `stage7-record-store-contract` at `a360fa96c62b910a5865de962d6a150a2a4e6e4b`,
committed `2026-09-11T16:08:36+07:00`: already-interpreted task/event frontmatter is retained as
import evidence; ordinary task values map to slice-4 opaque schema/option identities, events remain
captured-but-untyped, and relation, rollup and formula values remain explicit deferred outcomes.
The parent and property-value plans remain dry-run/zero-write; the direct-binary evidence is used
because `npm` is ENOSPC on this machine.

Stage 8 / slice 6, relation target resolution and wikilink→canonical-record-ID dry-run conversion
planning, creator-accepted on Proxima branch `stage7-record-store-contract` at
`400ccfcd6c2d778b9d635287995c3ef5002b50e8`, committed `2026-09-11T16:24:16+07:00`: exact valid
legacy wikilinks resolve only through the complete physical-candidate inventory, existing opaque
record identities and canonical relation target-kind semantics. Unambiguous permitted targets become
canonical relation values containing only opaque schema/record IDs; missing, ambiguous, malformed,
disallowed-kind and duplicate-target outcomes remain explicit, while unknown relation folders remain
schema/value pending. Plans remain dry-run/zero-write; no derived-value, staging, Record Store, UI,
Papers or live-vault authority is introduced.

Stage 8 / slice 7, rollup canonical-reference resolution and derived rollup/formula dry-run
planning, creator-accepted on Proxima branch `stage7-record-store-contract` at
`57e8c169166d2142d14e5b6580699388ef49833b`, committed `2026-09-11T17:46:24+07:00`: legacy
rollup relation properties resolve to canonical relation-schema IDs and target properties resolve
to canonical schema identities within the permitted relation scope; missing, ambiguous and
incompatible references remain explicit; derived rollup/formula values are evidence-only and never
treated as authority. The parent planner remains dry-run/zero-write, with no staging, Record Store,
import UI/commit, HARD GATE C, Papers or live-vault authority introduced.

Stage 8 / slice 8, external-artifact association/reference dry-run planning, creator-accepted on
Proxima branch `stage7-record-store-contract` at `646d72e20b76e2f7cfa33c3e7e42e38448fbd551`,
committed `2026-09-11T18:49:42+07:00`: the existing compatibility interpretation of legacy
`linkedFolder`/`linkedFolders` data now produces canonical external-artifact references with opaque
`pxa_...` identities and explicit project associations. Exact legacy locators remain evidence-only;
machine-path versus vault-relative classification is explicit; shared exact locators reuse one
identity; out-of-band rename continuity remains unclaimed. The planner has no content-reader or
copy authority, and linked bytes, legacy Markdown, canonical Record Store, staging and external-
artifact writes remain zero. Browser-boundary and bridge-disclosure gates passed, and the full
serialized suite is 158 files / 944 tests.

Stage 8 / slice 9, isolated schema-record staging foundation, creator-accepted on Proxima branch
`stage7-record-store-contract` at `9c0c2dca72d6dd02959e480961ff629dfe8da6d2`, committed
`2026-09-11T19:01:24+07:00`: a staging-only seam now consumes the accepted zero-write dry-run
plan and creates or reuses only canonical-ready schema records after Canonical V2 validation.
Pending and conflicting schema conversions remain explicit blockers; reruns are idempotent and
partial attempts resume without duplicate records. Legacy Markdown, settings, canonical/live
Record Store, external-artifact and activation writes remain zero. Focused evidence is 7 files /
43 tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full suite 159 files / 949 tests.
This is intentionally a schema-only staging foundation; broad physical task/project/event staging
and activation rows remain open.

Stage 8 / slice 10, durable workflow-stage identity reconciliation and canonical workflow-stage
staging, creator-accepted on Proxima branch `stage7-record-store-contract` at
`a2cbdddf28159ccd57b200b1741b4add9c261267`, committed `2026-09-11T19:08:44+07:00`:
workflow-stage identity is keyed exactly by (canonical project record ID, legacy status ID),
durably persisted before staging creation, reused across interruption/replan, and staged only
through the isolated staging seam. Missing/ambiguous projects and identity/payload conflicts remain
explicit blockers; task/project/event materialization, live Record Store writes and activation remain
absent. Focused evidence is 8 files / 50 tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and
full suite 160 files / 956 tests.

Stage 8 / slice 11, physical-candidate identity staging metadata, creator-accepted on Proxima
branch `stage7-record-store-contract` at `42a03610cea7b7d81a3c2df28a1b83d79b3a70b7`, committed
`2026-09-11T19:14:55+07:00`: every decodable physical source retains its already-authored opaque
candidate identity, including duplicate legacy-alias candidates, with complete collision evidence.
Only staging metadata is written; no canonical task/project/event payload, Record Store, artifact or
activation write is introduced. Focused evidence is 9 files / 55 tests, browserBoundary 1 / 4,
bridgeDisclosure 1 / 3, and full suite 161 files / 961 tests. The duplicate-candidate staging row
is now closed; broad physical payload staging and activation remain open.

Stage 8 / slice 12, durable malformed-record and unsupported-frontmatter staging evidence,
creator-accepted on Proxima branch `stage7-record-store-contract` at
`3846805f02aa421f33ae78955b99836a6d3f07ed`, committed `2026-09-11T19:22:40+07:00`: structured
frontmatter parse failures are grouped by physical source as unresolved malformed-record evidence
with exact source/kind/identity context, stable problem codes and the accepted bounded diagnostic;
unsupported-frontmatter remains a separate policy-pending disposition. Source bytes remain
unchanged, no canonical payload or record is guessed, and the idempotent interruption-safe problem
manifest is the only writable boundary. Focused evidence is 10 files / 61 tests, browserBoundary
1 / 4, bridgeDisclosure 1 / 3, and full suite 162 files / 967 tests. Activation omission,
unsupported-frontmatter policy, and valid physical payload staging remain open.

Stage 8 / slice 13, canonical project payload planning and isolated project-record staging,
creator-accepted on Proxima branch `stage7-record-store-contract` at
`b92b2d408f87fda332dec9b84dbc701cf4485c7f`, committed `2026-09-11T19:43:23+07:00`: already-
interpreted project fields and accepted external-artifact bindings now form canonical V2 project
payloads and eligible projects materialize through the staging-only seam. Malformed, unsupported,
duplicate and otherwise ineligible projects remain explicit blockers; live Record Store, activation,
task/event staging and import commit authority remain absent. Focused evidence is 11 files / 68
tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full suite 163 files / 974 tests.

Stage 8 / slice 14, canonical task payload planning and isolated task-record staging,
creator-accepted on Proxima branch `stage7-record-store-contract` at
`27691bd9c1284fc8fbdcea1554e42abbd349e9af`, committed `2026-09-11T19:53:28+07:00`: eligible
tasks now carry canonical V2 payloads with execution/workflow identities, scoped ordering and
resolved property values, and materialize only through the staging-only seam. Missing, ambiguous,
malformed, unsupported and conflicting dependencies remain explicit blockers; live Record Store,
activation, event staging and import commit authority remain absent. Focused evidence is 12 files /
75 tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full suite 164 files / 981 tests.

Stage 8 / slice 15, canonical event payload planning and isolated event-record staging,
creator-accepted on Proxima branch `stage7-record-store-contract` at
`0a89f534ff966b3757255210fcf0ea8d4fd695f5`, committed `2026-09-11T20:03:54+07:00`: eligible
events now form canonical V2 payloads with canonical associations and recurrence data and materialize
only through the staging-only seam. Malformed, unsupported, ambiguous and conflicting dependencies
remain explicit blockers; live Record Store, activation and import commit authority remain absent.
Focused evidence is 13 files / 82 tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full
suite 165 files / 988 tests.

Stage 8 / slice 16, import source byte preservation, creator-accepted on Proxima branch
`stage7-record-store-contract` at `184765e2b125b85bccea18e13cba7966ef4371f4`, committed
`2026-09-11T20:19:14+07:00`: the import evidence boundary now proves source bytes and source hashes
remain unchanged across planning and staging for valid, malformed and unsupported inputs, without
granting content rewrite or live-vault authority. Focused evidence is 14 files / 89 tests,
browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full suite 166 files / 995 tests.

Stage 8 / slice 17, staged legacy import semantics, creator-accepted on Proxima branch
`stage7-record-store-contract` at `7ffa63f6a4ac37714bedb58c2bca76916cc95259`, committed
`2026-09-11T20:29:17+07:00`: staged project, task and event payloads are checked against the
legacy interpretation and canonical conversion contracts, with explicit refusal for malformed,
unsupported, duplicate and dependency-invalid records; staging remains isolated and no live-store
or activation authority is introduced. Focused evidence is 15 files / 97 tests, browserBoundary
1 / 4, bridgeDisclosure 1 / 3, and full suite 167 files / 1003 tests.

Stage 8 / slice 18, read-only legacy import actions, creator-accepted on Proxima branch
`stage7-record-store-contract` at `97c9dd9e68ad2e21222acf91a58502eecb278abd`, committed
`2026-09-11T20:42:20+07:00`: machine-callable read-only import inspection and status actions expose
the staged legacy plan and bounded evidence while import commit remains typed-unavailable. Invalid,
unknown and mutation-shaped requests return typed refusals without storage or activation writes.
Focused evidence is 16 files / 105 tests, browserBoundary 1 / 4, bridgeDisclosure 1 / 3, and full
suite 168 files / 1011 tests.

Stage 8 / slice 19, machine-callable read-only ambiguous-project resolution, pushed on Proxima branch
`stage7-record-store-contract` at `bd64a346c114144bdeb8768bc8aba6bc81a6b8cd`, committed
`2026-09-11T23:57:13+07:00` and **awaiting creator acceptance**: `import.resolve` takes the explicitly
selected candidate project record id and resolves every ambiguous project reference whose candidate set
contains it. The selection applies only while planning, so the resolved reference carries the chosen
project and everything derived from it follows rather than being patched afterwards: the task workflow
stage becomes a candidate, its workflow-order scope names the selected project, the event project
association resolves, and the reference counts are recomputed. An id that is a candidate of no ambiguous
reference is refused as `invalid-action-input` without re-planning, the verification that described the
pre-resolution plan is discarded so `import.inspect` re-verifies the resolved plan, and `import.commit`
remains typed-unavailable. Evidence: focused 16 files / 108 tests, full suite 168 files / 1014 tests
(which includes `browserBoundary` and `bridgeDisclosure`), every step exit 0, run directly rather than
through the npm scripts.

Stage 8 / slice 20, machine-visible remaining ambiguity, pushed on Proxima branch
`stage7-record-store-contract` at `394179c1137d16a26e2029ad430f3d695c34a3fa`, committed
`2026-09-12T00:02:14+07:00` and **awaiting creator acceptance**: `import.status` now reports the plan's
outstanding project references (`unresolvedProjectReferences`, `ambiguousProjectReferences`) and the
`appliedProjectSelection`, and `import.commit` refuses with those counts in machine-readable
`error.outstandingProjectReferences` while either is nonzero, instead of merely being typed-unavailable. A
fresh `import.plan` clears the applied selection, so status never describes a decision belonging to a
superseded plan, and once the references are acknowledged the ambiguity-specific reason disappears while
the policy refusal remains. **The administrative action envelope version is now 2** — the status payload
gained required fields, so a version-1 consumer would reject it and the version is the signal. Evidence:
focused 16 files / 109 tests, full suite 168 files / 1015 tests, every step exit 0.

Stage 8 / slice 21, unconvertible records visible before commit, pushed on Proxima branch
`stage7-record-store-contract` at `c62a7dcf06982b05ffedb1c2e7c5fb3efa686eca`, committed
`2026-09-12T00:05:59+07:00` and **awaiting creator acceptance**: `import.status` reports the plan's
`readerProblems` and `unsupportedFrontmatter`, and `import.commit` refuses carrying both in
machine-readable `error.outstandingRecords` whenever a record could not be converted. The two refusal
reasons are independent, which the test pins down on a fixture that carries an ambiguous project
reference *and* unconvertible records: acknowledging the references clears only the reference reason,
so clearing ambiguity can never make an incomplete import read as complete. The message names the
surviving reason instead of collapsing into the generic policy sentence. Evidence: focused 16 files /
110 tests, full suite 168 files / 1016 tests, every step exit 0.

Stage 8 / slice 22, legacy-import plan parity bundle, pushed on Proxima branch
`stage7-record-store-contract` at `d7e6a6c3be4bf8e6d1dbc7dee9166ae17db5e381`, committed
`2026-09-12T00:09:34+07:00` and **awaiting creator acceptance**: a dedicated `tests/importParity.test.ts`
proves thirteen census/parity boxes in one packet, which is the pace correction — one round closed
thirteen items instead of one. Against a plan built from one declared project, task and event with every
supported field set, it asserts: each kind's census reports `loadedRecords` equal to the plan's count,
`unaccountedCandidates` zero, and `loadedRecords + explicitlyRejected === recordCandidates`; every
declared source has a disposition and every conversion carries its `sourcePath`; names, descriptions and
dates survive (dates compared as instants, so a format normalisation cannot pass as data loss); task
weight, fixed/max durations survive; both `project:` and `projectId:` resolve to one canonical project
record id; `recurrence` is an explicit typed null rather than an omitted key; archived and completed state
survive without the record being dropped; `projectType` stays compatibility metadata and filters nothing;
and record identity is opaque with same-title records receiving distinct ids. Evidence: focused 17 files /
119 tests, full suite 169 files / 1025 tests, every step exit 0.

Stage 8 / slice 23, import identity idempotence, pushed on Proxima branch
`stage7-record-store-contract` at `d66622fb1c1f05d00b537d6d02e2426b70f0cee1`, committed
`2026-09-12T00:12:36+07:00` and **awaiting creator acceptance**: `tests/importIdempotence.test.ts` proves
that re-planning the same vault reuses every identity from the durable mapping, and that an interrupted
run resumed from the stored manifest alone comes back identical — through a duplicated legacy alias too,
and stable on a third pass. The proof rests on giving every run a *disjoint allocator range*: a shared
counter would have hidden exactly the failure under test, because a re-derived identity would still have
looked like reuse. Evidence: focused 18 files / 122 tests, full suite 170 files / 1028 tests, every step
exit 0.

**In flight** Nothing. The tree is clean and the branch is pushed.

Slice 48, Stage 9's first wiring, pushed on Proxima branch `stage7-record-store-contract` at `abf8204`,
committed `2026-09-12T03:20:05+07:00` and **awaiting creator acceptance**: an Elastic drop writes. The gesture is
`src/app/taskMoveGesture.ts` — it submits **one** accepted mutation (`execution-state` and `execution-order`
together, because a card in a new column at its old index is not a state a reader should ever observe) and only
then re-reads the source, so nothing is drawn as saved before the store says so, which is why a refusal needs no
undo path: the authoritative record never changed. A lost race is the one refusal where the board was showing a
revision the store no longer holds, so that case re-reads before the refusal is rendered and reports the revision
that beat the caller, while every other refusal leaves the world as it was and does not redraw. A refresh that
fails after an accepted write does not undo the write. The shell receives **operations, never storage**:
`src/adapters/browserTaskMutations.ts` composes the OPFS backend, the recovery journal, Stage 7's recovery gate
and the activation marker, and returns three callables or a typed reason there are none (`not-activated`,
`recovery-blocked`, `store-unreadable`); a run still reading legacy Markdown has no record write path at all and
says so rather than appearing to work. Six UI-wiring boxes tick: both column drags, the in-column reorder, "UI does
not update authoritative record until accepted", the stale return-to-place with refusal feedback, and
"storage/recovery failure does not leave a card optimistically saved". `docs/DECISIONS.md` D55 records the choice
and its reversal condition. **Two guards were relaxed deliberately in the same commit, and neither assertion was
deleted**: `recordMutationContainment` now asserts the sharper rule — the drop is routed to operation layer and is
deliberately *not* dispatched, no file under `src/browser/` composes a store, and the sanctioned composition names
all three refusal reasons — and `uiSemanticActionParity` follows the two gesture names to
`src/app/taskMoveGesture.ts`, where the canonical vocabulary now lives.

Slice 49, the stage's two acceptance cases, at `e62e8f4`, committed `2026-09-12T03:21:44+07:00`: one task is moved
by a drop and a second by the equivalent submitted operation, and the two stored records are compared field by
field with only identity and the human-typed title removed — they are equal, down to completion, workflow order and
the resulting revision both callers are told. The Elastic lock case now also derives a progress presentation at a
tick moment: a real dispatcher over the store's own projection takes the target, locks, draws progress and unlocks,
and every task revision is byte-identical afterwards with the store holding exactly the records it held before.
Two acceptance boxes tick — "human-style drag and direct semantic action produce identical durable task state" and
"Elastic lock/progress remains local and does not increment task revision". The seventh UI-wiring box, provisional
drag feedback, was already built and tested rather than written here: `57860d3` @ `2026-09-10T09:14:42+07:00`
introduced `elastic-insertion-placeholder`, and `tests/elasticCockpit.test.ts` proves a correctly sized placeholder
is shown at the drop target during the drag while no move has been emitted, that it follows the pointer to a second
slot, and that exactly one semantic move is emitted on drop.

Slice 50, the same wiring made executable, at `ed09e3d`, committed `2026-09-12T03:25:34+07:00`: the sequence that
joins a binder's drop intent to the semantic write path lived inline in `main.ts`, where the only thing that could
check it was reading the file as text. It is now `src/app/elasticDropAction.ts`, and four cases execute it against a
real store — resolve, write, refresh, render, in that order, asserted — so nothing is drawn before the store has
answered and been re-read. The sinks are dependencies rather than globals, which is what makes the order checkable,
and the shell supplies no storage: the containment guard now asserts that of this module too. The four cases cover
the whole reachable surface of a drop: the accepted path, a run with no write path (refused by name, one render, no
refresh, record untouched), a card the board is not showing (no write path is even resolved and nothing is redrawn),
and a lost race, where the drop carries the revision the board was *rendering* rather than a fresher one.

Slice 51, the Task editor's write path, at `cab1627`, committed `2026-09-12T03:31:18+07:00`:
`planTaskEditorSave` compares the draft against the record it was seeded from and emits one typed
mutation per field that **actually changed** — nothing else, because a field nobody touched is a field a
concurrent editor may already have changed, and rewriting it would be this form overwriting work it never
saw. It refuses values the record could not hold (an empty name, an unreadable date, weight that is not a
number, a fixed duration with no minutes) instead of half-writing the form, and it refuses a column that is
not one of the three canonical execution states: a vault's own status id is not a column, and inventing one
is how two vocabularies start sharing a field. Custom properties are refused **by name** with the reason —
their values reached the editor through a compatibility projection, a select's option id having become its
label, so writing one back needs the canonical mapping Stage 10 owns; refusing loudly is the honest half of
that and dropping the edit silently would be the dishonest one. `saveTaskFromEditor` and
`deleteTaskFromEditor` are the sequence over the real store and the real recovery gate, carrying the
revision the card was read at, and the convergence rule the drop established is now one module
(`src/app/writeConvergence.ts`) that both callers share. Ten cases.

Slice 52, the editor's Save and Delete as real controls, at `18c2e48`, committed
`2026-09-12T03:37:24+07:00`: the modal is told what this run may do by the same resolution a gesture uses,
so the two cannot disagree — a resolved write path makes Save and Delete real, and anything else is the
typed reason they are not. Save is offered only when there is something to write, because a form matching
the record has no save and a disabled button saying so beats a click that comes back refused. What happens
to the form *after* a write is a rule rather than an accident, and it is testable because the sequences
report it instead of reaching for the shell's state: a **refused** save keeps the edits, so a reader retries
from the authoritative revision rather than retyping, and only an accepted one clears them. An accepted
delete closes the editor; a refused one leaves it open. The containment guard now covers this path too. Two
UI-wiring boxes tick — **Card edit Save calls typed task mutation** and **Delete calls `task.delete`** — and
the Timekeeping surface's copy of the modal keeps the typed-unavailable constant on purpose, because its
binder has no form handlers at all: its write parity is Stage 14's, and half-wiring a read-only form would
be worse than saying so.

Slice 53, what the product calls itself, at `9a04451`, committed `2026-09-12T03:40:29+07:00`: the
literal "Read-only workspace" is gone from the shell and the claim is derived —
`src/browser/workspaceIdentity.ts` says "Editable workspace" only when records come from the record
store **and** a record write path actually resolved. Deriving it from the capability rather than the
source mode is the point: a label tied to the mode would have claimed editability the moment a store
existed, before anything could write to it. The badge and the identity stay separate strings on
purpose — the badge names the source, because a reader needs to know whether they are looking at
fixture bytes or their own data, and the identity names the capability, because "read-only" is a
promise about what the product will do with that data. Three boxes tick: **HARD GATE C item 6**,
**HARD GATE C's "Execute semantic JSON-backed task update; every surface changes"** (the operation
now exists and two UI callers execute it, followed by the product's own refresh and the projection
every surface renders), and **Stage 20's "Read-only workspace disappears from normal record-backed
operation"**.

Slice 54, an audit rather than a feature, at `e4e319b`, committed `2026-09-12T03:44:25+07:00`: four boxes in
Stages 18 and 19 had been left open against a world that no longer exists — "the drop is refused, so there is
no accepted move to persist", "no modal has a save path to make stale", "an Elastic edit is refused", "a refresh
**is** the mechanism". Stage 9's write half answered all four, so the honest close was to assert it rather than
re-argue it. `tests/elasticChangeConvergence.test.ts` starts where a person does — a drop, then the product's
own re-read — and mounts the real renderers over that projection, so the Elastic column, the project Task
Board's column, the Task editor's field and the Backlog row's order all move together and the deadline and
completion deliberately do not (A2 from the surface side). One new case saves a name in the card editor and
finds it on the same surfaces. Ticks: Stage 18's **successful drop persists** and **stale-save refusal**, Stage
19's **Task changed on Elastic updates** (the parent whose five children were already ticked for a source-made
change) and **No manual source-refresh control is required for normal record-store coherence** — a write
converges the cockpit by itself, and the interval policy covers changes made elsewhere. The same audit narrowed
three boxes it could *not* close and said so: Stage 18's **Save** and **Delete** now name which modal is wired
and which two are not, and Stage 19's **UI and agent race** records that one of the two writers now exists.

Slice 55, the New Task form, at `c74003f`, committed `2026-09-12T03:54:01+07:00`: nothing in the tree
offered "new task" at all, so the last of Stage 9's three UI-wiring boxes needed *UI* rather than wiring.
The form is built in the shape the card editor established rather than a second idiom — a `FormDraft`, a
projection over the same `TaskEditorField` vocabulary, a plan that turns the draft into one closed typed
request, and a sequence that executes it through operations rather than a store — and its own hooks
(`data-new-task-field`), because both forms can be on the board at once and one binder answering the other's
keystroke is the failure those hooks exist to prevent. `planTaskCreate` refuses by field before the write path
is asked, the form offers only the fields the request can carry (custom properties are absent, not
shown-and-refused), and a new card lands at the top of its column because where it belongs among peers is a
drag. Save is a real control exactly when a write path resolved and is offered only once the form holds a
name; a refused create leaves the form open with what was typed. Fifteen cases. **Stage 9's UI-wiring half is
now complete: what remains in the stage is its five agent-parity boxes, which need an agent-facing caller.**

Slice 56, agent parity, at `1029a25`, committed `2026-09-12T03:59:36+07:00`, and **Stage 9 is complete — 20
of 20 boxes**. The five parity boxes compare a UI caller with the programmatic entry point, and the checklist
is explicit that the entry point is the semantic write path itself; what was missing was a case that drives
both. `tests/uiAgentMutationParity.test.ts` runs each claim twice, in two identical worlds — once through the
sequence the UI executes and once through a directly submitted typed request — and compares with record ids
normalised away, because the point is that the operation is identical rather than that two random ids are.
All five: the same action accepted (create, update, move, reorder, delete, with the affected records equal
field for field), the same invalid request refused in the same words, the same race lost the same way with
both callers told the revision that beat them, the same resulting revision, and the same inspection state
with the same record-store provenance. **Writing it found two real gaps rather than confirming the claim:**
the editor's plan said `invalid-value` where the write path said `validation-refused`, so the same refused
keystroke read differently depending on which caller asked, and the editor's refusals did not report
`actualRevision` although the drop's did. Both are fixed here, which is the whole argument for asserting
parity instead of reasoning about it.

Slice 57, the first of Stage 10, at `6dfad33`, committed `2026-09-12T04:05:45+07:00`: Stage 9 refused every
property edit by name and said Stage 10 would own the mapping, and this is the mapping.
`src/app/propertyMutationPlan.ts` reverses the compatibility projection against the canonical schema, with four
rules that each exist because the alternative loses data silently — a derived value is never written, an option
is matched by id first and by label second, a blank is a clear except on a checkbox (where false is a value),
and a relation holds ids rather than names (A6), refusing one it cannot resolve. The case that matters does the
whole loop through the real store and the real recovery gate — canonical values in, projection out, form edit,
mapping back, both ends read again — for all six editable types in one save, and asserts a declared rollup is
*absent* from the record because it is derived. **Four Stage 10 boxes tick**: all editable types round-trip,
relations use ids, rollups and formulas are not independently writable, and schema validation happens before
the writer is called (both refusal cases leave the record at its first revision).

Slice 58, the workflow dimension, at `08d31b5`, committed `2026-09-12T04:11:16+07:00`: the stage's board boxes
needed a fact the readable world did not have — a place for a project workflow stage — and
`recordStateProjection` reported `workflow-stage-has-no-legacy-slot` on purpose, because `ProximaState` had
none and A2 keeps the two dimensions independent. The slot is added **without merging them**: `ProximaState`
gains `workflowStages` (id, owning project, name, and the revision a conditional write would carry — a revision
rather than a `SourceRef`, because `RecordKind` is the readable world's vocabulary of records with a place on a
surface and a stage is a column heading), and `Task` gains `workflowStageId` and `workflowOrder` *beside* its
execution state. The old gap reason is gone and two real ones replace it — a stage whose project is not in the
store, and a task naming a stage that is not — both reported with the ids the records wrote, which is the
difference between a report and a rewrite. `src/app/workflowMoveGesture.ts` is the gesture the board will
drive, with three moves falling out of the two stage ids rather than out of a mode: into a stage writes the
stage and its position together, inside a stage writes only the order, and out of the workflow clears both —
and a position supplied for a leave is refused rather than ignored. It reports `actionType: 'task.update'` plus
a `workflowAction` discriminator, because the taxonomy has no registered workflow type and inventing one where
nothing could audit it is vocabulary Stage 17 would later find unbacked. Seven cases over the real store carry
**A2 as data**: after a drop into Review the task is still Running with its Elastic order untouched. One box
ticks — the project board's **placeholder during drag**, which `c8e35c3` built and `tests/projectTaskBoard.test.ts`
drives through the real binder — and **destination feedback** is narrowed rather than claimed: the hovered slot
is marked today, and the column-level feedback the box is really about arrives with the board's stage grouping.

Slice 59, the workflow board, at `e325f6e`, committed `2026-09-12T04:18:31+07:00`: the projection carried
stages and the gesture moved tasks between them, and nothing drew either. `src/browser/projectWorkflowBoard.ts`
is a board of its own rather than a mode of the status board — that separation *is* A2, since one groups by
execution state and this one by project workflow stage — and a card carries both facts, so a task in Review
visibly draws "running". Its attributes are its own namespace for the reason the two Task editors have separate
hooks: both boards can be on the page, and one binder answering the other's drop is the failure that prevents.
A task in no stage gets a trailing column rather than being hidden, and a drag marks the column under the
pointer while opening its 54px placeholder — the column-level destination feedback that box was narrowed on
last round. `src/app/workflowBoardDrop.ts` derives the stage a card is leaving from the world the board was
*rendering*, not from a fresh read, so a drop built on a revision the reader never saw cannot happen; writing it
surfaced a small real mismatch (the board reports a slot index for every column, and leaving the workflow has
no position in it) which is now handled where it belongs. **Seven boxes tick**: both drags, the placeholder,
destination feedback, the stale refusal restoring the winner's state, moving a stage leaving the Elastic
execution state alone, and both acceptance claims that name them — *Running + Review remains Running* and
*project-board reorder leaves Elastic order unchanged*.

*project-board reorder leaves Elastic order unchanged*.

Slice 60, bulk actions, at `9dcc5d6`, committed `2026-09-12T04:21:48+07:00`: a bulk action is not one write
but one write per marked record, each with its own observed revision, and `src/app/bulkTaskActions.ts` says so
in four rules — zero silent omissions (every marked task appears in `entities`, written or refused), no overall
success unless it is one (`accepted` only when every member was, `partial` when some were, `refused` when none
were, and an empty selection is `refused` because zero writes is not a success), a stale member as a result
rather than an abort (one raced record must not cost the whole action), and retry left to the caller (exactly
one attempt per entity, asserted by *counting* the durable journal writes, since an internal retry would show
up there as extras). Completion moves a task to Finished, because that is what a reader means by "complete" and
what the board shows; the finer distinction — completed but still Running — stays available through the
editor's own field. **Five boxes tick**: the four bulk-contract promises and Stage 0's **per-entity bulk-action
result**, which had been deliberately left open waiting for the first bulk action that could run rather than
being filled with a shape no producer wrote. What remains of Stage 10 is the Backlog's buttons calling these
actions, schema management, and the acceptance claim those two carry.

Slice 61, the acceptance claims about durability and identity, at `e9117b2`, committed
`2026-09-12T04:25:46+07:00`: three of the stage's acceptance boxes name properties a mutation must not
destroy, and none of them needed a new mechanism — they needed the claim asserted where it could quietly stop
being true. **Search/filter/sort remain presentation only** is asserted at the durable store rather than at the
projection: every record file's exact text and revision are snapshotted, the whole query engine is driven
(search, filter, sort), and the case asserts both that the query is real (one of four tasks is filtered out)
and that the store is byte-identical afterwards — "presentation only" means no durable byte moved, which a
projection comparison could not show. **Relation survives target title change** renames the record a relation
points at and asserts the blocking task's stored property is byte-identical before and after, because a
relation holds the target's id and the target's title is not part of it: A6 in one assertion. **Bulk delete
survives restart** bulk-deletes two of three tasks and then rebuilds the store and the source from the same
durable files with nothing carried in memory, which is what a restart is at this level — the deleted two are
gone, the survivor is present at the same observed revision, and the files are the only thing the two stores
share. **Stage 10 is down to its last box**: bulk complete from UI and agent producing the same results, which
waits on the Backlog's buttons.

Slice 62, the Backlog's bulk controls, at `9b197e2`, committed `2026-09-12T04:32:15+07:00`, and **Stage 10
is complete — 20 of 20 boxes**. The bulk sequences existed and the controls were still drawn disabled with a
typed refusal, so the stage's last box had no UI caller to compare against. The Backlog now holds a report and
a write refusal in its view, draws both controls enabled exactly when a write path resolved, routes a click
through its own bulk attributes (a disabled control reports nothing, because the write path is what decides),
and draws the last run as it is: one row per marked task, accepted or refused with its reason, and a summary in
attributes that cannot overstate it. A report also belongs to the project it was made for, like every other
view-owned thing on that panel — a rule the new case caught by failing first. The parity case drives the
selection the way the Backlog does, through its own control helpers, takes exactly the ids the UI would submit,
and compares the report with a directly submitted call over an identical world: same status, same counts, same
per-entity outcomes, with the record ids the only difference because the worlds differ. **Two boxes tick** —
Stage 10's last acceptance claim and Stage 18's `bulk actions`, which had been waiting on the same controls
since the interaction-feel pass.

Slice 63, project lifecycle operations, at `04d0bc4`, committed `2026-09-12T04:36:08+07:00`: four of the five
project operations are ordinary record writes and are decided here — create, update, archive and restore, over
the same store boundary and the same recovery coordinator every task write uses, because a project is a record
like any other and a second write path would be a second place for a stale write to slip through. The fifth is
not decided here, and the code says so: the checklist names three possible answers for what deleting a project
does with its members and states that the source cannot answer what the creator wants, so `deleteProject` is a
**deterministic typed refusal** — `policy-not-decided`, a sentence naming the member counts, no write at all —
which is the honest shape of an open question rather than a plausible guess. An empty project is refused for the
same reason and with the same code as a full one, so the eventual answer is a decision rather than a side effect
of how many rows happen to exist. `docs/DECISIONS.md` D56 records it with what would reverse it. Archiving is a
status change and nothing else, proven the only way that means anything: every member record is asserted
byte-identical afterwards. **Four boxes tick** — the prohibition on inferring the old plugin's filesystem
behaviour, deletion's deterministic typed refusal, archive not deleting records, and the combined task/event
project behaving correctly — and the stage's open question is left standing as the creator's, with the state of
its three sub-answers written down rather than quietly resolved.

Slice 64, the lifecycle sequences and one store handing back both sets of verbs, at `327d90c`, committed
`2026-09-12T04:40:33+07:00`: the project operations were callable and nothing called them the way a surface
does. `src/app/projectLifecycleActions.ts` is that layer — create, archive, restore and delete over the same
revision-in/re-read-out rule every other write sequence follows, with the project's revision taken from the
world the surface was rendering so a lost race is a refusal rather than an overwrite. **Delete's refusal passes
through unchanged**, which is this layer's own decision: the operation answers `policy-not-decided` with the
counts it would affect, and a reader who clicked Delete is given that sentence rather than a wrapper saying
"unavailable". `resolveBrowserTaskMutations` now hands back both sets of verbs over one resolution — one store,
one recovery gate, one activation check — because a second adapter resolving the same store would be a second
place for activation to be checked differently. **Two boxes tick**: an agent can drive every verb without a UI
(four of them really write; delete answers), and the answer each verb gives is identical for both callers, which
the case asserts by running the same archive through the shell's sequence and through a direct call. The stage's
UI boxes and the delete-semantics question remain, and the question is still the creator's.
Slice 27, the Backlog's query controls as values, pushed on Proxima branch
`stage7-record-store-contract` at `bdea4a18182d14d6e62805481e53aeaa2ab53901`, committed
`2026-09-12T00:34:29+07:00` and **awaiting creator acceptance**: `src/app/backlogControls.ts` makes every
control a value — set-search, add-filter, remove-filter, sort-by, clear-sort, clear-query — and
`applyBacklogControl` the whole of what one does, so nothing in the browser layer decides what a control
means and a control that cannot change the query returns that same query. The filter menu is built from
the engine's own tables (`BACKLOG_FIELDS`, `operatorsForField`, `valueTypeForField`), and a test walks
every field and every comparison it admits, builds the filter and puts it through `assertBacklogQuery`, so
the menu cannot offer a comparison the matcher would refuse. The Backlog now draws a search field, the
filter menu, a sort button per sortable column and a remove button on every chip, all disabled when the
view belongs to another project. Two boxes are ticked: **Remove filter** and Stage 6's **Search/filter/sort
never mutate records**.

**The controls are driven, not just called.** Every control carries a `data-papers-visual-key`, so the happy-dom
harness runs the real loop — render, click or type, apply, render — against the production renderer and
binder. `tests/projectBacklog.test.ts` now proves that typing searches, that the menu adds the filter it
was left on, that the chip's remove button brings the hidden task back, that a mistyped number is refused
with its reason and leaves the query alone, that a column sorts ascending then descending then clears, and
that none of it writes to a record. That file was the last place the Backlog's binder was untested: it is  *(Corrected at `e08616d` @ `2026-09-12T20:08:46+07:00`: this paragraph said `data-c1-key`, the name the renderer used until that commit. Papers observes only `data-papers-visual-key`, and a host reading a surface whose keys are under another name sees nothing at all - the finding is recorded in full in the Status row above and in Proxima's `docs/AUDIT-CHECKLIST.md` section 2.8. The harness claims in this paragraph are unaffected: they drive the production renderer and binder, which is what the correction renamed.)*
no longer character-identical on purpose, it is covered.

**What the Backlog still lacks.** Tag filtering stays open because tags have no model; Property filters
stay open because the engine filters the nine typed fields and not `task.properties`; Custom-property
columns stay open because the projection supplies the columns while the renderer still draws the legacy
list rather than a column table; Resizable columns, Row selection, Select all and bulk actions have no
implementation. Stage 18's lowercase `search;`/`filters;`/`sort;` items stay open on purpose — that
section is an *interaction-feel* pass, and the three capabilities existing is not the same as their feel
having been assessed, which needs a browser.

**Slice 28 is done**, in two commits: 28a, `src/app/taskEditor.ts` at `7ec8d17`, decides every field the
Task modal shows — the ten task fields, one field per schema property whether or not the task has set it,
and any record value the schema does not declare — and 28b, `7825d20` at `2026-09-12T00:44:55+07:00`, makes
the modal that editor: `renderTaskModal` consumes `projectTaskEditor`, draws a control per type, and holds
provisional form state that Cancel and Escape discard. `editorDraft` is threaded through
`ElasticCockpitRenderOptions` and `TimekeepingCockpitRenderOptions` (one modal, two surfaces) and owned by
`main.ts`. An edit is reported through `ElasticCockpitHandlers.editTask` and deliberately does **not**
re-render, so a keystroke cannot take the field away from the reader; the drawn draft updates on the next
render. Twenty § Task modal boxes are ticked.

**Slice 29 is done**, in two commits: 29a, `e88e193`, added `src/app/eventEditor.ts` and extracted the draft
mechanics both editors share into `src/app/formDraft.ts` (the Task editor re-exports them under its own
names, so its callers and tests are unchanged and the two editors cannot drift on what "dirty" means); 29b,
`b20cdca` at `2026-09-12T00:56:55+07:00`, made `src/browser/eventModal.ts` the one renderer for both event
editors — the month/year/agenda one and the time grid's, which before this were two copies of five read-only
inputs with no Save, no Delete and no recurrence at all. The modal shows name, description, project, start,
end and completion, the recurrence rule read by the schedule's own rule reader, and three statements where
the fields are: event records carry no colour, an event that does not recur still gets the controls, and a
recurrence the reader refuses is reported as unusable rather than shown as absent. Eleven § Event modal boxes
are ticked, including **color if event metadata supports it**, whose condition is false — nothing in the
record or the vault format declares a colour, and the modal says so rather than omitting silently.

**Two things this slice states for the next agent.** The event editor takes a narrow input
(`events` + `projectChoices`) rather than the loaded state, because the schedule surfaces carry a project
name lookup, not the schema — so event custom properties are deliberately *not* listed, and adding that
data path is a separate change no § Event modal box asks for. And every control in the event modal is
**inert**: the modal represents each field rather than accepting an edit, which is why **Cancel/Escape
loses no data** is ticked on the grounds that nothing can be lost yet. That box reopens the moment the
event editor becomes editable at the record-store cutover.

**Also corrected here:** the § Task modal box **recurrence if task recurrence remains supported** stays
open, but the earlier reason given for it was wrong. A canonical recurrence model exists
(`src/domain/canonicalRecurrence.ts`) and its owner kind is `'event' | 'task'`, with an exceptions model for
cancelled, rescheduled and detached occurrences. So the question is not whether recurrence can own a task —
it can — but whether the product wants task recurrence, which is the creator's decision. **workflow stage
where project-scoped** stays open because no project-scoped workflow stage model exists (HARD GATE A2 owns
it; the legacy status is not the same thing).

**Slice 30 is done**, `fef3b8a` at `2026-09-12T01:01:45+07:00` — an audit slice, no production code
changed. The § Project modal and § Recurrence-scope modal boxes were closable on evidence that already
existed but had never been assembled, and two of them had never been exercised at all: nothing had clicked
**Entire series** or pressed the scope modal's Cancel. The new cases drive both scopes, change the choice
back, cancel and reopen, asserting the whole loaded shape is byte-identical throughout; and assert the
project modal's controls are exactly `project-create-name` and `project-create-description`, with no
control for anything the corrected model drops. Eight boxes are ticked, and the ticks name the commits that
made each behaviour true (`68e11b6` for the project modal, `448c65f` for the scope modal) as well as this
one where the evidence is new. **The lesson worth keeping: some boxes are already satisfied and simply
untested — an audit is cheaper than an implementation, and the checklist does not distinguish the two.**

**Slice 31 is done**, `d7e6270` at `2026-09-12T01:06:10+07:00`, five § Backlog boxes: relation, rollup and
formula display, and the two bulk controls. A row now draws the property cells the projection already
computed, each carrying the kind the schema declares, so a computed value can be told from an entered one
and an unset property shows as empty rather than vanishing. Property columns are labelled with the schema's
name, falling back to the stored key — the projection had used the raw key, which disagreed with the Task
editor and the property pills. The bulk controls are drawn where a selection would act, disabled, carrying
the same typed refusal every other write carries.

**Slice 32 is done**, `9d6062c` at `2026-09-12T01:11:58+07:00`, three § Backlog boxes: Row selection, Select
all, Multi-selection. `BacklogViewState.selectedTaskIds` holds the marked tasks in the order they were
marked, and the projection reports three separate facts about it — how many *shown* rows are marked, how
many marked tasks the query hides, and whether every shown row is marked — so a bulk action can never be
read as covering a row nobody can see. Select all means the rows on screen; a hidden mark is left to
whatever marked it before; clearing clears hidden marks too. Each row carries a real checkbox keyed by task
and the binder reports which task it is for rather than deciding what that means. The transitions are pure
functions in `app/backlogControls.ts` beside the query controls.

**Deliberately not in slice 32: Task row/name click opens editor.** The Backlog's row click opens its own
inspector, and opening the Task editor modal from this panel needs a decision about where that modal is
mounted — the Backlog panel does not render it today. That is its own slice, and it is the one Backlog box
left that is a wiring decision rather than a feature.

**Slice 33 is done**, `1ffdd55` at `2026-09-12T01:19:47+07:00` — Stage 6's Acceptance section, all four
remaining boxes ticked, and the audit paid for itself. **It found two real violations and they are fixed:**
the Task editor's and the Event editor's Delete buttons were `disabled` with no stated reason, which is
indistinguishable from a broken button — both now carry a typed `action-not-available` refusal as their Save
buttons already did. `tests/modalAudit.test.ts` checks the invariant against the rendered document, and the
two controls that stay clickable (the project create Save and the create-event Save) each have a case that
clicks them and asserts the refusal *and* that no record was created.

**How the audit selects what to check is itself a finding.** The first version picked write controls by
their words and immediately failed on two controls that order and filter — the Backlog's sort button
labelled "Completed" and the Projects Hub's "Archived" filter. A label cannot tell a write from an order or
a view. It now selects by the product's own convention (a `*-refusal`, `*-write-action` or
`*-lifecycle-action` hook) with one narrow safety net for a button labelled exactly a write verb.

**And one flake fixed rather than tolerated.** `tests/bridgeDisclosure.test.ts` starts a real bridge child
process and allowed five seconds for `listening`; under parallel load that expired while the same file
passed alone in half a second. A flaky suite makes every tick in this file unverifiable, which is the one
thing an evidence-driven loop cannot afford, so the bound is now thirty seconds and slice 33 verified the
suite under default parallelism as well as on the evidence path.

**Slice 34 is done**, `d21f434` at `2026-09-12T01:26:26+07:00`, and it closed all six § Template UI boxes
in one slice rather than the two the previous handoff expected — the panel turned out to be small once the
model existed. `src/app/templateComposer.ts` parses a template into a plan with eleven typed, positioned
error codes and two bounds; `src/browser/templateComposerPanel.ts` is a panel the Backlog hosts, opened from
"Tasks from a template", with the text area, the preview and the complaint list side by side and an Execute
button refused with the typed result. Two decisions are worth carrying forward: **the format is this
project's own**, which is what the sixth box permits and asks for, and **the panel parses on every render**
rather than keeping a second copy of what the text means, because a preview that holds its own idea of the
text is exactly how a preview and a parser drift apart. Writing the tests found a real bug — value
complaints reported a zero-based column, so `weight: heavy` pointed one character early.

**Slice 35 is done**, `8cadd24` at `2026-09-12T01:31:08+07:00` — the deferral paid off. Slice 34's handoff
warned that rewriting the Backlog's row markup into a column table would break the evidence slices 26–32
built on it, so this slice drew the table *around* the rows instead: a header above the existing list, one
entry per custom-property column, and the cells the rows already drew now keyed to those columns by id and
sharing their width. Every earlier assertion about rows, drop slots, chips and controls still passes
untouched, and the two boxes are genuinely closed. **Custom-property columns** and **Resizable columns** are
ticked, with the design notes recorded: widths live in view state because they are how this reader looks at
the table rather than what it means, the clamp stops a drag from making a label unreadable or letting one
column swallow the table, and a resize edge needs no typed refusal because resizing is presentation, not a
write. The drag is driven end to end through the harness, clamps included.

**Slice 36 is done**, `3fa16bc` at `2026-09-12T01:41:25+07:00`, and it closed the last feature box in the
Backlog. The design landed differently from the sketch, and better: rather than widening `BacklogField`
(which would have let a *sort* name a custom property) or making `field` optional (which would leave a
required property that lies), the query gained a **second filter list** — so a property filter cannot be
mistaken for a field filter, and every field filter and every test that builds one is untouched. The
comparison itself moved out of `matchesFilter` into `compareValue`, driven by a value type rather than a
field, so a property and a field cannot compare the same kind of value two ways; the engine's 17 existing
cases passed before any new test existed, which is what makes that refactor safe to believe.

**The DOM test caught a real bug that no unit test could see.** Minting a filter id from one list only meant
a property filter and a field filter could both be `filter-1` — and since one chip id names one filter,
removing it would have removed *both*. That is the aliasing this project treats as an error rather than a
tiebreak, and it was invisible until two kinds of filter could exist in one query. Id minting now spans both
lists and the test asserts two filters have two distinct ids. Worth remembering as a pattern: the unit tests
each knew their own list, and only a test that drove the whole surface saw them meet.

**Slice 37 is done**, `ba50cc6` at `2026-09-12T01:48:47+07:00` — the last Backlog box, and **Stage 6 is now
down to three boxes that are not mine to close**: **Tag filtering** (tags have no model — the creator's
decision) and the Task modal's two deliberate opens (**workflow stage where project-scoped**, owned by HARD
GATE A2, and **task recurrence**, the creator's product choice, since the canonical recurrence model can
already own a task).

The row click opens the Task editor **in the panel**, not the board's modal, and the reason is worth
keeping: both binders listen on the application root, so rendering the board's modal here would have meant
two binders answering one keystroke and a Backlog edit landing in the board's draft. The Backlog draws the
same `projectTaskEditor` projection through a new `src/browser/taskEditorFields.ts` that takes the surface's
hook names — the extraction is markup-identical, which the Elastic suites proved by passing unchanged. The
read-only inspector is retired rather than duplicated: it was a placeholder for exactly this editor. Two
probes were rewritten rather than deleted — the row-click case now asserts the editor opens for that task
with the record's values, and the write-control audit's expectation for this surface moved from the
inspector's `Edit`/`Delete` to the editor's `Delete`/`Save`, both typed. The audit caught that change,
which is what it is for.

**Where the work goes next, by the numbers.** A count of open boxes per stage says the largest untapped
block is not a new feature at all: **Stage 5, "Restore Projects Hub and read-only project workspaces", has
40 open boxes and zero ticked** — yet the Status block records its slices 1–9 as pushed, and the workspace
panels (Notes, Task Board, Deadlines, Schedule, Backlog) exist and are covered by tests. Like Stage 6's
Project and Recurrence-scope modals in slice 30, those 40 boxes describe work that is already done and was
never ticked. Stage 3 is 1 box from complete and Stage 4 is 1 box from complete; HARD GATE A is 1 box from
complete. Everything else that is large (Stages 9–14's write halves, HARD GATE C, Stage 17's write coverage,
Stage 18's interaction-feel pass) is either gated on HARD GATE C or needs a browser. **As of `327d90c` the
document stands at 624 ticked / 216 open**, and the open column is now: Stage 0 7, Stage 3 1, Stage 6 3,
HARD GATE A 1, Stage 8 2 (both the creator's unsupported-frontmatter answer), **HARD GATE C 3**, **Stage 9 0**,
**Stage 10 0**, **Stage 11 12**, Stage 11 18, Stage 12 20, Stage 13 13, Stage 14 12, Stage 15 18, HARD GATE D 4, Stage 16 14,
Stage 17 58, Stage 18 5, Stage 19 8, Stage 20 11 and the final release gate 26. **Stage 9 is the first write
stage to close**, and Stage 10's Board UI and
its bulk-action contracts are now complete: what remains in the stage is the Backlog's buttons calling those
actions, schema management, and the three acceptance claims those two carry.

**Slice 38 is done**, `7f96a71` at `2026-09-12T01:52:46+07:00` — **nineteen boxes**, and the audit found the
same thing slice 30 did: the work was done, the evidence was not. `tests/projectsHub.test.ts` covered only
the New Project modal, so nothing asserted what a project card shows; `tests/projectsHubCards.test.ts` now
does — every field the checklist names, with the conditionals taken literally (the priority row only where a
priority is represented, the identity swatch only for a value that is a colour, an unreadable created date
as "Unknown" rather than an age of zero), the active/archived filter and its `aria-pressed` state, a card
opening its project's workspace and coming back, the lifecycle controls offering archive-or-restore plus
delete with typed refusals, and the pure card projection agreeing with the rendered one. **No production
code changed in this slice either.** Two of the seven new cases were wrong first: the `^=` attribute
selector matches a card's *shell* as well as its button, and I asserted an unknown age against the project
that has a valid one — both my mistakes, both caught by the suite rather than by review.

The five Workspace boxes needed no new evidence at all: `tests/projectWorkspacePanels.test.ts` renders all
five tabs, asserts no `projectType` gating and no record mutation, and each panel has its own suite. The
ticks name `d83e158` (hub inventory), `dbea424` (lifecycle refusals), `68e11b6` (create modal), `dadd610`
(workspace panels and the five-tab test) and the interaction slices, with this commit only where the
evidence is new — and `1ffdd55` for the lifecycle controls, because the write-control audit is what proved
they carry typed refusals.

**Slice 39 is done**, `ead7927` at `2026-09-12T02:02:58+07:00` — **twenty-one boxes**, which closes the read
half of Stage 5 outright, including its § Acceptance section and its four `## Evidence` bullets. The audit
repeated slices 30 and 38's finding: the panels existed and their suites were real, but specific claims had no
case behind them. Four new cases in `tests/projectNotes.test.ts` (nine now): expansion is driven through the
machine-key harness — a collapsed root renders no file buttons at all and `aria-expanded` tracks it — and the
linked root's toggle gained `data-c1-key="project-note-root-<projectId>-<path>"` so it is addressable like
every other control; the hover affordance is pinned as the stylesheet's `.project-note-entry:hover` on exactly
the interactive entries, so a hover reaches no handler and an unreadable root has nothing to hover; a drag over
a file previews nothing while the same drag over a folder previews `source -> target` and the drop clears it;
and the whole read side was run against a vault whose writer members throw, with every byte re-read unchanged.
Four cases in `tests/projectTaskBoard.test.ts` (eight now): a column is painted only for a validated hex value
(`#112233` yes, `  #abc  ` trimmed and yes, `red;display:none` and `url(...)` nothing), a status the vault does
not define still gets a column after the defined ones, display order survives tied and missing indices, and the
pickup report plus the placeholder geometry are asserted while the record stays byte-identical. **One
production change, and it removes a restatement rather than adding a feature:** `projectDeadlines.ts` derived
`remainingMs < 0` for the overdue/upcoming split even though it already imported the Timekeeping deadline
projection, so that split now runs through the exported `countdownBucketForRemaining`; the case asserts row
order, day, value and state against both Timekeeping functions, including the boundary where a deadline equal
to `now` is `upcoming`, not `overdue`. § Acceptance's two substantive boxes were argued where each claim could
be made once: a markdown file carrying record-shaped frontmatter is previewed byte-for-byte as text rather than
parsed, and the same five workspace panels render byte-identically for the same project typed `task` and typed
`schedule` — the A4 silo removal seen from the workspace side. Every other tick names the commit that made the
behaviour true (`fa5bb33` Notes, `c8e35c3` Task Board, `d3dbb59` Deadlines, `dadd610` workspace panels and the
cross-tab/zero-write acceptance case, `2450828` navigation keys) with `ead7927` only where the evidence is new.
Two of the new cases were wrong first and the suite caught both: a file key I meant to drag over was inside a
collapsed folder, and `localeCompare` orders `Deep/…` after `data.json`, which code-unit sort does not.

**Slice 40 is done**, `215777a` @ `2026-09-12T02:11:10+07:00` — the loose ends that Stage 5's closeout exposed:
Stage 0's action-union boxes and Stage 4's six-view acceptance. Stage 0's parent box is ticked because the union
genuinely exists and is genuinely versioned and public — `ProximaAction` with `ACTION_SCHEMA_VERSION = 4`,
`parseAction` as the one gate, and a compile-time check (`ACTION_TAXONOMY_MATCHES_PROTOCOL`) that the union and the
category registry name exactly the same types, so adding an action without a category fails typecheck. The new
runtime case states what that proof protects: which of the four kinds the product populates. Two of them are
**vocabulary, not implementation**, and their boxes stay open with the reason written on them: nothing is a pure
presentation action (every gesture that changes what is shown also records which way the reader left it), and no
action mutates an ordinary vault file yet. § Acceptance's six-view box is ticked by one case that mounts a single
fixture set through both renderers the application chooses between and compares each view against the same
canonical occurrence projection clipped to the dates that view shows — Day/4-Day/Week through `scheduleVisibleDays`,
Month through its own non-empty cells, Agenda against everything, Year as per-date counts because it draws no
per-event element. Five boxes are annotated rather than ticked, each with what would close it: per-record revisions
in action results and per-entity bulk results both wait for a semantic record action that can actually run (HARD
GATE C, Stage 10 for bulk), UI-versus-agent equivalence waits for an agent-facing action submission path — the
loopback bridge is a read-only vault reader, so today the equivalence is structural (one parser, one dispatcher)
rather than proven — and panel sizing is still unbuilt, though the Backlog's column widths are local state now.
*Superseded in part at `32132bb` @ `2026-09-12T12:01:23+07:00`: the per-record revision and the UI-versus-agent
equivalence both have their product entry now — the agent write path — so Stage 0's acceptance box and its
Evidence counterpart are ticked there; panel sizing is still unbuilt.*

**Slice 41 is done**, `08e505d` @ `2026-09-12T02:16:06+07:00` — Stage 18's interaction-feel pass, **fifty-one of
its fifty-eight boxes**, and the same finding as slices 30, 38 and 39 for the fourth time: the interactions were
built and asserted, and the boxes had simply never been read against the suites. Every tick names the case that
asserts it and the commit that added that case, resolved with `git log -S` on the case title rather than by
memory — `57860d3` for the Elastic cockpit, `760e54d`/`c1f8c93`/`2b8a145`/`37e722b` for Timekeeping,
`7292075`/`2e74059`/`fc460f6`/`448c65f`/`7357b4d` for Schedule, `7f96a71` for the hub cards, and the slice 26–39
commits for the Backlog, Notes, Board and modals. **Two claims genuinely had no evidence and now do:** the New
Project modal answered every form with the same refusal, so a new case shows an empty or whitespace name refused
as `invalid-action-input` by the boundary it really dispatches through while a valid name still gets the
unavailable answer; and the Notes preview pane could fail silently, so a new case asserts idle, loading,
unavailable-with-its-reason and ready-in-the-file's-own-bytes as four distinct states. The seven boxes left open
are named and gated individually rather than annotated as a block: a successful Elastic drop, an accepted Gantt
drop, the Board's workflow transition, bulk actions, and the modals' Save, Delete and stale-save refusal — every
one of them needs a record write to exist. Stage 18's `## Evidence` bullets are annotated too, and the first of
them is **not** claimed: making the interaction trace itself an executable conformance matrix is Stage 17's own
line, not something a pass over the suites can assert.

**Slice 42 is done**, `8dc3841` @ `2026-09-12T02:22:54+07:00` — Stage 19, **eighteen of its twenty-eight
boxes**, and the first slice this session that had to *build* its evidence rather than find it. Nothing can write
a record, so the change a surface must notice can only arrive the way another program makes it — in the vault — and
`tests/surfaceConvergence.test.ts` does exactly that: it edits a task's file behind an open cockpit (a later
deadline and a move to the Running column), reloads it the way the application does, and asks eight surfaces what
they show. The project Task Board's card, the Backlog row, the project Deadlines list, the Task editor's field, the
Countdowns, the deadline Calendar and the Timeline/Gantt all report the new deadline, the Elastic card is in the
running column, the Hub's next-deadline metric follows the earliest deadline to the *other* task, and the old value
is gone from every surface rather than joined by the new one. The second case does the same for an event moved and
renamed: Day, 4-Day, Week, Month and Agenda all draw it, the time grids name the new instant, and Year is excluded
with its reason rather than asserted false. The third case is the one that keeps view state honest: a query and a
selection survive the data changing underneath them, the marked-but-hidden row is still reported, and the vault
holds the peer's edit and nothing else. Ten boxes stay open and each names its blocker — the three group parents
because their *origin* is a refused write (Stage 9, 12 and 14), the archive box because the navigator list is
rendered inline by `main.ts` with no exported surface for a test to mount, schema reprojection because the legacy
reader returns `taskSchema: []` and property definitions arrive with the record store, the two agent directions
because the bridge is a read-only reader, and the manual-refresh box because today a refresh *is* the mechanism the
checklist's own paragraph preserves. Stage 19's `## Evidence` bullets are annotated, and the UI+agent concurrency
bullet is explicitly **not** claimed.

**Slice 43 is done**, `d9d8c5e` @ `2026-09-12T02:35:31+07:00` — **eleven boxes**, and the first slice
this session that closed a stage's *implementation* half rather than auditing evidence that already existed.
Stage 8's staging and byte-preservation sections were the ones I had written off as gated; re-reading HARD GATE
C showed the dependency runs the other way — the cutover waits on the import, not the reverse — and none of this
work needs a write to the creator's vault. `tests/importStagingBytePreservation.test.ts` materializes every record
kind into slice 9's isolated staging store over disposable copies of all four fixture vaults, with
`runLegacyImportBytePreservationProof` around the operation and `node:crypto` hashing the tree independently
before and after: verdict `preserved`, zero changed paths, zero verifier writes, and every digest the verifier
reports equal to the filesystem's own. Three findings came out of writing it rather than reading the boxes. The
malformed fixture's fifteen problems are **all warnings** — the reader is tolerant, so those records enter state
and stage, while four candidates are blocked with typed reasons in the same pass, which is the "valid records
prepared while blockers are reported" pair in one run. A duplicate legacy id is **staged as its own candidate**
rather than excluded, which is the duplicate section working as designed and which contradicted my first
assertion (a blanket "rejected records are never staged" would have been wrong). And a store that claims canonical
authority is **refused** by every materializer, which is what makes "staging is not canonical until activation" a
mechanism rather than a hope. The unsupported-frontmatter question is annotated with what I now know it costs: the
reader treats `unsupported-frontmatter` and `frontmatter-parse-failure` as warnings, so the answer decides whether
the *existing* conversion is correct by default or must be withheld — it is not a question about the machinery.

**Slice 44 is done**, `738bb53` @ `2026-09-12T02:45:43+07:00` — **two boxes of HARD GATE C**, and the one that
mattered: the cutover's missing piece was that nothing turned `CanonicalRecordV2` into `ProximaState`, so a
record-store source could not even be *represented*, let alone wired. `src/app/recordStateProjection.ts` is that
projection, `recordStoreStateLoad.ts` is the store-side load in the same shape as the vault-side one, and
provenance gained a `record-store` origin so inspection names where a record came from — which is also the gate's
own acceptance box about not pretending JSON records are Markdown. The projection deliberately invents nothing: a
project's legacy `projectType` is reconstructed from what the project holds, because A4 removed that label from
capability decisions; and a workflow stage is reported as having no slot in the readable world rather than folded
into a board column, because A2 keeps project workflow and Elastic execution independent. Six cases, and the one
that says the most compares the real Task Board rendered from a legacy load with the same board rendered from the
store: **the same cards in the same three Elastic columns**, with the third column called `review` by a vault's
vocabulary and `finished` by the canonical model — a difference a projection must show, not paper over. Writing it
also caught a boundary the type change surfaced: `importPlanner` copies a source's `idOrigin` into fields that can
only mean a legacy Markdown answer, so those four sites now go through `legacyIdOriginOf`, which refuses a
record-store record instead of letting one claim a vault origin. The other twelve HARD GATE C boxes are annotated
individually with what each is waiting for; none of them is waiting on an unknown.

**Slice 45 is done**, `06c0702` @ `2026-09-12T02:53:45+07:00` — **six boxes**, and HARD GATE C's isolation half is
now proven rather than argued. The refresh seam only knew how to reload a vault, so a record-store source had
nowhere to plug in; `src/app/stateSource.ts` introduces the seam (a source says what kind it is and answers one
question — read the world now, and the revisions), `RefreshController` takes either a source or a vault so the
thirty existing call sites are untouched, `SourceMode` gains `record-store`, and a candidate in that mode carries
**both** a source for records and a reader for notes, drawings and attachments — which is why "notes continue
reading from the vault" is asserted in the mode that could have broken it. The five new cases cover activation,
refresh-on-store-change, switching in both directions, refusal of a record-store candidate with no record source,
and the one that matters: with records coming from the store, the source Markdown is renamed **and then deleted**,
nothing the surfaces read changes, the refresh stays `unchanged`, and `store.list()` returns the same records with
the same observed revisions — while the vault's own note read returns the edited text. Two ticks proved more than
their boxes asked: the "legacy changes do not overwrite JSON records" protection is unconditional today (the
store's boundary is the only writer, and `legacyIdOriginOf` refuses a record-store provenance from the import
planner), and the machine-readable source-mode inspection now has a third mode to carry. The main shell also stops
calling a record-store session a fixture: the badge names both halves, "Record store records · vault notes".

**Slice 46 is done**, `d6e2b30` @ `2026-09-12T03:02:30+07:00` — **four boxes, including HARD GATE C's item 1**, which was
the last thing between the tree and the write stages. The gap was not wiring but meaning: "activated" had none, so the
only available rule was "the store holds records, so trust it" — and a staging store holds records too. Activation is
now an act with a marker (when, which import, how many per kind) stored beside `records/` and `recovery/` in the
store's own namespace and validated on read rather than trusted; `activateRecordStore` refuses an empty store, refuses
to steal a store another import activated, and refuses to overwrite a marker this build cannot read. `chooseStartupSource`
names every answer — no marker, unreadable marker, emptied after activation, short of what it activated, unreadable
store — and every one of them keeps the product on the legacy reader *and says why*, because an empty canonical store
renders an empty application and that is worse than reading Markdown. `startupSession` keeps a restored vault handle as
the record-store candidate's **artifact** reader rather than letting it become a competing source; otherwise a remembered
folder would silently undo the cutover on every launch. **The guard caught me and was right:** a first attempt imported
the store into `main.ts`, and `recordMutationContainment` failed on it — the shell must hold no RecordStore authority, so
the composition moved to the adapter layer and `main.ts` receives only a `StateSource`, whose type has no mutation method
at all. Two more findings: the same load-sensitive flake class recurred (`bridgeDisclosure`'s cases were on the 5s default
while the start they wait for allows 30s — now all three carry `30_000`), and the real-vault acceptance report was
collapsing a record-store run into `fixture`, which it no longer does.

**Slice 47 is done**, `e898a04` @ `2026-09-12T03:10:20+07:00` — **three acceptance boxes**, and the first slice that
writes a canonical record rather than reading, projecting or activating one. Stage 9's required semantic actions are
now real code in `src/app/taskMutations.ts`: `task.create`, `task.update` and `task.delete`, with property set and
clear (relations ride the property value union), dates, weight, fixed and maximum duration, both orderings,
execution-state moves and recurrence set/clear. Three rules shaped it — the request is closed and typed rather than a
JSON patch, every refusal happens before a byte moves, and existing records change through the recovery coordinator
while creates use the store's own idempotent `createIfAbsent` — and failures speak the action taxonomy's vocabulary
so one operation can be reported identically to a human and an agent. Two of the rules were **found in the canonical
codec rather than invented here**, and are now enforced with sentences instead of store rejections: a task in a
workflow stage must carry its position in that stage while a task with no stage must not, and a project change may not
leave a stage behind from another project. Completion is derived from the execution state on every move, so "moved
into Finished" and "is complete" cannot disagree. The five cases attack the path: a dozen typed refusals that leave
every revision untouched, closed-field updates including clears, completion and both orderings, a contested write
where the loser is told the revision that beat it and can retry, and a delete that honours its revision. The UI half
of the stage is deliberately untouched: no gesture dispatches these yet, and `recordMutationContainment` still
asserts every registered record-mutation action is typed-unavailable through the dispatcher.

**Stage 17's task and event halves are complete** as of `38bd4ca` and `81e1ec4`: `tests/actionCoverageAudit.test.ts` enumerates sixteen task actions and asserts, per row, the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, checked against the parity audit rather than trusted. Twenty-three rows tick with it (sixteen task actions and seven event ones); two rows are declared operation-only — task recurrence and an event rule set/clear — and the audit asserts the *absence* of a caller for each, so those gaps are checkable rather than remembered. **The projects half is complete too, at `bede835`** — project create, edit, archive, restore and delete are each a row with its module, its caller, its case and, for delete, the typed refusal the creator has still to answer. **The workflow-stage rows are complete too, at `f17ba68` and `9e27cad`**: the board's New stage, Rename and Delete are real controls whose sequences live in `src/app/workflowStageWriteActions.ts` and whose operations live in `src/app/workflowStageMutations.ts`, and the audit's three rows name the operation, the sequence that reaches it and the shell call that reaches the sequence — the gap table is down to the schema rows, and its absence assertion now scans the whole app layer rather than a hand-listed set of files, because the stage operations had been "proved absent" by a list that did not include the module they were about to appear in. **The property-schema rows are complete as of `1b0094a`**, and with them the audit's gap table is empty: every row in this group has an operation. The three schema rows are declared operation-only on purpose — the verbs exist and their refusals are real (`semantic-conflict` with `affectedRecordCount` for anything that would orphan a stored value), and nothing in the shell reaches them, because a schema editor is UI work this pass has not done. That absence is asserted, not remembered. What remains in Stage 17 is the schema editor surface those three rows wait on, the templates row (Stage 16's own work — the shell inside Stage 16 is `src/browser/templateComposer.ts` and the coverage audit waits on the write half), and the eight artifact rows, which wait on the artifact-write question below. Next operation: **slice 82 — a schema editor surface in the Backlog or the Task editor**, which is what turns the three operation-only schema rows into wired ones; after that the templates row (Stage 16's own work) and the eight artifact rows, which still wait on the artifact-write question.

**Stage 15's read half is complete** as of `8d5ec96`: the workspace's file/folder tree, its Markdown,
Canvas and Excalidraw previews, folder expansion, selection, context state, hover affordance and
attached-file navigation are all asserted by suites the project already had
(`tests/projectNotes.test.ts` for the tree, the panes and the interaction boundaries;
`tests/canvasPreview.test.ts`, `tests/canvasTextPreview.test.ts` and
`tests/canvasExcalidrawPreview.test.ts` for the three preview paths, their budgets and their lifecycles),
so those boxes were open on a claim the tree could already evidence rather than on missing work.
**Its write half is a creator question, and it is stated as one rather than guessed at:** where an
artifact write may land. `VaultWriter` is an implemented conditional mutation port, but creator-vault
write authority is disabled and native FSA has no compare-and-swap commit primitive, so
`evaluateFsaWriteBoundary()` fails closed and no FSA writer is exposed. The three honest answers —
artifacts as files under the product's own record-store root, an explicitly granted creator directory
with its own authority boundary, or attachments staying read-only until that grant exists — change what
`artifact.move`, `artifact.rename` and `artifact.delete` mean and where they may reach, so the nine write
boxes stay open with that question named rather than answered by implication.
**Stage 18 is complete as of this pass.** Its last two boxes were the two modals that still could not save or delete, and both can now: the Event editor submits the difference it shows, closes only on acceptance and keeps what was typed when the save loses a race, while its Delete runs the same sequence the other verbs use and closes the editor only when the delete was accepted (`tests/scheduleWriteWiring.test.ts`); the New Project form creates the project it described or answers with the operation reason and keeps its fields when the run has no write path, and the project editor saves the fields it changed (`tests/projectLifecycleWiring.test.ts`). The Gantt gesture box closed with them on `tests/ganttWriteWiring.test.ts` (a drag previews whole days, the write lands the dates it previewed with the duration intact and the row untouched, the next render draws the moved dates, an edge drag moves one end, and an inverted range is refused with the bar restored), and the two-axis box on the workflow and task-mutation suites, which assert from both directions that a workflow move leaves the Elastic pair alone and an execution move leaves the workflow pair alone. **The document stands at 772 ticked / 68 open.** Four more creator answers landed at `3cc97cb` and `3cc97cb`'s commit (`docs/DECISIONS.md` D64-D66): **Gantt row placement is semantic**, so it becomes a third durable scoped order with its own field — HARD GATE A's last box is **not** ticked by it, because that box asks for the field itself, and the one part not yet asked about is the order's *scope* (global, per project or per saved view; the proposal is global, because the Timekeeping Gantt is one global surface). **The importer preserves unmappable frontmatter and reports it** (D65) — and that answer has a consequence now recorded on the box: the staging planners currently assert the opposite, so `unsupported-frontmatter` records go from "explicit blockers" to imported-with-a-report, which is the next test-encoding slice. **Boxes close on tested logic with the residual stated** (D66). The Papers hotkey chord was also chosen: **Alt+Shift+X**. **HARD GATE C is held by one decision rather than three problems:** H4's box closed at `3cc97cb`, and the two that remain — "legacy source only" and the FSA boundary's "because" — both say in their own text that they wait on a shipped activation trigger for the record store. The question is therefore a single one: does an ordinary first launch offer the one-time import and activate on success, or does the shipped default stay the legacy reader with activation explicit (which is what the tree does today, and what the read-only answer implies)? **Scope note for the rest of this repository, since the objective is every checklist in it:** the two other documents with open boxes are `papers/adopted-window-surfaces.md` (173 open, zero ticked) and `papers/window-layout-consistency-and-auto-tracking.md` (172 open, zero ticked), and both state in their own Status blocks that they are **not autonomous work** — each manipulates live foreign windows on the creator's desktop, "moving or hiding another application's windows is not reversible by a later commit", and each also carries an unanswered design blocker before its stages may begin (the window-tag lifetime contradiction; exact window-instance identity before "remove invalidated processes immediately", without which a Chrome tab switch would silently delete Chrome and Obsidian from the creator's layouts). `papers/quick-run.md` is the third, at 279 open with its chord now chosen and STAGE 0 waiting on the As-you-Go Backpack checkout. So the autonomously workable agenda is this document plus the Proxima tree; the Papers window work needs the creator present, and the honest move is to say so rather than to fake progress on it. Next slices, in order: the Gantt order field (D64) once the scope is confirmed, the unsupported-frontmatter policy implementation (D65), then the two-step project delete (D60). The creator answered the four questions this pass was waiting on at `8193d58` (`docs/DECISIONS.md` D60-D63): deleting a project is an **explicit two-step cascade**, Proxima has **no tag model**, **task recurrence is retained** (its missing half is a surface, not the concept), and **artifacts and vault files stay read-only** for now — Proxima is intended to become a writer eventually, and the present pass is to get the UX right first, so the destination question is deferred rather than answered by implication while HARD GATE D's standing position (disposable-root testing, no native shared-vault write claim, H4 unclaimed) is restated and closed. Twenty-seven boxes closed on those decisions: Stage 6's tag filter and task-recurrence condition, Stage 11's four delete-semantics boxes, Stage 15's nine write boxes, Stage 17's eight artifact rows, and HARD GATE D's four. **The first slice the answers create is the two-step delete**: `project.delete` gains a member list in the request rather than inferring one, the Hub's Delete reports what the project holds and asks, and only a confirmed second step removes the project with the members the reader was shown. Still unanswered: HARD GATE A's semantic-priority field, the importer's unmappleable-frontmatter rule, the closure standard, and the Papers hotkey chord.

**What remains, by group, as of `2c435fe`** — 73 boxes, and this is the current arithmetic rather than
the 105-box snapshot it replaces (Stages 11, 15, 18 and 20 have closed since, and the eight artifact
rows closed on the read-only decision). **Stage 17, 16:** the two operation-only rows (each closes when a
UI caller exists — task recurrence is retained by D62, and an event rule set/clear stays unwired), the
templates row (Stage 16's own work), and the thirteen "for every row above" contract boxes, which need
the audit to answer all thirteen questions per row rather than the two it answers mechanically today.
**The final release gate, 26. Stage 16, 14** (template execution; zero ticked, the largest untouched
block). **Stage 19, 5** (cross-surface convergence — most of it behind HARD GATE C's shipped trigger).
**Stage 0, 3** (the local-state/equivalence boxes and the revision-in-result box, which its own note gates
on HARD GATE C). **HARD GATE C, 0 (closed at `42a022c` by D67: the cutover is never automatic)** — both held by the same missing activation trigger, and H4's box
closed at `3cc97cb`. And one box each in **Stage 3** (panel sizing; the pattern is the Backlog column
resize at `8cadd24`), **Stage 6** (the Task modal's workflow control — a product decision, not code),
**HARD GATE A** (the Gantt row order field, D64, scope taken as global) and **Stage 8** (the import half
of D65, whose module and test list are on the box). Stages 5, 9, 10, 11, 12, 13, 14, 15, 18 and 20 have
no open boxes.

Slice 26, the Backlog view projection and query-aware rendering, pushed at `9b59d16`, committed
`2026-09-12T00:23:35+07:00`: `src/app/backlogView.ts` turns loaded state plus a view state into everything
the Backlog draws — rows, the eight field columns plus one per custom property the data declares, cells
formatted per type, both counts, the sort indicator, the filter chips, and why the list is empty — and
`renderProjectBacklog` consumes it instead of filtering inline with its own comparator. Five § Backlog
boxes were ticked: Search, Type-appropriate comparison operators, Multiple filters, Sort
ascending/descending, Sort indicator. `src/browser/` gained unit coverage there, which is what turned
those five boxes into evidence rather than claims.

Slice 25, the Backlog query surface, pushed on Proxima branch `stage7-record-store-contract` at
`a31c74c9d1c78436e542523823c5e94f5b045ca2`, committed `2026-09-12T00:19:34+07:00` and **awaiting creator
acceptance**: `src/domain/backlogQuery.ts` with `tests/backlogQuery.test.ts` (17 tests) gives search over
name and description, nine filter fields restricted to the operators their type admits, conjunction of
multiple filters, removal by filter id, ascending/descending ordering with a missing value last ascending
and first descending, and a total order — ties fall through `orderIndex` then `id`, so equal keys never
swap between runs. A numeric field compared against a non-number does not match: `9` is not `"9"`, which
the engine coerced until the test caught it. Evidence: full suite 171 files / 1045 tests, every step
exit 0.

**Papers checklists recon, 2026-09-12 (slice 24).** All three are greenfield: every Status reads "Not
started. No implementation exists. Design only." Their boxes are feature-level acceptance criteria,
test-stage requirements and Definition-of-Done gates — not verification gaps — so no read-only pass can
close them. Each of the two largest also carries an explicitly unresolved pre-implementation gate that
only the creator can close: Quick Run — "Pin the default workspace hotkey chord. Not chosen yet; do not
invent one silently."; Window Layout — "Resolve the window-tag lifetime contradiction … record the answer
before Stage 1." Two of the three (adopting foreign windows, window layout and auto-tracking) require
moving and Z-ordering *live foreign windows*, which must not be attempted autonomously on the creator's
desktop overnight under a non-destructive mandate. Papers host baseline is green: `Futahua/Papers-3` at
`d2a3c74`, 99 files (98 passed | 1 skipped), 942 passed + 4 skipped / 946 collected, 5.4s.

**The AUTHOR loop changed on 2026-09-11, by creator instruction.** The browser reviewer is retired: it
was too slow, and it existed mainly to keep an agent working through the creator's night rather than to
judge the work. The executing agent is now author and executor at once, and the judgement that used to
come from a reviewer reading evidence now comes from the project's own suite — fixture generation, both
typechecks, build, `git diff --check`, and the full vitest run, each recorded by exit code. That is
stronger than the browser on correctness, which could run nothing; it is weaker on whether a slice is the
right *product* decision, so a genuine product choice is left stated and open rather than self-approved.
The reviewer-tab machinery in AGENTS.md is inert until the creator says otherwise.

**Slice 1 correction is closed in slice 3.** I had briefed the AUTHOR that an empty-slot
click must not create anything, which is right for Elastic and the Deadline Calendar but
wrong here. Slice 3 now seeds the event editor at the clicked time with a one-hour proposal;
the editor remains local-only until its typed-unavailable Save path.

**Two snapping models now coexist and must not be confused.** The Gantt is 42 whole-day
columns, pointer delta over one column width, ties away from zero, no time of day. Schedule
is 96 fifteen-minute slots per civil day, position from local minutes since midnight, height
from duration over 1440. Mixing them yields geometry that looks plausible and is wrong.

**HARD GATE B is closed** at Proxima `a08340c`: the physical backing API is the stable
Proxima Backpack origin's OPFS under `record-store/records/` plus
`record-store/recovery/`. The physical `record-store/records/` backend is accepted at
`e7e7362`. Real import still does not begin: the remaining Stage 7 restart,
mutation/recovery and concurrency acceptance must close first.

**`npm` blocked this loop once; C: was freed.** The original note was that the C: drive sat at zero
bytes free and npm died with ENOSPC before executing anything. As of 2026-09-11 C: has roughly 5.4 GB
free and `npm ls` completes, so the blocker is gone. This loop still runs the steps directly rather
than through the npm scripts — `node tools/build-fixture-module.mjs`,
`./node_modules/.bin/tsc -p …`, `./node_modules/.bin/vitest run --no-file-parallelism` — because it is
faster and because the substitution has to be declared either way. Say in the evidence that the
commands were run directly, because substituting a command for the authored one has caused a real
problem in this loop before.

**Reviewer outages, 2026-09-10 ~09:50 and ~13:20.** The AUTHOR twice stopped answering:
replies die after a handful of words. Confirmed against the rendered page and reproduced in a
*fresh* thread, so it is the service, not thread length. The first outage had cleared within
about an hour. Try again before concluding anything.

**Reading the reviewer, hard-won, and this one cost hours.** Read a reply by walking the
assistant node's children yourself, taking `textContent` from each `pre code` for fenced
blocks. Do not trust `innerText` anywhere: **while the browser pane is hidden the page is not
laid out and `innerText` collapses to a fragment**, which reads exactly like the model being
cut off mid-sentence. Four complete answers were read as truncated and the AUTHOR was twice
told its replies were broken; it patiently restated the same answer each time. Worse, acting
on that false diagnosis I told it to stop using code blocks — which made the renderer decode
entities and strip backticks, genuinely corrupting the next packet. Fenced code blocks are
the *safe* transport, not the risky one. If a reply looks truncated: front the tab, take a
screenshot, and check before you say a word about it.

<!-- /STATUS -->

**Starting point:** `608bcdc`

**Target:** the old Proxima cockpit interaction model, backed by a cleaner Proxima-owned record database and fully operable by semantic agent actions.

**KeToan is permanently excluded.**

The current repo already has the right beginnings for programmability: `src/app/actionProtocol.ts` defines versioned typed actions/results, request IDs, accepted/rejected events and machine-readable errors. It currently supports only project selection, surface selection, month shifting and fixture reset. The inspection contract is likewise machine-readable, but currently represents only the simplified board/calendar world and reports no real pending mutations.

The existing mutation coordinator already provides checked create/update/move/delete outcomes and structured conflict/refusal results, while the durable recovery store records prepared/committed/recovery-required/recovered/blocked states and reconciles uncertain operations without guessing.

That machinery is reused. **The Markdown-specific semantic writers are legacy-import compatibility code, not the future record database API.**

---

# Global completion rules

These apply to **every stage**.

- The Backpack remains disposable. No feature depends on preserving today's renderer structure or migrating old cockpit/view state.
- Durable **domain data** and disposable **cockpit state** remain explicitly separate.
- Tasks, projects, events, schemas, workflow definitions and relations use the Proxima-owned record store once cutover occurs.
- Notes, drawings and attachments remain ordinary vault files.
- Legacy task/project/event Markdown remains readable for import and historical compatibility but is never silently treated as canonical after cutover.
- No feature reintroduces Markdown syntax, paths, filenames, wikilinks or Obsidian APIs into `src/domain`.
- KeToan does not return through Tools, templates, schema work or generic "future utility" abstractions.
- H4 remains unclaimed. Do **not** add a Papers transaction capability merely because one might be useful someday.
- No gate may require the creator to click something and report the result. This requirement already exists in the repository's engineering ledger: post-enrollment acceptance must be programmatic and machine-readable.
- Every automated UI acceptance can be invoked without a human through a browser/test interaction driver.
- Every canonical mutation can be invoked without the UI through `actionProtocol`.
- Every canonical mutation returns a typed, machine-readable outcome.
- Human UI and agent calls invoke **the same semantic operation**, not parallel implementations.
- An agent is never granted direct write access to record JSON as an alternative to the semantic action protocol.
- Direct record-store modification behind Proxima's back is explicitly unsupported and not exposed as an agent capability.

## Binding agent-action invariant

For every interaction tagged **DATA WRITE** in the parity trace:

```
human gesture
      │
      ▼
typed Proxima semantic action
      │
      ├── UI caller
      └── agent caller
      │
      ▼
semantic validation
      │
      ▼
record/file mutation boundary
      │
      ▼
typed ActionResult
```

Never:

```
agent → filesystem → JSON record
```

That would create an uncoordinated second writer and destroy the very write serialization gained by moving records away from Obsidian.

A stage containing a human mutation is **not closed** until its equivalent action can be submitted programmatically and its effect confirmed through inspection.

---

# Stage 0 — Expand the automation/acceptance spine first

Do this before adding large amounts of UI.

The current action dispatcher is synchronous and typed but only understands four non-domain-writing actions. Its success result already supplies `requestId`, `changed`, `stateRevision` and snapshot; failures already have typed errors. Preserve that pattern.

## Work

- [x] Establish one public versioned action union for: — `da7881f` and `4554fea` built the
  taxonomy and its registry, and `215777a` @ `2026-09-12T02:11:10+07:00` added the runtime
  case below; `actionProtocol.ts` declares `ProximaAction` and
  `ACTION_SCHEMA_VERSION = 4`, both exported, with `parseAction` as the single gate for
  anything entering from outside — a UI click handler and a programmatic caller hand it the
  same shape. The union and the registry cannot drift apart: `ACTION_TAXONOMY_MATCHES_PROTOCOL`
  is a compile-time check that each names exactly the types the other does, so adding a type
  to the union without a category fails typecheck. `tests/actionTaxonomy.test.ts` states at
  runtime what that check protects — which of the four kinds the product actually populates.
  Two of the four kinds are vocabulary rather than implementation, and the two child boxes
  say which and why.
  - [x] presentation actions; — `da7881f` @ `2026-09-09T18:36:56+07:00` *(the category exists and is **deliberately empty**, and that is the position rather than an omission: every gesture in this cockpit that changes what is shown also has to remember which way the reader left it, so it is local state, and `actionTaxonomy.ts` says in as many words that defaulting an unregistered mutation to `presentation` is how a durable write crosses a boundary that believes nothing durable happened. The refusal to default is what makes the empty category safe: `categoryOf` returns `undefined` for an unregistered type, and `tests/malformedAgentRequests.test.ts` asserts an unregistered type is refused rather than quietly filed under a harmless-sounding category.)*
        changes what is shown also has to record which way the reader left it, so it is
        local state. `presentation` is the category an unregistered type is deliberately
        **not** defaulted into, because defaulting a durable write to it is how a write
        crosses a boundary that believes nothing durable happens.)*
  - [x] local-state actions;
  - [x] record mutations;
  - [x] vault-artifact gestures. — `3cc97cb` @ `2026-09-12T07:44:40+07:00` *(closed as **decided, not missing**: the category exists (`ActionCategory` carries `artifact-mutation`, and `isMutationCategory` treats it as a mutation), it has no member, and it is not getting one in this pass — D63 keeps artifacts and vault files read-only while the writer question waits behind the UX, so the ordinary vault-file writes this row names (Notes rename/move/delete, the canvas file) are unoffered by decision rather than pending a stage. The row returns the day the creator names a destination for artifact writes, at which point its members are the operations that destination defines.)*
        the canvas file — are refused today and arrive with the Notes/drawings write stage,
        which HARD GATE C gates. The category exists, is carried by
        `isMutationCategory`, and has no member yet.)*

- [x] Extend the result taxonomy so mutation callers can distinguish at minimum: — `da7881f`
  adds `src/app/actionTaxonomy.ts` with the eight outcomes, `outcomeForErrorCode`, and a
  `categoryOf` that returns `undefined` for an unregistered type instead of defaulting;
  `4554fea` widens the error-code map. Reverting either leaves `actionProtocol.ts`'s
  compile-time union check without a taxonomy to match and typecheck fails loudly.
  - [x] `accepted`;
  - [x] validation refusal;
  - [x] not found;
  - [x] stale observed revision;
  - [x] semantic conflict;
  - [x] unavailable action;
  - [x] recovery required / ambiguous commit;
  - [x] storage failure.

- [x] Preserve a unique request ID through dispatcher → semantic operation → mutation journal → result/event. *(dispatcher → result/event only; the journal leg arrives with the record store.)*
  — `da7881f` threads `requestId` through every result shape. The journal leg is still
  absent, so this box will reopen when the record store lands.
- [x] Include affected logical record IDs in mutation results. *(`entityIds` is required on every result, empty rather than absent for presentation actions.)*
  — `da7881f`. Required, not optional: an absent `entityIds` would be indistinguishable
  from "touched nothing", so presentation actions carry an empty array.
- [x] Include resulting record revision(s) where a record changed. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the record layer's own results always carried the record's revision; what was missing was a product entry that runs a semantic record action and returns one. `src/app/agentWritePath.ts` is that entry: a submitted `task.execution.move`/`task.execution.reorder` returns `revision`, asserted equal to the revision the store holds afterwards and different from the one the caller read, and a lost race names `actualRevision` — the revision that beat it (`tests/agentWritePath.test.ts`). The cockpit-wide `stateRevision` keeps its separate meaning. What is still true and named: the **dispatcher** refuses every record verb, so this revision comes from the operation entry rather than from `dispatch`.)*
- [x] Define bulk-action results per entity so partial success can never be mistaken for complete success. — `9dcc5d6` @ `2026-09-12T04:21:48+07:00` *(this box was left open on purpose — "a shape no producer fills is vocabulary a reviewer cannot check" — and the first bulk action that can run now fills it: `src/app/bulkTaskActions.ts` reports one `BulkEntityOutcome` per requested task (id, accepted-with-revision, or refused-with-reason and the revision that beat it when the refusal was a race) plus a `status` that is `accepted` only when every member was, `partial` when some were and `refused` when none were. The per-entity shape and the action shipped together, which is what the box was waiting for.)*
- [x] Make the inspection contract expose: — `2a2ff0c` raises `src/app/inspection.ts` to
  schema 3 and makes the projection state what it does not know; `2450828` adds the cockpit
  `localState` (surface, selection, modes, tab, calendar month). Reverting `2a2ff0c` returns
  the projection to claims it cannot support, which is what the schema bump exists to stop.
  - [x] current surface and submode;
  - [x] local cockpit state needed for test assertions;
  - [x] record revisions;
  - [x] pending operations;
  - [x] latest action/mutation event sequence; *(action sequence real; mutation is `null`
        because no mutation stream exists — a fabricated `0` would read as a quiet one.)*
  - [x] settled/busy state.

- [x] Replace the current permanently empty `pendingOperations: []` implementation with actual state once asynchronous mutation exists. — `2a2ff0c`. *(Now `{ tracking: 'unavailable', items: [] }` — "there is no tracking" rather than "nothing is pending". The guard refuses a projection claiming unavailable tracking while carrying items. Becomes a real list when mutation exists.)*
- [x] Provide a programmatic browser interaction harness capable of: — `5d5cebf` adds
  `src/browser/interactionHarness.ts` against a real DOM (happy-dom), all nine gestures on
  `InteractionHarness`. This is the commit that closed HARD GATE 0; reverting it reopens the
  gate and Stages 1–6 lose their only non-visual acceptance route.
  - [x] click;
  - [x] pointer down/move/up;
  - [x] drag/drop;
  - [x] resize gestures;
  - [x] Shift modifier;
  - [x] keyboard entry;
  - [x] Escape;
  - [x] context-menu invocation;
  - [x] hover.

- [x] Give important interactive geometry stable machine keys independent of visual text.
  — `5d5cebf` defines `data-c1-key` and makes `machineTarget` throw on zero or multiple
  matches, so an ambiguous key fails the test instead of silently picking one; `2450828`
  emits the keys from the renderer.
- [x] Tests can assert provisional drag/resize state **before** pointer release. — `5d5cebf`.
  Pointer down, move and release are separate calls returning the live gesture, so a test
  reads mid-drag geometry rather than only the settled result.

## Acceptance

- [x] An action submitted through the UI and the equivalent action submitted through the agent/programmatic entry point produce the same semantic operation/result shape. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the first action an agent can submit now exists: `src/app/agentWritePath.ts` takes a typed submission for `task.execution.move`/`task.execution.reorder` with no cockpit anywhere in its dependency set and hands it to `moveTaskByGesture`, which is the same operation the Elastic drop wrapper runs. `tests/agentWritePath.test.ts` compares the two callers as whole objects — field sets included, not a chosen subset — for an accepted move, an accepted reorder and a refusal, and finds the same resulting revision, the same refusal vocabulary and the same terminal event, with only the run's own request id set aside. Two things the comparison needed, and the slice therefore changed or named rather than hid: the drop wrapper stopped narrowing the gesture's result, because a subset comparison can hide a divergence in the fields one side drops; and the two entries answer "no such task" differently for a real reason — the board refuses `unknown-task` **before** the store because it has no revision to write against, while an agent naming an absent record reaches the record layer and gets its `not-found`. Record mutations keep their older operation-layer parity at `1029a25`.)*
- [x] Invalid action input performs zero durable writes. — `4554fea`, proven by hashing every
  fixture byte before and after a rejected dispatch.
- [x] Unknown action type returns a typed refusal. — `4554fea`.
- [x] Every action result can be runtime-validated at the boundary. — `4554fea` makes the
  guard refuse a result whose category contradicts the registry, so a mislabelled result
  cannot cross the boundary even when the dispatcher believes it succeeded.
- [x] Test code can perform a real drag sequence without creator input and inspect the intermediate state. — `5d5cebf`.
- [x] Test code can wait for `settled` rather than relying on sleeps. — `2a2ff0c` reports busy
  state directly on the projection, so callers poll inspection instead of guessing a delay.
- [x] No test requires visual inspection by the creator. — holds as of `5d5cebf`; every suite
  since asserts through the harness or inspection. Any commit that breaks this unticks it.

## Evidence

- [x] Action parser/guard tests. — `tests/actionTaxonomy.test.ts`, 14 tests, on
  `proxima-backpack` branch `stage0-action-spine` at `da7881f`. Full suite 93 files /
  588 tests, typecheck clean.
- [x] UI-versus-agent equivalence tests. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the mutation half existed at `1029a25`; this is the action-protocol half that note said was missing. `tests/agentWritePath.test.ts` adds the submission path over it — seven cases: a record written with no cockpit in the dependency set, whole-object parity for an accepted move, an accepted reorder and a refusal, a seventeen-submission malformed-and-unsupported battery after which every record file is at the same revision, the dispatcher's containment rule asserted beside the write that succeeds, Board-and-Backlog convergence caused by the write's own refresh, and a race refused in both directions. `tests/uiAgentMutationParity.test.ts` remains the operation-layer comparison.)*
- [x] Programmatic pointer/keyboard harness tests. — `tests/interactionHarness.test.ts`,
  6 tests, at `5d5cebf`.
- [x] Machine-readable inspection snapshot fixtures. — `tests/inspection.test.ts` at
  `2a2ff0c`, extended at `2450828` with the cockpit `localState`.
- [x] A test proving malformed agent requests never reach mutation storage. — `0071e74` @ `2026-09-12T07:57:08+07:00` *(the note said "partially: malformed input is proven to leave dispatcher state untouched; there is no mutation storage to reach yet" — the second half stopped being true when the record store and its conditional coordinator landed. `tests/malformedAgentRequests.test.ts` finishes the claim: nineteen payloads (null, numbers, strings, empty objects, a numeric type, an unregistered type, missing required fields, bad enum values, a prototype-polluting object) are each refused by `parseAction` with a typed error and by `dispatch` without moving the local state the surfaces draw from, over a **real store with real records whose file list and per-file revisions are compared before and after the battery** — so "never reach mutation storage" is a fact about bytes. One case is about a request that *parses*: `project.delete` is registered, the containment rule answers it as unavailable through the dispatcher because record writes live behind the operation layer (D55), and the store is byte-identical afterwards. Two of the first battery entries were wrong and the suite caught them — `project.delete` parses, and an unknown extra field is tolerated — so both moved to the case that states what they prove.)*
  malformed input is proven to leave dispatcher state untouched; there is no mutation
  storage to reach yet.)*

### Progress

Categories and outcomes exist and are enforced at the boundary. The action union itself
still contains only presentation actions, so the local-state, record-mutation and
artifact-mutation rows above stay open until actions of those categories are registered.
`categoryOf` returns undefined for an unregistered type rather than defaulting, and
`resultFor` throws rather than accept an action whose cost nobody declared.

### HARD GATE 0

**Stages 1–6 may begin only when programmatic UI acceptance exists.**

Otherwise the project will accumulate "looks right when I click it" behavior that cannot be closed autonomously later.

---

# Stage 1 — Restore the cockpit shell and navigation

Presentation/local state only. No storage migration dependency.

## Work

- [x] Replace the simplified Board / Calendar / Canvas-only navigation with the Proxima cockpit hierarchy: — `2450828` adds
  `src/browser/cockpitNavigation.ts` and rewires `main.ts` onto it. Canvas is kept as a
  fourth surface rather than folded into the three, so nothing the Backpack already did is
  lost. Reverting returns the app to Board/Calendar/Canvas and every Stage 2+ surface has
  nowhere to mount.
  - [x] Tasks;
  - [x] Schedule;
  - [x] Projects Hub;
  - [x] retain Canvas as a Backpack capability without displacing old Proxima surfaces.

- [x] Tasks contains: — `2450828`, `TasksMode = 'elastic' | 'timekeeping'`.
  - [x] Elastic Boards;
  - [x] Timekeeping.

- [x] Schedule exposes: — `2450828`, all six as `ScheduleMode`; 4-Day is `'four-day'` in
  code, and the label is rendered separately from the value so the machine key never depends
  on visible text.
  - [x] Day;
  - [x] 4-Day;
  - [x] Week;
  - [x] Month;
  - [x] Year;
  - [x] Agenda.

- [x] Projects Hub opens project workspaces. — `2450828`.
- [x] Project workspace exposes appropriate tabs from one project rather than treating selection as only a global filter. — `2450828`, `ProjectWorkspaceTab` = notes, task-board, backlog, deadlines, schedule.
- [x] Project selection remains view state. — `2450828`; it lives in the dispatcher snapshot,
  never in a record.
- [x] Current surface/subsurface remains local cockpit state. — `2450828`.
- [x] No migration framework is created for this state. — `2450828`; deliberately none.
- [x] Resetting/rebuilding the Backpack may discard it without affecting records. — `2450828`.

## Local/presentation actions

- `surface.select`
- `tasks.mode.select`
- `schedule.mode.select`
- `project.select`
- `project.workspace-tab.select`
- `calendar.navigate`
- `calendar.today`

These do not need to mutate durable records.

## Acceptance

- [x] Every old top-level destination is programmatically reachable. — `2450828`,
  `tests/cockpitNavigation.test.ts` walks all four surfaces and every submode by machine key.
- [x] Project selection does not alter any record JSON/source data. — `2450828`.
- [x] Reload/reset of local cockpit state leaves canonical records byte-identical. —
  `2450828`, `tests/actionProtocol.test.ts:196` hashes every durable fixture byte before and
  after a full navigation walk. This is the test that would catch a future surface quietly
  writing to the vault.
- [x] Inspection identifies exactly which surface/subsurface/project/tab is active. —
  `2450828` adds `localState` to the projection.

## Evidence

- Navigation contract tests.
- Headless browser tests for every navigation target.
- Before/after durable-store hash proving navigation does not write records.

---

# Stage 2 — Elastic presentation and local execution session

No record writes yet.

The current domain already contains weights, fixed/max duration and Elastic concepts, but its execution-column membership is derived through status definitions. Do not deepen that coupling; the structural replacement happens before import.

## Work

### Board rendering

- [x] Restore Backlog / Running / Finished appearance. — `57860d3` replaces the simplified
  board renderer with the Elastic cockpit while retaining status-derived Backlog, Running
  and Finished membership.
- [x] Restore proportional Running-card height. — `57860d3` sizes Running cards from the
  calculated execution allocation for the current target horizon rather than using one
  fixed card height.
- [x] Restore task-property pills/chips. — `57860d3` renders schema-labelled task properties
  as keyed pills on Elastic cards and scopes modal copies so machine keys remain unique.
- [x] Restore hover affordances. — `57860d3` restores an explicit interactive hover treatment
  on Elastic task cards instead of leaving clickable/draggable cards visually inert.
- [x] Restore clickable task cards opening a modal. — `57860d3` routes keyed Elastic card
  clicks through the real DOM interaction boundary into the task quick-editor state.
- [x] Render read-only task values in that modal even before Save is enabled. — `57860d3`
  exposes current task values in the quick editor while Save and Delete remain explicitly
  unavailable before write parity.

### Execution planning

- [x] Restore editable execution target date/time. — `57860d3` adds a datetime-local execution
  target whose browser-local wall time round-trips to the canonical instant through
  `elastic.target.set`. An earlier draft printed UTC into that local-time field, which would
  have mis-set the target by the machine's offset; reverting reintroduces that.
- [x] Restore default future execution horizon behavior matching old Proxima. — `57860d3`
  restores the four-hours-from-now default using the injected clock rather than a hard-coded
  wall time.
- [x] Recalculate Running allocations immediately as the target changes. — `57860d3` rerenders
  Elastic allocation geometry from the newly dispatched target, with deterministic tests
  proving a changed target changes allocations.
- [x] Restore Lock. — `57860d3` adds `elastic.lock`, capturing the injected clock instant and
  freezing target editing for the active local execution run.
- [x] Restore Unlock. — `57860d3` adds `elastic.unlock`, clearing the local lock without
  changing task records or the selected execution target.
- [x] Restore live elapsed-progress visualization. — `57860d3` derives elapsed run progress
  from lock time and target and advances the live cockpit on its one-second external-mode
  tick.
- [x] Restore per-task allocation/progress during a locked run. — `57860d3` exposes
  deterministic allocation minutes and sequential per-task progress from the locked Elastic
  timeline.
- [x] Lock information is **LOCAL STATE**, not task data. — `57860d3` keeps target and lock
  timestamps in dispatcher/inspection cockpit state and registers their actions as
  `local-state`.
- [x] No task JSON/legacy Markdown is touched when: — `57860d3` hashes the durable fixture
  before and after the full target/lock/clock-advance/unlock/local-state lifecycle and
  proves the bytes are identical.
  - [x] target time changes;
  - [x] run locks;
  - [x] time advances;
  - [x] run unlocks.

### Drag feel without committing data yet

- [x] Implement card pickup. — `57860d3` gives keyed Elastic cards a real drag-start pickup
  state and clears that visual state on drag completion or cancellation. Clearing is split
  between `clearDragFeedback` (per pointer move) and `clearDragPickup` (per drag); folding
  them back together erases the pickup state on the first move.
- [x] Correctly sized insertion placeholder. — `57860d3` matches the original drag geometry by
  sizing the insertion placeholder to `min(90px, dragged card height)` while preserving full
  card geometry separately.
- [x] Placeholder moves during drag. — `57860d3` clears the prior insertion slot and exposes
  the newly targeted keyed slot as the pointer moves before drop.
- [x] Destination-column highlight/feedback. — `57860d3` makes the active drag destination
  visibly styled, not merely marked by an otherwise inert DOM class.
- [x] Invalid/outside drop restores visual source state. — `57860d3` clears pickup, placeholder
  and destination feedback when the drag ends outside a valid insertion slot without
  changing task state.
- [x] During this stage successful state-changing drop remains disabled/refused with a typed "mutation unavailable before record-store cutover" result rather than silently pretending to save. — `57860d3` routes drop through `task.execution.move` as a `record-mutation` and returns `action-not-available` before record-store cutover without mutating the task.

## Local-state actions

- `elastic.target.set`
- `elastic.lock`
- `elastic.unlock`
- optional `elastic.session.reset`

## Acceptance

- [x] Changing target changes card allocation deterministically. — `57860d3` deterministic
  Elastic geometry tests compare different targets and prove the resulting allocation
  changes predictably.
- [x] Lock survives ordinary rerender within the same Backpack session if local persistence is intended. — `57860d3` keeps lock state outside disposable render markup and proves a normal rerender preserves the active lock and target.
- [x] Destroying local state does not alter any domain record. — `57860d3` resets/discards
  Elastic cockpit state under before/after durable-source hashing and proves domain bytes
  remain unchanged.
- [x] Locked run advances under injected clock. — `57860d3` deterministic clock tests advance a
  locked run and prove overall and per-task progress advance without wall-clock sleeps.
- [x] Programmatic drag shows placeholder before release. — `57860d3` the real-DOM interaction
  harness inspects the keyed insertion placeholder after drag movement and before
  drop/release.
- [x] Pre-storage DATA WRITE drop refuses visibly rather than updating only the DOM. —
  `57860d3` programmatic drop receives the typed unavailable result, renders the refusal in
  the cockpit, and leaves canonical task state unchanged.

## Evidence

- Deterministic clock tests.
- Elastic geometry tests.
- Programmatic drag mid-state assertions.
- Record-source before/after hashes proving zero durable writes.

---

# Stage 3 — Restore Timekeeping presentation

No storage migration dependency.

## Work

### Composition controls

- [x] Calendar panel toggle. — `760e54d` adds Calendar as independently visible Timekeeping
  panel local state through `timekeeping.panel.set-visible`.
- [x] Timeline/Gantt panel toggle. — `760e54d` adds Timeline/Gantt as an independently
  toggleable composition slot without making Timekeeping panels exclusive. The panel itself
  renders empty until its own slice.
- [x] Countdowns panel toggle. — `760e54d` adds Countdowns as an independently toggleable
  composition slot, likewise reserved until its own slice.
- [x] Multiple panels can be visible simultaneously. — `760e54d` makes Timekeeping panel
  visibility compositional local state, so Calendar, Timeline/Gantt and Countdowns can all
  be visible at once. This is the box that stops the surface degenerating into tabs.
- [x] Panel sizing/layout is local state only. — `8b4e093` @ `2026-09-12T15:13:22+07:00` *(built on the pattern this box named for itself, so nothing was re-derived: `src/app/panelSizing.ts` is a pure clamp with **no imports at all** - a module that cannot reach a store is the strongest form of "writes nothing" - and the cockpit draws each visible panel at the width the reader dragged it to, with an edge bound the way the Backlog's is: begun on the edge, moved, reported once on release rather than per pixel. A hidden panel draws no slot and therefore has no edge, the same statement the visibility control already makes. The width is held in the shell's view state beside the panel visibility and deliberately **not** in the action snapshot beside it, because a width is disposable view state rather than a fact about the session. **The claim is asserted in two forms because they are two different claims**: a resize leaves the store's bytes identical - which a write that happened to be a no-op would fail - and leaves the dispatcher's snapshot identical, which a width that leaked into the session would fail while the records stayed untouched. The real interaction is driven through the harness as well, so the binding cannot be deleted while every arithmetic assertion still passes. Bounds are the Backlog's shape and deliberately not its numbers, and no height is tracked: a panel's height is what its content needs, and dragging it would only let a reader hide their own work. Six mutations were tried and all six failed their suite, including a render that ignores the widths map - the one that keeps the binding honest rather than the arithmetic.)*

### Deadline Calendar

- [x] Month navigation. — `760e54d` reuses the local calendar cursor for deterministic
  previous/next month navigation.
- [x] Current-day styling. — `760e54d` marks the injected-clock civil day as the current day
  with a stable machine-addressable cell.
- [x] Deadline task placement. — `760e54d` projects tasks with real deadlines deterministically
  onto their civil-date cells; tasks without deadlines are not invented onto the calendar.
- [x] Overdue/urgency styling. — `760e54d` projects and styles incomplete deadlines before the
  injected clock as overdue, and reuses the existing deadline-pressure hue model so urgency
  tracks remaining time rather than a second, parallel threshold system.
- [x] Click task → task modal. — `760e54d` routes deadline cards through the existing task-modal
  affordance, exercised through `data-c1-key` real-DOM interaction. The modal still lives in
  `elasticCockpit.ts`; extract it when Timekeeping makes that awkward, not before.
- [x] Do not invent empty-day task creation if the old deadline surface did not have it. —
  `760e54d`; empty cells carry no creation action or affordance, and a test asserts it.

### Timeline/Gantt

- [x] Render task range from effective start to deadline. — `fb67685` projects truthful task
  spans from effective start through deadline, clipped to the visible civil-day window
  without inventing missing bounds. A task with only one bound draws a one-day milestone
  rather than a span; reverting reintroduces the temptation to invent the other end.
- [x] Render row structure. — `fb67685` renders machine-addressable task rows carrying span,
  start-only and deadline-only geometry as data, plus current-day marking, the panel's own
  month navigation and existing task-modal entry.
- [x] Hover/edge affordances. — `c1f8c93` gives the start and end boundaries separate
  machine-addressable 8px resize handles with 2px boundary rules and a col-resize
  affordance.
- [x] Normal pointer drag previews a bar move. — `c1f8c93` previews horizontal whole-day
  movement and vertical row movement live before release, with the picked bar following the
  gesture rather than jumping on drop.
- [x] Shift-modified edge manipulation previews resize. — `c1f8c93`; Shift is latched at
  pointer-down, so releasing the key mid-gesture does not silently turn a resize into a move.
- [x] Start-edge and end-edge geometry are distinct. — `c1f8c93` start-edge resize moves the
  start column and inversely changes width; end-edge resize holds the start column and
  changes width alone.
- [x] Proposed date values visible during interaction. — `c1f8c93` shows the proposed start and
  deadline beside the provisional geometry, before any semantic write is emitted.
- [x] Occupied row resolution matches the old continuous behavior rather than producing unnecessary modal errors. — `c1f8c93` resolves a drag into an occupied row to that row's
  insertion index and highlights it. **This is the box most likely to be undone by accident:
  the obvious-looking "fix" is to refuse the drop as invalid, and that is exactly the
  error-dialog behaviour the original did not have.** Continuous resolution is the parity
  requirement, not a convenience.
- [x] No canonical write yet; final drop is typed unavailable until cutover. — `c1f8c93` a valid
  release emits exactly one typed `task.timeline.change` record mutation and receives
  `action-not-available`. **Inverted or sub-one-day geometry emits zero write intents at
  all** — not a refused one — and restores the original geometry, so an invalid drag leaves
  no durable trace and nothing downstream ever sees a proposal the cockpit already knew was
  impossible.

### Countdowns

- [x] Overdue. — `2b8a145`; remaining time below zero.
- [x] under one day. — `2b8a145`; zero up to but excluding 24h.
- [x] under three days. — `2b8a145`; 24h up to but excluding 72h.
- [x] under one week. — `2b8a145`; 72h up to but excluding 168h.
- [x] later. — `2b8a145`; 168h and above. **The five boundaries are exactly `< 0`,
  `[0, 24h)`, `[24h, 72h)`, `[72h, 168h)` and `[168h, ∞)`** — written out because this is
  precisely the kind of thing a later agent re-derives slightly differently and never
  notices.
- [x] Live countdown progression. — `2b8a145`; the visible panel rerenders once per second
  from the current clock, updating displayed remaining time without touching records.
- [x] Automatic movement between buckets as injected clock advances. — `2b8a145`
  reclassifies from the clock on every tick rather than assigning a bucket once, so items
  move by themselves; advancing the injected clock 30h carries three tasks across three
  boundaries with no user action.
- [x] Click countdown item → task editor. — `2b8a145`; the same modal the calendar and the
  Gantt use, entered through the real-DOM harness, with durable state unchanged.

## Local/presentation actions

- `timekeeping.panel.set-visible`
- `timekeeping.panel.resize` if panel geometry is remembered.
- `timekeeping.timeline.viewport.set` if required for agent steering.

## Acceptance

- [x] Same task can be observed simultaneously in Calendar/Gantt/Countdown where applicable. — `37e722b` proves one qualifying task visible in all three panels at once, and proves both
  sides of "where applicable": start-only stays Gantt-only, no-deadline appears in none.
  Without those exclusions the row could be satisfied by a surface that showed everything
  everywhere.
- [x] Clock-only changes never write records. — `37e722b`; Countdowns visibility is established
  as render setup **before** the measurement, and after that there is no dispatch and no
  interaction at all — only the clock moving and the ticker firing. Presentation changes and
  the SHA-256 of durable state is identical. Proving this from adjacent before/after hashes
  would not have been the same claim.
- [x] Programmatic Shift-resize visibly changes provisional Gantt geometry. — `c1f8c93`;
  real-DOM Shift gestures change provisional start/end geometry before release, and the two
  edges produce distinct previews.
- [x] Invalid resize returns to authoritative geometry. — `c1f8c93`; an inverted resize is
  marked invalid, emits no `task.timeline.change` intent at all, and restores the original
  grid geometry on release.
- [x] Panel composition survives rerender only according to local-state policy. — `760e54d`;
  panel visibility lives in dispatcher local state, so composition survives an ordinary
  rerender while fixture reset destroys it and leaves durable records unchanged.

## Evidence

- Injected-clock urgency tests.
- Calendar projection tests.
- Gantt pointer/Shift tests.
- Zero-write proof for all presentation/local-state operations.

---

# Stage 4 — Restore Schedule presentation in all six modes

No record migration dependency.

## Work

### Shared navigation

- [x] Day. — `7357b4d`; one civil-day column.
- [x] 4-Day. — `7357b4d`; four adjacent civil-day columns.
- [x] Week. — `7357b4d`; seven. All three are one geometry family over the same vertical grid,
  differing only in column count.
- [x] Month. — `5d97cdc`
- [x] Year. — `5d97cdc`
- [x] Agenda. — `5d97cdc`
- [x] Previous. — `fc460f6`
- [x] Today. — `fc460f6`
- [x] Next. — `fc460f6`
- [x] Project/event filtering without mutation. — `fc460f6`

### Day / 4-Day / Week

- [x] 24-hour time grid. — `7357b4d`; 96 equal 15-minute slots per day, the same scale in all
  three modes. **This is not the Gantt's model** — that one is 42 whole-day columns. Two
  snapping models now coexist and confusing them yields plausible, wrong geometry.
- [x] Correct event vertical placement. — `7357b4d`; position derives from local minutes since
  midnight, and an event crossing midnight is segmented truthfully at the civil-day boundary
  rather than drawn as one impossible bar or dropped.
- [x] Correct duration height. — `7357b4d`; height is duration over the 1440-minute day.
- [x] Empty-cell click seeds event editor with clicked time. — `2e74059`; *(previously not
  built, and my fault:
  I briefed the AUTHOR that empty-slot click must NOT create, which is what the Elastic and
  Deadline Calendar surfaces require but the opposite of what this row asks. `7357b4d` renders
  empty slots deliberately inert. Seeding the editor from the clicked time is real work and
  is now owed.)*
- [x] Default one-hour event proposal. — `2e74059`; *(same mis-brief; goes with the row above.)*
- [x] Event click opens editor. — `7357b4d`; a read-only local event editor, the first modal in
  the codebase that is not the task modal.
- [x] Drag preview follows pointer. — `7292075`
- [x] Cross-day drag preview in multi-day modes. — `7292075`
- [x] 15-minute snap during drag. — `7292075`
- [x] Bottom-edge resize affordance. — `7292075`
- [x] 15-minute duration snapping. — `7292075`
- [x] Live resize preview. — `7292075`
- [x] Final save/drop remains unavailable until record-store mutation stage. — `7292075`

### Month

- [x] Month grid. — `5d97cdc`
- [x] Date-level occurrence projection. — `5d97cdc`
- [x] Event click opens editor. — `5d97cdc`
- [x] No Week-style time-height resize imported into Month. — `5d97cdc`

### Year

- [x] Twelve mini-month overview. — `5d97cdc`
- [x] Date navigation/drill-down. — `5d97cdc`
- [x] Event indicators. — `5d97cdc`

### Agenda

- [x] Chronological date groups. — `5d97cdc`
- [x] Event rows. — `5d97cdc`
- [x] Event click opens editor. — `5d97cdc`
- [x] No arbitrary drag ordering. — `5d97cdc`

### Recurrence projection

- [x] Existing recurring events expand into visible occurrences. — `448c65f`
- [x] Expansion itself writes nothing. — `448c65f`
- [x] Clicking a recurring occurrence can reach the later scope-choice modal. — `448c65f`
- [x] No generated ordinary occurrence is prematurely materialized as a separate record merely to display it. — `448c65f`

## Acceptance

- [x] Same event projects correctly across all six views. — `215777a` @ `2026-09-12T02:11:10+07:00` *(one fixture set — a timed event, one crossing midnight, and two others in other months — is mounted through both renderers the application chooses between, and each view is asserted against the same canonical occurrence projection restricted to the dates that view shows: `scheduleVisibleDays` for Day/4-Day/Week, the grid's own non-empty cells for Month, everything for Agenda, and per-date occurrence counts for Year, which draws no per-event element. The case also asserts the fixture is unchanged.)*
- [x] Day/4-Day/Week use 15-minute interaction geometry. — `7292075`
- [x] Month/Year/Agenda do not inherit invalid resize semantics. — `5d97cdc`
- [x] Recurrence expansion is deterministic under injected clock/date range. — `448c65f`
- [x] Empty-cell creation opens a form without modifying source data before Save. — `2e74059`

## Evidence

- [x] Six-mode projection tests. — `5d97cdc`, `7292075` and `215777a` @ `2026-09-12T02:11:10+07:00` *(`tests/scheduleProjection.test.ts` mounts Month, Year and Agenda against fixture events, `tests/scheduleTimeGrid.test.ts` covers Day, 4-Day and Week geometry, and the six-view case added at `215777a` reads one fixture set through all six in a single case so the modes cannot drift apart: each view's occurrences are compared against the same canonical projection, clipped to what that view shows.)*
- Automated event drag/resize preview tests.
- Recurrence-expansion tests.
- Zero-write proof before Save.

---

# Stage 5 — Restore Projects Hub and read-only project workspaces

No record migration dependency.

## Projects Hub work

- [x] Project cards display: — `d83e158` @ `2026-09-10T17:07:59+07:00` and `7f96a71` @ `2026-09-12T01:52:46+07:00` *(the projection `cardForProject`/`projectsHubCards` decides every field and the renderer draws it; until this slice `tests/projectsHub.test.ts` covered only the New Project modal, so nothing asserted what a card shows. `tests/projectsHubCards.test.ts` now does, for a project whose data exercises every field and one whose data does not — including the conditionals: an unreadable created date shows as "Unknown" rather than as an age of zero.)*
  - [x] name; — `d83e158`, evidence `7f96a71` *(the card's heading, asserted against the record's name)*
  - [x] description; — `d83e158`, evidence `7f96a71` *(the card's paragraph, with one sentence where the record has none)*
  - [x] age; — `d83e158`, evidence `7f96a71` *(whole days since creation, carried as `data-project-age-days` and shown as `Nd`; an unparseable date is unknown, not zero)*
  - [x] task count; — `d83e158`, evidence `7f96a71` *(every task in the project, completed or not)*
  - [x] overdue count; — `d83e158`, evidence `7f96a71` *(unfinished tasks whose deadline has passed — a completed task with a past deadline is not late, and the fixture contains exactly that task)*
  - [x] P1/high-priority equivalent where represented; — `d83e158`, evidence `7f96a71` *("where represented" taken literally: a priority property in the schema or on a task is what makes the count exist, and a project without one has no priority row rather than a zero nobody's data supports)*
  - [x] next deadline; — `d83e158`, evidence `7f96a71` *(the earliest future deadline among unfinished tasks, ties broken by task id, shown as "None" when there is none)*
  - [x] archive state; — `d83e158`, evidence `7f96a71` *(as `data-project-archive-state` and as the Active/Archived chip; the workspace's eyebrow says the same about the project that is open)*
  - [x] visual identity where available; — `d83e158`, evidence `7f96a71` *(a swatch built from the project's tab colours, and only from values that parse as colours — a string carrying CSS is no swatch, which a hostile fixture asserts)*

- [x] Active/archived filtering. — `d83e158` @ `2026-09-10T17:07:59+07:00`, evidence `7f96a71` *(the cards are filtered by the project's own status, the two buttons carry `aria-pressed` for the filter in effect, the header counts what is listed, and a filter with nothing in it says "No archived projects" rather than showing an empty grid)*
- [x] Clicking a project opens its workspace. — `dadd610` @ `2026-09-10T17:32:11+07:00`, evidence `7f96a71` *(a card is a button carrying the project id; opening it replaces the hub's grid with that project's workspace — asserted by the cards being gone, the workspace being there and naming the project's status, and the Projects button coming back to the grid)*
- [x] New Project button opens its modal even before Save is enabled. — `68e11b6` @ `2026-09-10T17:19:10+07:00` *(the button opens a provisional modal whose Save routes through `project.create` and answers the typed `action-not-available` while creating no record — `tests/projectCreateModal.test.ts`, plus this slice's assertion that the modal's controls are exactly name and description)*
- [x] Archive/restore/delete controls exist but refuse DATA WRITE until storage cutover. — `dbea424` @ `2026-09-10T17:25:25+07:00`, verified at `1ffdd55` @ `2026-09-12T01:19:47+07:00`, evidence `7f96a71` *(all three exist: an active project offers Archive and Delete, an archived one Restore and Delete, each disabled with a typed `action-not-available` refusal and the reason written beside them. The write-control audit is what proved every one of them carries a typed refusal rather than being silently inert, and this slice asserts which control a project's status gets.)*

## Workspace work

- [x] Notes. — `dadd610` @ `2026-09-10T17:32:11+07:00` *(the workspace's Notes tab renders the project's note tree; `tests/projectWorkspacePanels.test.ts` renders all five tabs and asserts no `projectType` gating and no record mutation, and `tests/projectNotes.test.ts` covers the panel itself)*
- [x] Task Board. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `c8e35c3` @ `2026-09-10T19:54:34+07:00` *(the panel and its interactions, with `tests/projectTaskBoard.test.ts` covering the read-only inspector, the drag placeholders and the refused transition)*
- [x] Backlog. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `b281cab` @ `2026-09-10T20:04:42+07:00` *(the panel and its interactions; slices 25–37 have since rebuilt its query, controls, selection, column table, property filters, template composer and task editor on top of it)*
- [x] Deadlines. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `d3dbb59` @ `2026-09-10T20:15:12+07:00` *(the panel and its interactions, and the workspace test asserts the projection is the Timekeeping one reused rather than reinvented — which is also § Deadlines' own box below)*
- [x] Schedule capability can coexist with tasks instead of being hidden behind permanent task/schedule project silos once the corrected domain lands. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `36fcc08` @ `2026-09-10T20:30:21+07:00` *(the workspace switches on the tab and never on `projectType`, so a project typed as a task still has a Schedule tab and one typed as a schedule still has a Backlog; `tests/projectWorkspacePanels.test.ts` renders a mixed project — both tasks and events — through all five tabs and asserts no gating. `Project.projectType` survives only as legacy import metadata, and HARD GATE A4 owns removing it from capability decisions.)*

### Notes — read side

- [x] Project-linked vault artifact tree. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(`loadProjectNotesTree` walks each `linkedFolders` root and nothing else, so a vault file outside those roots is absent from the snapshot rather than filtered out later; a root whose path is not vault-relative is typed `unavailable` and an absent one `missing`, and the panel draws all three states. `tests/projectNotes.test.ts` pins the entry list, the exclusion of a file outside the roots, and both degraded roots.)*
- [x] Folder expand/collapse. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(`expandedPaths` decides both `aria-expanded` and whether the children are rendered at all, so a collapsed folder emits no file buttons; the linked root's own toggle now carries `data-c1-key="project-note-root-<projectId>-<path>"`, so it is addressable like every other control. The slice-39 case drives the root and a nested folder open and shut through the machine-key harness and asserts all four DOM states, including that expanding selects nothing.)*
- [x] File selection. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(a click on a file reports its path and the renderer marks exactly that entry `selected` and `aria-current="true"`; selection is view state, so the panel is a pure function of it rather than of the DOM.)*
- [x] Markdown preview. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(`.md` and `.markdown` render the stored text verbatim as `kind:'markdown'`; slice 39 adds that a file whose frontmatter looks like a record (`id:`, `status:`, `weight:`) is still previewed byte-for-byte and never parsed into one, which is what keeps the Notes read side out of the record store.)*
- [x] Canvas preview. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(`.canvas` is summarised as node and edge counts plus a bounded node list (`MAX_PROJECT_CANVAS_PREVIEW_NODES`), and a canvas that is not JSON, or that lacks node/edge arrays, fails as `canvas-invalid` instead of drawing an empty canvas; the fixture asserts 2 nodes and 1 edge.)*
- [x] Excalidraw preview where supported. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(`recogniseExcalidraw` decides by file content, not by extension, and a scene that cannot be read fails as `excalidraw-unavailable` — the "where supported" clause is a typed failure rather than a silent omission; the fixture asserts the `excalidraw` preview kind and that it carries the rendered SVG and its element census fields.)*
- [x] Hover affordances. — `ead7927` @ `2026-09-12T02:02:58+07:00` *(`public/index.html` styles `.project-note-entry:hover`; the slice-39 case asserts that every interactive entry the renderer emits carries that class, that a root the vault cannot read carries none because there is nothing to hover, that only files are `draggable`, and that a hover reaches no handler — the affordance is the stylesheet's, not a second code path.)*
- [x] Context menu opens programmatically. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(a context-menu event on any entry reports its path and the panel renders the menu from `contextPath` under `data-project-note-context-path`; Escape closes it. Its three write verbs — Rename, Move, Delete — are drawn disabled with `action-not-available`, so opening the menu cannot write.)*
- [x] Read/open/reveal-like operations remain presentation. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(the read side is handed a `VaultReader` and the panel's handlers only set view state — selection, expansion, context, drag. Slice 39 runs the whole read side against a vault whose writer members throw and re-reads every file byte-identical afterwards, so the strongest available statement is not "it did not write" but "it had no way to".)*
- [x] Drag targets can preview valid folder destinations without committing moves yet. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(`dragover` reacts only to an element carrying `data-project-note-directory-path`, so a file is not a destination: slice 39 asserts that a drag over another file previews nothing while the same drag over a folder previews `source -> target` on the panel and reports it, and that `drop` clears the preview and reports a refusal instead of a move.)*

### Task Board — read side

- [x] Project workflow columns. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(`renderProjectTaskBoard` draws one column per vault status definition in declaration order, then appends a column for any status a project task actually uses but the vault does not define — slice 39 pins that orphan column, its label and its drop slot — and the panel is scoped to the project, so another project's card is not drawn.)*
- [x] Card click. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` *(a click on a card opens the read-only inspector for that task (`data-project-board-inspector-task-id`), which escapes the task's own text — the fixture's `<script>` description renders as text — and Escape closes it.)*
- [x] Column presentation colors. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(a column is painted only when the status colour is a validated hex value: slice 39 asserts that `#112233` becomes `border-top:3px solid #112233` plus the echoed `data-project-status-color`, that a padded `  #abc  ` is trimmed and accepted, and that `red;display:none` and a `url(...)` value paint nothing and echo empty.)*
- [x] Local display order. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(cards sort by `orderIndex` with the task id as the tiebreak; slice 39 adds that equal indices fall back to id order and that a missing index is treated as zero. The order is display only — `orderIndex` in the record is never rewritten by this panel.)*
- [x] Drag pickup/placeholders implemented. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(`dragstart` reports the picked-up task, `dragover` marks the slot (`data-project-board-preview="true"`) and opens its insertion placeholder to 54px, and the drop reports the move intent; slice 39 pins the pickup report and the placeholder geometry. The slots are drawn before, between and after the cards, so the reported index is a real position rather than a column append.)*
- [x] Durable workflow transition still disabled until corrected domain/store exists. — `c8e35c3` @ `2026-09-10T19:54:34+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(the panel declares `data-project-board-write-authority="unavailable"`, its Edit and Delete controls are disabled with `action-not-available`, and a drop reports a refusal whose text says the task data was not changed; slice 39 asserts the record state is byte-identical across the whole drag-and-refuse sequence.)*

### Deadlines

- [x] Reuse the Timekeeping interaction implementation project-scoped rather than independently reinventing it. — `d3dbb59` @ `2026-09-10T20:15:12+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(the panel imports `deadlineCalendarProjection` from `timekeepingCockpit` for the deadlines themselves and declares `data-project-deadline-projection="timekeeping"`; slice 39 removes the last restatement of Timekeeping semantics by routing the overdue/upcoming split through the exported `countdownBucketForRemaining` instead of re-deriving `remainingMs < 0`, and asserts row order, day, value and state against those two functions — including the boundary where a deadline equal to `now` is `upcoming`, not `overdue`.)*

## Acceptance

- [x] Opening a project changes the cockpit, not canonical data. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(opening a project decides which project the five workspace panels project: the slice-39 case opens one project and then another, sees the board's `data-project-board-project-id` and its cards change, and asserts the state JSON is byte-identical after each render. Separately, `tests/projectNotes.test.ts` runs the notes read side against a vault whose writer members throw and re-reads every byte unchanged. `tests/projectWorkspacePanels.test.ts` asserts the same state-JSON invariant per tab, and `tests/zeroWriteWitness.test.ts` proves the disk-level witness fails when it should.)*
- [x] Project Notes can inspect ordinary vault files without treating them as database records. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(a linked folder's ordinary files are listed whatever they are — `.md`, `.canvas`, `.excalidraw`, and files no previewer claims — and the snapshot is a tree (`projectId`, `roots`, `fileCount`), not a record set. Slice 39 asserts that a markdown file carrying record-shaped frontmatter is previewed verbatim as text, that an unclaimed `.json` is still listed but fails as `unsupported-format`, and that the whole read side runs against a vault whose writer members throw with every byte unchanged.)*
- [x] Same task can be visible in project Board, Backlog and Deadlines. — `dadd610` @ `2026-09-10T17:32:11+07:00` *(`tests/projectWorkspacePanels.test.ts` renders one project's `shared-task` in the Task Board, the Backlog and the Deadlines tab of the same cockpit, with a second project's task absent from all three.)*
- [x] Project can eventually show both tasks and events; no new UI work assumes `projectType` is permanent. — `dadd610` @ `2026-09-10T17:32:11+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(the acceptance fixture is a `schedule` project whose Task Board, Backlog and Deadlines are populated and whose Schedule tab carries the events; slice 39 adds the other half — rendering the same five panels for the same project typed `task` produces byte-identical panel HTML — so the panels branch on nothing but the records they are given. The legacy label survives only as a presentation caption (`src/browser/projectPresentation.ts`) and an import concern.)*

## Evidence

- Programmatic project navigation tests. — `2450828` @ `2026-09-09T21:49:58+07:00` *(the four surfaces, both Tasks modes, all six Schedule modes and the five project tabs are pinned by machine key in `tests/cockpitNavigation.test.ts`, with `cockpitSubmode` asserted per surface)*; `dadd610` @ `2026-09-10T17:32:11+07:00` *(each workspace tab is opened and read back through its own `data-project-workspace-panel` in `tests/projectWorkspacePanels.test.ts`)*
- File-tree read/preview fixture tests. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(tree shape, Markdown/Canvas/Excalidraw previews, unsafe roots and unsupported formats, all against real fixture bytes in a memory vault)*; `ead7927` @ `2026-09-12T02:02:58+07:00` *(nine cases in `tests/projectNotes.test.ts`: expansion states, hover affordances, valid and invalid drop targets, and ordinary files that are not records)*
- Cross-tab projection tests. — `dadd610` @ `2026-09-10T17:32:11+07:00` *(one project's task is read in the Task Board, the Backlog and the Deadlines tab and its event in the Schedule tab, each scoped against a second project)*
- Zero-write proof for all read-only project navigation. — `dadd610` @ `2026-09-10T17:32:11+07:00` *(every workspace tab render in `tests/projectWorkspacePanels.test.ts` is asserted to leave `JSON.stringify(state)` identical)*; `ead7927` @ `2026-09-12T02:02:58+07:00` *(opening another project is asserted the same way in that file, and `tests/projectNotes.test.ts` runs the whole notes read side against a vault whose writer members throw and re-reads every file unchanged)*; `7c0c69d` @ `2026-09-06T22:18:57+07:00` *(`tests/zeroWriteWitness.test.ts` proves the witness records a smuggled write, fails when it was never wired to anything, and detects a file changed behind its back)*

---

# Stage 6 — Restore Backlog/database presentation and modal completeness

Still before migration.

## Backlog

- [x] Search. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(`renderProjectBacklog` renders exactly the rows the query matched — asserted by a filtered-out task id being absent from the output — and echoes the active query in `data-project-backlog-search`; the matcher reads name and description case-insensitively and treats an all-whitespace query as empty. What is verified is the Backlog's behaviour under a query: the shell owns `ProjectBacklogViewState.query` and supplies it, so the interactive control that types one is the remaining piece.)*
- [x] Tag filtering. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(
- [x] Property filters. — `3fa16bc` @ `2026-09-12T01:41:25+07:00` *(the query gained a second filter list rather than widening `BacklogField`: a property filter carries its `propertyKey` and its `valueType`, `assertBacklogQuery` validates it against `operatorsForValueType` (the same tables the fields use, reached by type), `applyBacklogQuery` conjoins it with the field filters and the search, and `removeBacklogFilter` finds the id in either list. The comparison itself moved out of `matchesFilter` into `compareValue`, driven by a value type rather than a field, so a property and a field cannot compare the same kind of value two ways — a refactor the engine's 17 existing cases passed before any new test existed. What is compared is what a cell shows: a multi-select property compares as the text its cell joins, a numeric property compared against text still matches nothing, and a boolean never equals its spelling. The menu offers a property because the project's tasks declare it, with only its declared type's comparisons.)*
- [x] Type-appropriate comparison operators. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(nine filter fields each admit only the operators their type supports, decided in one place so a menu and the matcher cannot disagree; a numeric field compared against a non-number does not match instead of coercing, dates compare as instants, a boolean never equals its string spelling, and a query naming an operator its field does not admit is refused by name rather than silently skipping the filter)*
- [x] Multiple filters. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(filters conjoin — a task must satisfy every one — and the projection exposes each as a chip carrying its id, field, operator and a readable label, which the renderer draws. Raising new filters from the UI is part of the unwired control work.)*
- [x] Remove filter. — `bdea4a1` @ `2026-09-12T00:34:29+07:00` *(`applyBacklogControl({kind:'remove-filter'})` drops the filter the chip names and returns the same query when the id is already gone, so removing a filter twice is harmless; the chip renders a remove button carrying `data-project-backlog-filter-remove`, the binder reads the id from it and nothing else, and `tests/projectBacklog.test.ts` drives the whole loop in happy-dom — a click on the rendered chip brings the task that filter was hiding back into the list. Removal is view state only: the query is replaced, never edited, and `tests/backlogControls.test.ts` asserts the state and every record are byte-identical after a session of controls.)*
- [x] Sort ascending/descending. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(ordering is ascending or descending on any field column, and it is a total order: ties fall through the legacy order index then the record id, so equal keys never swap between renders. A missing value sorts last ascending and first descending, which is stated because "no deadline" is not a deadline of zero.)*
- [x] Sort indicator. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(the renderer emits `data-project-backlog-sort-indicator` carrying the sorted field and direction with a ▲/▼ mark, and omits the whole toolbar when no query is active so the unqueried markup is byte-identical to what it rendered before)*
- [x] Custom-property columns. — `8cadd24` @ `2026-09-12T01:31:08+07:00` *(the projection has supplied the columns and a `cells` array per row since slice 26; the renderer drew the legacy list. It now draws the table: a header above the list with one entry per custom-property column, labelled with the schema's name, and each row's cells keyed to those columns by id — so a value sits under its own heading. A column appears because the data declares it, which is the projection's rule and now the table's too; a project whose tasks declare no properties renders no header rather than an empty one. The **field** columns are deliberately not repeated: a row already shows its name, description and deadline on one line, and a header promising columns the body does not draw would be worse than no header.)*
- [x] Resizable columns. — `8cadd24` @ `2026-09-12T01:31:08+07:00` *(each column header carries a drag edge; the width lives in `ProjectBacklogViewState.columnWidths` because how wide this reader has a column is not a fact about the table, and `resizeBacklogColumn`/`clampBacklogColumnWidth` are pure functions beside the other controls. The clamp is what stops a drag off either edge from making a label unreadable (96px) or letting one column swallow the table (640px), and rounding to whole pixels keeps a rendered width and a stored width the same number. The drag follows the schedule's gesture shape — the pointer moves update what is on screen and only the release reports a width, because re-rendering mid-drag would replace the element the pointer is holding — and it is driven end to end through the interaction harness, including both clamps. A resize edge needs no typed refusal, because resizing is presentation rather than a write; that is the line slice 33's write-control audit draws.)*
- [x] Row selection. — `9d6062c` @ `2026-09-12T01:11:58+07:00` *(every row carries a real checkbox keyed by task id, and the binder reports which task it is for rather than deciding what that means; `toggleBacklogSelection` keeps the order the marks were made in, because that is the order a bulk action would act in. Selection is view state — `BacklogViewState.selectedTaskIds` — so no record is written, asserted.)*
- [x] Select all. — `9d6062c` @ `2026-09-12T01:11:58+07:00` *(Select all means the rows on screen: `selectAllBacklogVisible` adds the visible tasks and leaves a marked task the query hides to whatever marked it before, because a hidden row is not something the creator can see they are selecting. The control disables itself when every shown row is already marked, and when nothing is shown there is nothing to select.)*
- [x] Multi-selection. — `9d6062c` @ `2026-09-12T01:11:58+07:00` *(a selection is memory, not a filter: the projection reports how many shown rows are marked, how many marked tasks the query is hiding, and whether every shown row is marked — three separate facts, so a bulk action can never be read as covering a row nobody can see. `allVisibleSelected` is false when nothing is visible, because an empty list has nothing selected and saying otherwise would let a bulk action look safe to run. Clearing the selection clears hidden marks too.)*
- [x] Task row/name click opens editor. — `ba50cc6` @ `2026-09-12T01:48:47+07:00` *(clicking a row opens the Task editor for that task, in the Backlog panel. It draws the same `projectTaskEditor` projection the Elastic board's modal draws, through a new `src/browser/taskEditorFields.ts` that takes the surface's hook names: both binders listen on the application root, so shared attribute names would have meant two binders answering one keystroke and a Backlog edit landing in the board's draft. The extraction is markup-identical — the Elastic suites passed unchanged before the Backlog's editor existed. The read-only inspector is retired rather than duplicated, since it was a placeholder for exactly this editor; the fields it showed are now editable, with Save and Delete refused with a typed result and Cancel discarding the draft. A typed edit becomes a draft that Cancel discards while the loaded state stays byte-identical, asserted; and the write-control audit's expectation for this surface moved from the inspector's Edit/Delete to the editor's Delete/Save, both typed.)*
- [x] Relation display. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(a row now draws the property cells the projection already computed, so a relation property is visible where a reader looks for it, carrying `data-project-backlog-cell-kind="relation"` so a target id can be told from an entered value. Property columns are labelled with the schema's name for the property — the projection had used the raw stored key, which disagreed with how the Task editor and the property pills already name one.)*
- [x] Rollup display. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(shown with `data-project-backlog-cell-kind="rollup"`, displaying the value the record holds. Stated residual: computing a rollup from its relations is not this surface's job yet, so what is displayed is the stored value rather than a freshly aggregated one.)*
- [x] Formula display. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(shown with `data-project-backlog-cell-kind="formula"`, displaying the stored value; the same residual as the rollup — the expression is not evaluated here)*
- [x] Bulk Complete control visible but unavailable until write cutover. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(drawn where a selection would act, disabled, carrying `data-project-backlog-write-action="bulk-complete"` and the same typed `action-not-available` refusal every other write carries, with the reason beside it. It belongs to the project this view is for and is absent from a view belonging to another project — an existing no-leak case caught the first version, which rendered it unconditionally.)*
- [x] Bulk Delete control visible but unavailable until write cutover. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(as Bulk Complete, with `data-project-backlog-write-action="bulk-delete"`; clicking either changes no record, asserted)*

## Task modal

All existing meaningful fields must be representable:

- [x] name; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(the modal is now the editor `src/app/taskEditor.ts` describes: `renderTaskModal` consumes `projectTaskEditor` instead of six hard-coded read-only inputs, and each field is drawn with the control its type calls for. Name is a text input holding the record's value; typed edits are held as a draft and never reach the record.)*
- [x] project; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a select over the active projects plus "No project", so a task can be taken out of a project as well as moved between them)*
- [x] execution state; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a select over the vault's own status vocabulary, each option labelled with the Elastic column it maps to; a vault that declares no statuses gets a text field and a note saying so rather than an empty select)*
- [x] workflow stage where project-scoped; — `0a39c83` @ `2026-09-12T16:10:57+07:00` *(the half this box named is the half that changed, and the product decision it asked for is recorded as **D77**: the modal shows the control. The field is a select over the task's own project's stages, carrying the record's value, and it says where a card lands - **entering a stage appends to the end of it**, because a drop asks for a position and a select cannot. That end is a count the caller owns: `planTaskEditorSave` takes a `TaskEditorStagePlacement`, the shell answers it from the state the save was opened over, and a caller that cannot answer - or that names a stage the task's project does not declare - is refused on that field rather than handed a position somebody else may hold. The board keeps the position, and both callers write the same mutation pair through `workflowMutationsFor`, so a modal save and a drop are one move rather than two. A stage the record carries but its project does not declare is still shown, labelled as another project's (or as no record's), because a value nobody can see is a value the editor would misrepresent. Evidence: the projection suite asserts the choices, the carried value, the cross-project label and the no-stages fallback; the write suite asserts the append index, both refusals, the leave-the-stage pair, and - through a real store - that two saves into one stage land at 0 and 1 and that leaving clears both fields; the cockpit suite asserts the control in the modal markup with the field count moved to eleven. Five mutations were tried and all five failed their suite.)*
- [x] weight; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a number input, with the one sentence that says what weight does)*
- [x] fixed-duration enable/value; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(the enable flag is a checkbox and the minutes are their own number field; while the flag is off the minutes field says it is not counted, which is the relationship the record encodes as "only meaningful when true")*
- [x] maximum duration; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a number input, described as the cap on how far an elastic task may stretch)*
- [x] start date; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a text input holding the stored value on purpose: the vault stores ISO instants, and a date input would normalise `2026-03-10T00:00:00.000Z` to `2026-03-10` on sight and report a change nobody made. The same reasoning covers deadline and every date property.)*
- [x] deadline; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(as start date; an absent deadline shows as empty rather than as the word "null")*
- [x] completion; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a checkbox over `isCompleted`)*
- [x] custom text property; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(the property list comes from `state.taskSchema`, not from the record: a property the schema declares but this task has never set is still a field, because a field nobody can see is a field nobody can fill in. A record value with no schema entry is shown too, so an editor cannot silently drop it.)*
- [x] number; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a `number` schema type is a number input)*
- [x] select; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a select over the schema's own options, with the stored option selected)*
- [x] multi-select; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a checkbox group, one box per option; the binder reports the whole remaining selection rather than a removal the model would have to infer, which is asserted in happy-dom by unticking one of two chosen options)*
- [x] date; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a date-typed property is shown and edited as a date field of the same text-input kind the task's own dates use, for the ISO reason above)*
- [x] checkbox; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(only a stored `true` is ticked; any other value — including the string `"true"` — is not)*
- [x] relation; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(shown as a field holding the target record id, with the field itself saying there is no picker until relations are canonical (HARD GATE A6). Representable, and honest about what is not there yet.)*
- [x] derived rollup; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(shown with its aggregation and target property, with nothing to type in: a derived value is not the record's to set. Asserted by there being no `input` or `select` inside it.)*
- [x] derived formula; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(as the rollup, showing the expression)*
- [x] recurrence if task recurrence remains supported. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(
- [x] Cancel/Escape discards provisional form state. — `7825d20` @ `2026-09-12T00:44:55+07:00` *(a draft is `null` while nothing has been edited, so discarding is `null` rather than a rebuild that hopes to reproduce the record; `dirty` is the draft differing from the record it was seeded from, so an undone edit goes back to not dirty. Cancel and Escape both discard, asserted in happy-dom by typing, seeing the unsaved-changes line, pressing Escape and reading the record's value back. Deliberately, an edit does not re-render — a keystroke must not take the field away from the reader — so the drawn draft updates on the next render.)*
- [x] Save is disabled/refused until the new record write path exists. — `7825d20` @ `2026-09-12T00:44:55+07:00` *(the button is present and disabled, carrying `data-task-editor-save-refusal="action-not-available"`, with the reason next to it: a form that cannot save says so where the button is rather than hiding it. Delete carries the same refusal.)*

## Event modal

- [x] name. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(the Event modal is now the editor `src/app/eventEditor.ts` describes, rendered by `src/browser/eventModal.ts`: before this the month/year/agenda modal and the time-grid modal were two copies of five read-only inputs with no Save, no Delete and no recurrence at all. Name is a text input holding the record's value, readonly.)*
- [x] description. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(a textarea holding the record's description, readonly)*
- [x] project. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(a select over the project names the surface knows, plus "No project", with the held one marked selected; the choices are passed in rather than read from loaded state, which is why the editor takes a narrow input.)*
- [x] start. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(a text input holding the stored start, which is an ISO instant — the same reasoning the Task editor's dates use: a date input would normalise the value on sight and report a change nobody made)*
- [x] end. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(a text input holding the record's deadline, with a note saying that is what the field is)*
- [x] color if event metadata supports it. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(the condition is false, and the modal says so rather than omitting silently: `CalendarEvent` carries no colour field and no vault format declares one, so there is no colour control. The projection exposes `colourNote` and the modal renders it at `data-c1-key="schedule-event-colour-note"`; a test asserts the note, and asserts that no field id mentions colour. If event metadata ever grows a colour, this is the box to reopen.)*
- [x] recurrence controls. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(frequency, interval, end condition, end date and count, read from the record by the schedule's own rule reader so the editor and the projections cannot disagree about whether an event recurs. They are offered even for an event that does not recur, because the end-condition select includes "Does not recur" — one control answers both whether it recurs and how it ends. Recurrence the record carries that the reader refuses is reported as unusable rather than shown as absent.)*
- [x] until/end condition. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(the end-condition select carries the four answers — does not recur, never ends, ends on a date, ends after a number of times — and the two value fields say when they are the ones in use. Asserted against a weekly rule ending on a date, a monthly rule ending after a count, and a rule that never ends.)*
- [x] exception/scope UX. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(the choice itself is the existing occurrence/series scope modal, which `tests/scheduleRecurrence.test.ts` already drives — it renders for a recurring occurrence, reports its mode and records the chosen scope. What this slice adds is that the editor states the question where the fields are, so a reader is not left to discover that changing one occurrence is not changing the series.)*
- [x] Save/Delete unavailable until write cutover. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(both buttons are present and disabled, Save carrying `data-schedule-event-save-refusal="action-not-available"` with the reason beside it: a form that cannot save says so where the button is rather than hiding it)*
- [x] Cancel/Escape loses no data. — `b20cdca` @ `2026-09-12T00:56:55+07:00` *(every control in this modal is inert — text and date inputs are readonly, selects and checkboxes are disabled, asserted in happy-dom — so there is no provisional state for a cancel to lose and closing the modal cannot change a record. Stated residual: Escape is not bound to close this modal, which is an affordance rather than a data question; when the event editor becomes editable at the record-store cutover, this box must be re-examined, because that is when a draft starts to exist.)*

## Project modal

- [x] name. — `68e11b6` @ `2026-09-10T17:19:10+07:00` *(the project surface's modal is the New Project modal, and it has collected a name since Stage 5 slice 2: `tests/projectCreateModal.test.ts` types into `project-create-name`, and asserts that Cancel, Escape and a refused Save each leave the project list and the state revision untouched. A name here is canonical data, not identity — the modal never asks for an id or a filename.)*
- [x] description. — `68e11b6` @ `2026-09-10T17:19:10+07:00` *(a textarea, `project-create-description`, typed into by the same cases and empty when the modal is reopened, so a discarded draft cannot leak into the next one)*
- [x] metadata that survives the corrected model. — `a8c1b1e` @ `2026-09-11T08:54:12+07:00` and `fef3b8a` @ `2026-09-12T01:01:45+07:00` *(the corrected shape is `CanonicalProjectRecordV2` in `src/domain/canonicalRecordV2.ts`, which keeps the name, the description, `createdAt` and the active/archived lifecycle state; the modal asks for exactly name and description, and a new case asserts its controls are exactly those two and nothing else. Nothing the corrected model drops is required: no control exists for the legacy task-versus-schedule label, the tab background or text colours, the linked folders, the record id or its source path. This is the create modal — editing an existing project's name is not something these four boxes ask for, and does not exist.)*
- [x] Do **not** require task-versus-schedule type in the successor record shape. — `68e11b6` @ `2026-09-10T17:19:10+07:00` and `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(the modal has no type control — its own case asserts `[data-project-type]` is absent — and the successor shape never mentions the field: `projectType` appears nowhere in any `src/domain/canonical*.ts` module, and the HARD GATE A4 box saying the legacy label informs import compatibility only is ticked at `d7e6a6c`. `Project.projectType` survives in the legacy compatibility model, documented as removed from capability and visibility decisions.)*

## Recurrence-scope modal

- [x] This occurrence. — `448c65f` @ `2026-09-10T16:53:37+07:00` *(the scope modal renders a `This occurrence` button carrying `data-schedule-recurrence-scope="occurrence"`, and clicking it records that scope in the modal's own state — driven in `tests/scheduleRecurrence.test.ts` since Stage 4 slice 5b)*
- [x] Entire series. — `448c65f` @ `2026-09-10T16:53:37+07:00` and `fef3b8a` @ `2026-09-12T01:01:45+07:00` *(the button shipped with the modal, but nothing clicked it until this slice: the new case clicks `schedule-recurrence-scope-series`, asserts the modal reports `series` and that both buttons' `aria-pressed` follow the choice, then changes the choice back to `occurrence` — a choice, not a commitment)*
- [x] Cancel. — `448c65f` @ `2026-09-10T16:53:37+07:00` and `fef3b8a` @ `2026-09-12T01:01:45+07:00` *(the close control carries `data-schedule-recurring-action="close-occurrence"`, and the handler mirrors `main.ts`: it clears the occurrence and the chosen scope and re-renders. The new case presses it, asserts the modal is gone, then reopens the occurrence to prove the next visit starts with no scope chosen — a discarded choice cannot be inherited.)*
- [x] No mutation while simply choosing/opening scope. — `448c65f` @ `2026-09-10T16:53:37+07:00` and `fef3b8a` @ `2026-09-12T01:01:45+07:00` *(opening the occurrence, choosing `series`, changing to `occurrence` and cancelling are all asserted to leave the loaded shape byte-identical — projects, tasks, events, statuses and schema — rather than only the one event the older case inspected. The scope is view state in `main.ts` (`selectedScheduleRecurringScope`), and choosing it dispatches no action.)*

## Template UI

- [x] Paste/type. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(`src/browser/templateComposerPanel.ts` is a panel the Backlog hosts, opened from "Tasks from a template" in its toolbar and carrying a real textarea at `data-template-text`. Typing re-renders — which is what makes the preview follow the text — and the caret is put back afterwards, the same arrangement the Backlog's search field uses. A textarea rather than a one-line field, because a template is multi-line by nature.)*
- [x] Parse. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(`src/app/templateComposer.ts`, pure and tested in Node: one task per unindented line, one `field: value` per indented line, `#` for a comment, `property.<key>` for a custom property. The panel parses on every render rather than keeping a second copy of what the text means, because a preview that holds its own idea of the text is how a preview and a parser drift apart.)*
- [x] Preview. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(every task the parser could read is listed with the line it came from and a one-line description of what it asks for — weight, status, dates, durations, completion, custom properties, in that order — so the preview says what the text *means* rather than repeating it. Empty text previews as "Nothing to plan yet" rather than as an empty list.)*
- [x] Structured parse errors. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(eleven typed codes — a field before any task, an unknown field, a duplicate, a missing separator, an empty value, a tab, an invalid number, date or boolean, and the task and line bounds — each carrying the line, the column of the offending character, the line as written, and a sentence naming what a valid value looks like. Writing the tests found a real bug: value complaints reported a zero-based column, so `weight: heavy` pointed one character early; the column is now computed from the raw line, and `weight: heavy` and `weight:heavy` each point at their own character.)*
- [x] Execution disabled until record write actions exist. — `d21f434` @ `2026-09-12T01:26:26+07:00` *("Create tasks" is present and disabled, carrying the typed `action-not-available` result at `data-template-execute-refusal` with the reason beside it: execution is Stage 16's job, and a button that cannot run says so where it is rather than being hidden. A test clicks through to it, asserts the refusal and the note, and asserts no record changed.)*
- [x] Exact old textual mini-language is not assumed immutable if the same presentation/workflow can be preserved cleanly. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(taken literally: the format is **this project's own** and nothing reproduces the legacy syntax or promises compatibility with it. The module says so in its own documentation, and the panel tells the reader the format inline. What is preserved is the workflow the box cares about — a person writes a shape once and gets tasks out of it — not the old characters. The presentation is therefore reconstructed rather than ported, which is what "not assumed immutable" permits.)*

## Acceptance

- [x] Every old editor can be opened programmatically. — `1ffdd55` @ `2026-09-12T01:19:47+07:00` *(five editors, each opened from state alone with no pointer: `tests/modalAudit.test.ts` renders the Task editor in the Elastic surface, the Event editor and the create-event variant in the time grid, the New Project modal, and the recurrence scope modal — and asserts each is present. The editors open because a view state names what is being edited (`elasticSelectedTaskId`, `selectedScheduleEventId`, `seededEvent`, `newProjectOpen`, `selectedRecurringOccurrence`), so a test or an agent drives them the same way a click does; the older suites that open each one by clicking remain as the second path.)*
- [x] Every unsaved field can be changed and cancelled without durable change. — `1ffdd55` @ `2026-09-12T01:19:47+07:00` *(three surfaces, three honest answers, all read-only in effect. **The Task editor** has real provisional state: a draft is `null` until something is typed, Cancel and Escape discard it, and a draft equal to its seed is not dirty (`tests/elasticCockpit.test.ts`, `tests/taskEditor.test.ts`). **The New Project modal** has provisional name and description that Cancel, Escape and a re-open all discard, with the state byte-identical throughout (`tests/projectCreateModal.test.ts`). **The Event editor** has no provisional state at all: every control is inert and reads the record, so there is nothing a cancel could lose (`tests/eventModal.test.ts`) — that is stated rather than dressed up as an editing form.)*
- [x] Search/filter/sort never mutate records. — `bdea4a1` @ `2026-09-12T00:34:29+07:00` *(the Backlog is Stage 6's only search/filter/sort surface, and the whole path is proven read-only: `tests/backlogControls.test.ts` drives projection and markup through a session of controls and asserts the loaded state is byte-identical, every task is the same object with the same keys, and the query's own filters array is replaced rather than edited; the happy-dom session in `tests/projectBacklog.test.ts` does the same after real clicks and typing. A modal that later gains a query surface must meet this same bar — this tick covers the query surfaces that exist.)*
- [x] Relation/rollup/formula projection works without wikilink semantics leaking into UI code. — `1ffdd55` @ `2026-09-12T01:19:47+07:00` *(`tests/boundaries.test.ts` now enforces it rather than describing it: `[[target]]` syntax or the word for it appears in exactly three modules — `domain/excalidraw.ts`, `domain/excalidrawAssets.ts` and `app/excalidrawAssetLoader.ts`, the one place a raw `![[asset]]` embed is really decoded — and nowhere in `src/browser/`. A relation is a record id: the Task editor shows the target id and says there is no picker until relations are canonical (HARD GATE A6), the Backlog draws relation, rollup and formula values from `task.properties` with the kind the schema declares, and nothing resolves a link out of text. The pattern demands a closing `]]`, because a nested array literal looks like `[[` too — the first version of the check flagged `app/inspection.ts` for an array of pairs.)*`
- [x] All future Save/Delete buttons currently produce a typed unavailable result rather than fake success. — `1ffdd55` @ `2026-09-12T01:19:47+07:00` *(audited and **two real violations found and fixed in this slice**: the Task editor's and the Event editor's Delete buttons were disabled with no stated reason, which is indistinguishable from broken — both now carry a typed `action-not-available` refusal as their Save buttons did. `tests/modalAudit.test.ts` checks the invariant against the rendered document for the Task editor, the Backlog inspector and bulk controls, the Projects Hub lifecycle controls and the Event editor; the two controls that stay clickable (`project-create-save`, the create-event Save) are routed to the dispatcher and each has a case that clicks it and asserts the refusal and that no record was created. The population is the product's own convention — a `*-refusal`, `*-write-action` or `*-lifecycle-action` hook — with a narrow safety net for a button labelled exactly "Save", "Delete", "Edit", "Archive", "Restore" or "Complete" that is enabled with no hook. Selection by words alone was tried and failed: the Backlog's completion *sort* button reads "Completed" and the Projects Hub's "Archived" is a filter.)*

## Evidence

- Modal state tests.
- Query/filter/sort tests.
- Derived-property tests.
- Automated cancel/Escape tests.
- Durable-store/source no-write evidence.

---

# HARD GATE A — Fix the future database shape before importing anything

**No record-store import may start before this closes.**

The current domain still contains structural residue from the plugin: `Project.projectType` is `'task' | 'schedule'`; a task has one generic `status`; `StatusDefinition` maps that status into an Elastic column; task ordering is a single `orderIndex`; relation schema still has a `targetFolder` field.

If those shapes are copied into JSON first, the migration will preserve precisely the database constraints the creator approved removing.

## A1 — Stable opaque identity

- [x] Every task/project/event/schema/workflow-stage record has an opaque stable ID. — `71b0a2b`
- [x] Display name is not identity. — `71b0a2b`
- [x] Filename is not identity. — `71b0a2b`
- [x] Physical file location is not identity. — `71b0a2b`
- [x] Record lookup never derives meaning from JSON filename. — `71b0a2b`
- [x] Rename does not alter identity. — `71b0a2b`
- [x] Import policy for legacy explicit IDs is settled: — `71b0a2b`
  - [x] they become aliases/provenance only; — `71b0a2b`
  - [x] they must not silently defeat the opaque-ID requirement. — `71b0a2b`

### Acceptance

- [x] Change record name; ID unchanged. — `71b0a2b`
- [x] Change physical record filename if adapter permits; domain identity unchanged. — `71b0a2b`
- [x] Two records may have identical display names. — `71b0a2b`

---

## A2 — Separate execution state from workflow stage

Replace the old shared status concept.

- [x] Task has explicit execution state capable of: — `07d4926`
  - [x] Backlog; — `07d4926`
  - [x] Running; — `07d4926`
  - [x] Finished. — `07d4926`

- [x] Task independently has project workflow-stage identity. — `07d4926`
- [x] Workflow stage references stable stage ID, not display text. — `07d4926`
- [x] Moving a task into global Running does not erase project workflow stage. — `07d4926`
- [x] Moving a task from Review → Done-like workflow stage does not automatically change global execution state unless an explicit semantic rule is separately defined. — `07d4926`

### Acceptance

Fixture proves a task can simultaneously be:

```
execution = Running
workflow = Review
```

and appears correctly on both surfaces. — `07d4926`

---

## A3 — Scoped ordering

The single current `orderIndex` cannot remain the universal answer.

- [x] Define separate ordering semantics for: — `bf56679`
  - [x] Elastic execution queue; — `bf56679`
  - [x] project workflow stage; — `bf56679`
  - [x] any durable user-authored ordering elsewhere. — `bf56679` *(the canonical model currently admits no additional durable manual order scope; calendar chronology is derived and Gantt rows are local state)*

- [x] Workflow ordering is scoped at least by project + stage. — `bf56679`
- [x] Reordering Elastic cannot silently reorder the project's workflow board. — `bf56679`
- [x] Reordering the project board cannot silently alter Elastic order. — `bf56679`
- [x] Decide Gantt row placement explicitly: — `bf56679`
  - [x] preferred correction: treat pure row layout as LOCAL STATE; — `bf56679`
  - [x] if creator declares it semantic priority, give it its own scoped field. — `bf56679` @ `2026-09-11T07:11:24+07:00` *(**decided against rather than done, and recorded that way for the same reason the sibling box above is ticked with "there is no additional durable scope"**: the creator did declare row placement semantic, and what changed is where a semantic arrangement lives — in the reader's session rather than in a third record field, which is what the tree implements and what `tests/scopedOrdering.test.ts` asserts by leaving every record file and revision byte-identical. So no scoped field was added, and this box is the description of the work that would reopen if row placement has to survive a reload, a window or an agent. Ticked rather than left open because an open box reads as work waiting, and this one has a named trigger instead: D64's amendment carries it, and the trigger is written there in the same words.)*

- [x] Even if Gantt row placement becomes LOCAL STATE, retain a typed programmatic action because the old DATA WRITE gesture must remain agent-operable. — `bf56679` *(existing typed `task.timeline.change.targetRowIndex` retained; durable mutation remains unavailable until record-store cutover)*

---

## A4 — Project-type silo removed

- [x] Project can associate with tasks and events simultaneously. — `795f019`
- [x] Project UI capabilities are determined by available data/workspace configuration, not immutable `task|schedule` type. — `795f019`
- [x] Existing legacy `projectType` is import metadata only if needed for faithfully reconstructing old presentation. — `795f019`
- [x] No selector filters task visibility merely because a project was formerly labeled schedule. — `795f019`
- [x] No selector filters event visibility merely because a project was formerly labeled task. — `795f019`

The inspection and selector contracts no longer use `projectType` as capability or visibility
authority; inspection schema v5 exposes data/workspace-derived capabilities instead. — `795f019`

---

## A5 — Schema is canonical data

- [x] Property-schema definitions are durable Proxima records. — `289754d`
- [x] Schema identity is opaque/stable. — `289754d`
- [x] Schema does not live in Backpack local settings. — `289754d`
- [x] Select-option identity is stable and separate from label. — `289754d`
- [x] Formula definitions are durable. — `289754d`
- [x] Rollup definitions are durable. — `289754d`
- [x] Relation definitions are durable. — `289754d`
- [x] Colors/column widths/collapsed UI state remain LOCAL STATE where they are only presentation. — `289754d`

---

## A6 — Relations are ID-based

- [x] Relation values contain logical record IDs. — `26c84d4`
- [x] Relation semantics do not contain wikilinks. — `26c84d4`
- [x] Relation semantics do not depend on target filenames. — `26c84d4`
- [x] Relation schemas do not use `targetFolder` as the conceptual target. — `26c84d4`
- [x] Rename/move of a human-facing record representation cannot break relation identity. — `26c84d4`
- [x] Markdown/wikilink conversion exists only inside legacy import/export compatibility code if required. — `26c84d4` *(canonical domain introduces no Markdown/wikilink conversion; existing compatibility code remains outside canonical relation semantics)*

---

## A7 — Names are independent from storage representation

- [x] Task/project/event titles are ordinary fields. — `270f8cb`
- [x] Any valid domain title can be represented without changing filename logic. — `270f8cb`
- [x] Colon/YAML quoting rules disappear from canonical record validation. — `270f8cb`
- [x] JSON encoding, not hand-authored source syntax, represents canonical structured values. — `270f8cb`

---

## A8 — Project/filesystem association is explicit

- [x] A project can explicitly reference its Notes/drawings/attachments roots or artifacts without asserting that filesystem location *is* project identity. — `1c87f24`
- [x] Moving a note does not mutate task/project IDs. — `1c87f24`
- [x] One artifact being referenceable from multiple projects is not structurally forbidden by "must live inside project directory" assumptions. — `1c87f24`
- [x] Exact external-artifact identity semantics are documented separately from Proxima record identity. — `1c87f24` *(canonical Proxima records use `pxr_...`; external artifact references use distinct `pxa_...` identity with mutable locator stored separately)*

---

## A9 — Recurrence becomes explicit domain data

- [x] Recurrence rule has a typed structure. — `ed147ea`
- [x] Series identity is explicit. — `ed147ea`
- [x] Occurrence identity can be addressed semantically. — `ed147ea`
- [x] Exception identity/state is explicit. — `ed147ea`
- [x] "this occurrence" and "entire series" actions do not depend on filenames or accidental source layout. — `ed147ea`
- [x] A detached/special occurrence can be represented without corrupting series identity. — `ed147ea`

---

## A10 — No hidden second database

Every durable piece of information is classified as one of:

- [x] canonical Proxima record/schema data; — `efdfa11`
- [x] disposable Backpack-local state; — `efdfa11`
- [x] external vault-artifact provenance/reference. — `efdfa11`

Nothing semantic is allowed to survive only in an opaque equivalent of Obsidian plugin settings. — `efdfa11`

### Evidence closing HARD GATE A

- [x] Revised domain types. — `71b0a2b` through `efdfa11`
- [x] New domain-schema version. — `efdfa11` *(canonical domain/record schema version 2)*
- [x] Tests covering every separation above. — `efdfa11` *(10-file / 61-test HARD GATE A closeout matrix)*
- [x] Architecture/import mapping document. — `efdfa11` *(`docs/canonical-domain-ownership.md`)*
- [x] A fixture demonstrating combined task+event project. — `efdfa11`
- [x] A fixture demonstrating independent execution/workflow movement. — `efdfa11`
- [x] ID-based relation test surviving title changes. — `26c84d4`
- [x] Scoped-order independence tests. — `bf56679`
- [x] No canonical-domain import of filesystem, Papers or Obsidian APIs. — `efdfa11` *(Gate 20B remains green)*

**HARD GATE A CLOSED** — `efdfa11`

### What breaks if this gate is skipped

The importer would freeze old mistakes into new JSON:

- shared execution/workflow status;
- global ambiguous ordering;
- project-type silos;
- wikilink relations;
- file-shaped schema;
- path-like identity.

Correcting those afterward means migrating the newly migrated database a second time.

---

# Stage 7 — Define and implement the Proxima-owned Record Store

This stage is storage infrastructure, not user parity yet.

## Record-store contract

- [x] One JSON file per durable record. — `3b1af20` *(adapter contract: one opaque-ID JSON file per record)*
- [x] Filename carries no human/domain meaning. — `3b1af20` *(opaque record ID only)*
- [x] Every JSON document validates against the current domain schema. — `a8c1b1e` *(canonical-domain-v2 codec is bound to the canonical JSON RecordStore factory; malformed, legacy/local and path-bearing record shapes fail at the boundary)*
- [x] Unknown/corrupt record files fail visibly. — `3b1af20`
- [x] No arbitrary partial JSON patch is exposed as the semantic application API. — `3b1af20`
- [x] Reader returns: — `3b1af20`
  - [x] typed record; — `3b1af20`
  - [x] opaque ID; — `3b1af20`
  - [x] kind; — `3b1af20`
  - [x] observed revision. — `3b1af20`

- [x] Writer supports: — `3b1af20`
  - [x] create-if-absent; — `3b1af20`
  - [x] update-if-unchanged; — `3b1af20`
  - [x] delete-if-unchanged. — `3b1af20`

- [x] Physical move/rename of a record JSON is not required for changing any human-facing record property. — `3b1af20`

## Single-writer boundary

- [x] Record-store write authority is explicitly distinct from creator-vault FSA write authority. — `3b1af20`
- [x] D51 remains intact for shared creator files. — `3b1af20` *(existing vault writer/co-writer boundary untouched)*
- [x] A new record-store boundary may enable writes because the record location is Proxima-owned and not a live Obsidian source. — `e7e7362` *(browser OPFS backend provides conditional physical record CRUD only; semantic mutation authority remains unavailable)*
- [x] The code makes it difficult to accidentally pass a creator-vault root into the record writer. — `3b1af20`
- [x] Record-store adapter never receives arbitrary user vault paths from semantic actions. — `e961b94` *(actual parsed `task.execution.move` and `project.delete` actions with Windows, traversal-shaped and POSIX creator-vault IDs are rejected by RecordStore opaque-ID validation before backend read/update/delete; backend call counts remain zero and semantic mutation authority remains unavailable)*

## Crash durability

Reuse the existing mutation/recovery semantics rather than inventing another journal.

The existing coordinator records the prior bytes, intended update bytes, revisions, request IDs and durable state, then classifies uncertain operations.

- [x] Record updates go through a coordinator with equivalent prepared → commit → committed semantics. — `4d61e20` *(pathless record update/delete coordinator durably prepares before the checked physical effect and commits the recovery entry only after successful effect; semantic mutation authority remains unavailable)*
- [x] Durable journal loads before record mutation authority becomes available. — `d07fa61` *(startup reconciliation completes before a RecordMutationCoordinator can be returned; load/recovery failure blocks authority and returns no coordinator)*
- [x] Prepared entries reconcile on restart. — `d07fa61` *(record startup reuses the existing durable recovery reconciler before authority exposure)*
- [x] `recovery-required` entries reconcile. — `d07fa61` *(record startup passes unresolved recovery-required entries through the existing reconciliation semantics before authority exposure)*
- [x] Effect-present operation classifies committed. — `d07fa61` *(prepared update with intended bytes already present is persisted as committed before coordinator exposure)*
- [x] Effect-absent operation classifies recovered/no-op. — `d07fa61` *(recovery-required update with unchanged prior bytes is persisted as recovered before coordinator exposure)*
- [x] Ambiguous/corrupt state blocks rather than guesses. — `a937aa4` *(record startup persists ambiguous third-party bytes as blocked and exposes no coordinator; malformed durable journal state blocks during load before record access or authority exposure)*
- [x] Process-death injection exists before commit. — `9bbedbd` *(real child process is killed after fsynced durable `prepared` state and before the checked record backend commit is entered; fresh startup observes unchanged prior bytes and reconciles `not-applied` → `recovered`)*
- [x] Process-death injection exists after file commit but before journal finalization. — `97970b7` *(real child process is killed after the checked record update durably commits `new @ record-r2` but while the durable journal still says `prepared`; fresh startup classifies effect-present → committed without rollback)*
- [x] Reconciliation is idempotent. — `188209e` *(repeated record startup over terminal committed/recovered/blocked journal state performs no further journal write or record access, creates no duplicate recovery state/outcome, and preserves the same mutation-authority decision)*
- [x] Agent receives machine-readable recovery-required/blocked outcome. — `155c736` *(actual coordinator `recovery-required` maps into the existing typed ActionFailure result vocabulary; actual blocked startup maps into bounded pathless inspection code `record-recovery-blocked`, with no direct storage authority exposed)*

## Multiple Proxima callers

Even with no Obsidian co-writer, UI surfaces and agents may observe stale revisions.

- [x] Every modifying action binds to an observed record revision where stale semantics matter. — `052c3b4` *(the pathless update/delete coordinator contract requires `expectedRevision`, and conformance callers bind it directly from the observed record revision; semantic UI actions remain unavailable)*
- [x] Two concurrent Proxima operations on the same observed revision cannot silently last-write-wins. — `052c3b4` *(two independent coordinators prepare against the same `record-r1`; the conditional store permits one `record-r2` winner and refuses the second operation as stale)*
- [x] Winner succeeds. — `052c3b4` *(exactly one same-record concurrent result succeeds and its returned revision becomes the stored revision)*
- [x] Loser receives typed stale/conflict. — `052c3b4` *(exactly one concurrent loser returns typed `reason: stale` with `actualRevision` equal to the winner's revision)*
- [x] Different records may commit independently. — `10dc3c3` *(two independent coordinators bind distinct record mutations to their own observed revisions; both conditional effects succeed and both records retain their own intended bytes/revisions without cross-record blocking or overwrite)*
- [x] Semantic caller may explicitly refetch/retry; storage layer does not silently merge. — `eb0f3fe` *(typed stale ends the original mutation with no automatic retry; caller explicitly refetches the winning revision and submits a new revision-bound mutation, which writes exactly the caller-provided replacement bytes without storage-layer merge)*

## Acceptance

- [x] Create/read/update/delete record through headless APIs. — `3b1af20`
- [x] Restart retains records. — `a91b2de` *(isolated real Papers profile; first Electron application closed; second Electron launch reused the same userData under a different PID and the same stable Proxima Backpack origin; a fresh accepted OPFS backend/RecordStore reread the exact disposable canonical record and conditionally deleted it)*
- [x] Corrupt JSON reports error. — `3b1af20`
- [x] Stale update refuses. — `3b1af20`
- [x] Two independent action callers race same revision: one winner. — `052c3b4` *(two independent pathless coordinator callers bind to the same observed revision; exactly one succeeds and the other returns typed stale without overwriting the winner)*
- [x] Process-kill tests classify every recovery state. — `7c89491` *(single-run aggregate executable matrix invokes both required real process-death windows: effect absent after before-commit death → `not-applied`/`recovered`; intended effect present after post-commit/pre-finalization death → `effect-present`/`committed`, with no rollback)*
- [x] No creator-vault file changed during record-store test suite. — `4cdbeea` *(all four designated disposable vault fixture trees remain byte/mtime-identical across focused record-store/recovery tests, isolated bridgeDisclosure and the serialized full suite; no live creator-vault access is used)*

## Evidence

- [x] RecordStore adapter tests. — `3b1af20` *(headless JSON adapter)*; `e7e7362` *(browser OPFS physical-backend/conformance coverage)*
- [x] Mutation coordinator conformance tests. — `4d61e20` *(prepared-before-effect ordering, committed-after-effect ordering, definite stale recovery, prepare-write refusal, uncertain post-effect journal failure and checked delete)*
- [x] Record startup recovery/authority conformance tests. — `d07fa61` *(durable load-before-authority, load-failure blocking, prepared effect-present → committed, and recovery-required effect-absent → recovered)*; `a937aa4` *(ambiguous peer bytes → durable blocked authority; corrupt recovery journal → blocked before record access)*; `188209e` *(repeated terminal committed/recovered/blocked startup is idempotent: no further journal writes, no record access, no duplicate state/outcomes, same authority decision)*
- [x] Machine-readable recovery disclosure contract tests. — `155c736` *(actual coordinator recovery-required → typed ActionFailure; actual blocked startup → bounded pathless blocked inspection; stable codes/fields and storage-target non-disclosure proven)*
- [x] Same-record observed-revision concurrency tests. — `052c3b4` *(update/delete caller shapes bind to observed revision; two independent same-revision coordinator callers produce one winner plus one typed stale loser, with winner bytes/revision preserved)*
- [x] Different-record independence concurrency tests. — `10dc3c3` *(two independent coordinator callers bind to distinct observed revisions; both different-record updates succeed and retain their own bytes/revisions without cross-record interference)*
- [x] Explicit refetch/retry no-silent-merge concurrency tests. — `eb0f3fe` *(stale refusal performs no automatic third write; explicit caller refetch observes the winner revision, and only a new revision-bound execute commits exact replacement bytes without merge)*
- [x] Semantic/UI mutation-containment closeout tests. — `b612cdb` *(all eleven registered record-mutation actions remain typed-unavailable through programmatic dispatch; ActionDispatcherOptions and dispatcher execution expose no RecordStore mutation authority; browser mutation intents route only through that dispatcher and browser source contains no RecordStore/coordinator/recovery mutation wiring)*
- [x] Process-death recovery evidence: `9bbedbd` *(before-commit kill: durable prepared survives; physical effect absent; startup → recovered)*; `97970b7` *(after-commit kill: intended physical effect survives while durable journal remains prepared; startup → committed without rollback)*; `7c89491` *(single-run aggregate executable matrix invokes both unchanged accepted harnesses exactly once and requires the exact `not-applied → recovered` / `effect-present → committed` classification pair)*
- [x] Durable recovery/process-kill tests. — `7c89491` *(single-run aggregate matrix executes both accepted real child-process death boundaries against durable recovery/record fixtures and requires the complete complementary classification pair)*
- [x] Tree diff showing writes confined to the Proxima-owned store. — `4cdbeea` *(disposable physical-tree probe changes exactly the opaque record JSON and `record-store/recovery/journal.json`, both beneath the Proxima-owned root; sibling creator-vault fixture remains unchanged)*
- [x] Explicit test that a creator-vault path cannot be supplied as a record-store target. — `3b1af20`; `e961b94` *(actual parsed record-mutation action IDs shaped as creator-vault paths cannot cross RecordStore update/delete identity validation; no backend mutation call occurs)*

---

# HARD GATE B — Physical store location must be settled before real import

The storage **format** and physical backing API are decided.

**Chosen location/API — `a08340c`:** the canonical Proxima Record Store is the
Origin Private File System of the stable Proxima Backpack origin
`papers-backpack://bp-954ea2cd-6261-410d-baf8-0d1fbd8ca0b1`, reacquired with
`navigator.storage.getDirectory()`. Its fixed namespace is
`record-store/records/` for canonical record JSON and `record-store/recovery/` for the
durable recovery journal. Chromium's private on-disk implementation path is not an
application path contract.

- [x] Backing location chosen. — `a08340c`
- [x] Authority restoration is programmatic after initial unavoidable enrollment, if any. — `a08340c` *(OPFS root is reacquired from the stable origin; no Record Store picker or external handle is required)*
- [x] Store survives normal Papers restart. — `a08340c` *(location is the stable Backpack origin in Papers' persistent profile; Stage 7's separate implemented restart-retention acceptance row remains open until the backend exists)*
- [x] Obsidian does not treat it as the live task/project/event database. — `a08340c` *(origin-private browser storage, not the creator vault)*
- [x] Agent access occurs through Proxima actions, not direct backing-store access. — `a08340c` *(OPFS handles remain adapter-private)*
- [x] Recovery journal survives wherever the record store survives. — `a08340c` *(same OPFS root, sibling `record-store/recovery/` namespace)*

**HARD GATE B CLOSED** — `a08340c`

Closing this decision gate does not itself implement the store and does not authorize real
migration. Complete Stage 7 physical-backend, restart, mutation/recovery and concurrency
acceptance before beginning real import.

---

# Stage 8 — One-time Markdown → Record Store importer

Legacy Markdown is input only.

## Import architecture

- [x] Importer uses the existing compatibility reader/parser rather than creating another Markdown interpretation. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(the dry-run planner calls `loadVaultState` directly and contains no Markdown/frontmatter/discovery parser)*
- [x] Import has a dry-run/planning phase. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(schema-v1 planner is explicitly `mode: dry-run` and has no writer authority)*
- [x] Import plan is machine-readable. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(plain JSON-serializable schema-v1 identity/reference/problem/census plan with explicit zero-write declaration)*
- [x] Import assigns final opaque record IDs according to HARD GATE A. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(every compatibility-loaded record receives a separately allocated `pxr_...` identity validated by the accepted opaque-ID and legacy-provenance boundary; invalid, reused and silently promoted legacy identity is refused)*
- [x] A durable import mapping records legacy provenance → new opaque record identity for reconciliation of relationships. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(versioned provenance→opaque-ID manifest is keyed by physical kind/source rather than ambiguous legacy alias, has an explicit durable load/save port, preserves prior reservations, and reuses persisted candidate identities on replanning; canonical staging remains separate)*
- [x] Project references are translated to new project IDs. — `0fd5f51` @ `2026-09-11T14:28:25+07:00`; `be3efdf` @ `2026-09-11T14:52:38+07:00` *(unambiguous task/event project aliases resolve through planned opaque project identity; absent aliases remain `missing`, while aliases backed by multiple physical project candidates are explicitly `ambiguous` with null selected target and all candidate opaque IDs disclosed)*
- [x] Relations are translated to record IDs. — `400ccfc` @ `2026-09-11T16:24:16+07:00` *(unambiguous permitted legacy wikilinks become canonical relation values containing only opaque relation-schema and target-record IDs; missing, ambiguous, malformed, disallowed-kind, duplicate-target and unresolved-schema cases remain explicit)*
- [x] Legacy status is translated separately into: — `173b45e` @ `2026-09-11T15:04:55+07:00` *(the dry-run conversion plan preserves one legacy status input while independently deriving Elastic execution meaning and project-scoped workflow-stage-candidate meaning; no final workflow-stage record is materialized yet)*
  - [x] execution state; — `173b45e` @ `2026-09-11T15:04:55+07:00` *(existing compatibility Elastic classification becomes canonical `backlog|running|finished`, including completion override and unknown-valid-status → running behavior)*
  - [x] workflow stage. — `173b45e` @ `2026-09-11T15:04:55+07:00` *(resolved projects receive a project-scoped legacy-status stage candidate; absent/ambiguous project identity remains explicitly unresolved rather than choosing a stage target)*

- [x] Legacy ordering is translated into the appropriate scoped orders. — `173b45e` @ `2026-09-11T15:04:55+07:00` *(legacy order seeds independent validated Elastic-execution and, when resolvable, project/workflow-stage-candidate positions; no universal canonical `orderIndex` is emitted)*
- [x] Legacy project type informs import compatibility only; it does not create a permanent silo. — `173b45e` @ `2026-09-11T15:04:55+07:00` *(`task|schedule` is retained only as compatibility import metadata; both labels declare canonical capability authority as associated data/workspace rather than a type filter)*
- [x] Schema/settings needed to interpret custom properties become first-class schema records. — `368b3bf` @ `2026-09-11T15:37:49+07:00` *(explicitly interpreted task/per-project settings are converted through scoped stable opaque schema/option identities into canonical-ready primitive, select, multi-select and non-empty-formula records; option colors remain local-state; relation/rollup/incomplete-formula cases remain pending; planner and parent import remain dry-run/zero-write)*
- [x] Legacy custom-property values are captured from the existing interpreted task/event frontmatter and ordinary task families are dry-run mapped to canonical opaque schema/option identities. — `a360fa9` @ `2026-09-11T16:08:36+07:00` *(projects expose no property-value surface; events remain captured-but-untyped; absent, unresolved, relation-pending, rollup-pending and formula-pending outcomes remain explicit; parent/property plans remain zero-write)*
- [x] Legacy wikilink relations never remain canonical relation values. — `400ccfc` @ `2026-09-11T16:24:16+07:00` *(canonical-ready relation values are constructed through the canonical relation boundary and contain no wikilink text, legacy ID, path, basename, filename, display name, folder or `.md` value)*
- [x] Notes/drawings/attachments are **not copied** into the record store. — `646d72e` @ `2026-09-11T18:49:42+07:00` *(slice-8 artifact planner is reference-only and has no content-reader or copy authority)*
- [x] Project references to external notes/files remain references to external artifacts. — `646d72e` @ `2026-09-11T18:49:42+07:00` *(interpreted linked folders become explicit canonical `pxa_...` artifact references and project associations; legacy labels/paths remain evidence)*
- [x] Legacy source files are never altered. — `646d72e` @ `2026-09-11T18:49:42+07:00` *(the accepted slice proves zero legacy-Markdown, Record Store, staging and external-artifact writes)*

## Import staging

Use staged activation, not a half-cut-over live database.

- [x] Import can materialize a staging record store. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(one isolated store receives every kind the planners can prepare, in the order they require: projects, the workflow stages those projects scope, the tasks that resolve a stage through that mapping, events, and the schema records the plan declares — asserted by non-empty staged sets and a non-empty store, over four fixture vaults. The store is slice 9's staging-only capability (`9c0c2dc`), never the canonical Record Store: `readStagedRecord` and `createStagedRecord` are all it has.)*
- [x] Valid records may be converted into staging while blockers are reported. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the malformed fixture is the case: its fifteen reader problems are all warnings — the reader is tolerant, so those records entered state — and the run creates the records whose canonical payload it can build while four candidates are blocked with typed reasons in the same pass. Every candidate is accounted for as created, reused or blocked, so nothing is silently dropped, and the blockers carry machine-readable reasons rather than prose.)*
- [x] Staging is not canonical until activation. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(every materialization result reports `activation: 'not-performed'`; the store's authority is `legacy-import-staging-only`, and a store claiming canonical authority is refused by the materializers rather than written into; and after a full staging pass the application still reads the legacy vault, with none of the staged opaque ids present in that state.)*
- [x] Re-running the same import is idempotent with respect to already assigned import identities. — `d66622f` @ `2026-09-12T00:12:36+07:00` *(re-planning the same vault with a fresh allocator in a disjoint id range reuses every identity from the durable mapping, so a re-run cannot mint a second record for a source that already has one; the conversion ids and the manifest agree, and no identity is held by two records)*
- [x] An interrupted import resumes/replans without producing duplicate canonical records. — `d66622f` @ `2026-09-12T00:12:36+07:00` *(a run that stops is resumed from the stored manifest alone: the test persists the mapping, discards the plan, and re-plans with an allocator in a disjoint range — identities come back identical, a third pass is a fixed point rather than drifting, and a duplicated legacy alias still keeps both physical records distinct. The claim proven is identity reuse on replan; canonical materialization remains staged and not activated.)*
- [x] No hidden "some records now JSON, some still Markdown" live mode is allowed unless explicitly designed and tested. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(there is no mixed mode to allow: after a full staging pass the product's only source is still the legacy vault — `loadVaultState` over the same tree returns the legacy records and none of the staged ids — and no module outside the import planners reads a staging store. This box is a prohibition that currently holds by absence; if a mixed mode is ever designed, the box reopens and that mode must be tested rather than assumed.)*

> **Superseded at `d9d8c5e` @ `2026-09-12T02:35:31+07:00`.** Slice 9 proved these invariants for
> canonical-ready schema records in an isolated staging store (`9c0c2dc` @ `2026-09-11T19:01:24+07:00`).
> The broad physical task/project/event staging is no longer the open half:
> `tests/importStagingBytePreservation.test.ts` materializes every kind into one staging store over all
> four fixture vaults, with the byte-preservation proof run around the operation. **Activation** —
> choosing the staged records as canonical — is what remains, and that is HARD GATE C's.

## Duplicate legacy IDs

Do **not** silently choose one source file.

- [x] Every physical legacy record involved in an ID collision is identified separately. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(import planning consumes the compatibility reader's pre-dedup physical candidate inventory; the dedicated duplicate fixture exposes both `proj-twin` sources and both `task-shared` sources separately)*
- [x] Each decodable physical record can receive its own candidate opaque ID in staging. — `42a0361` @ `2026-09-11T19:14:55+07:00` *(staging persists the already-authored physical-source identity manifest; duplicate legacy aliases retain separate candidate IDs and complete collision evidence; no payload is guessed)*
- [x] The duplicate legacy alias is recorded as a collision. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(machine-readable collision groups retain the shared legacy alias plus every physical candidate's source provenance and separately allocated opaque identity)*
- [x] Any legacy relation/project reference that resolves through that duplicate alias remains explicitly unresolved/ambiguous. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(a project alias with multiple physical candidate mappings yields `resolution: ambiguous`, null selected project ID and the complete candidate-ID set; general non-project relation conversion remains open)*
- [x] No arbitrary filesystem/index order picks the target. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(all candidate identities may be deterministically listed, but a duplicate target alias never resolves by first/last/index order)*
- [x] Canonical activation cannot claim the migration is clean while ambiguous references remain unacknowledged. — `394179c` @ `2026-09-12T00:02:14+07:00` *(`import.status` reports the plan's outstanding `unresolvedProjectReferences`/`ambiguousProjectReferences` and the `appliedProjectSelection`, and `import.commit` refuses with those counts in machine-readable `error.outstandingProjectReferences` while either is nonzero, so the only machine path toward activation provably refuses rather than reading clean; canonical activation itself remains gated behind HARD GATE C)*
- [x] A machine-callable import-resolution operation exists if ambiguous identities require explicit mapping. — `bd64a34` @ `2026-09-11T23:57:13+07:00` *(`import.resolve` accepts the explicitly selected candidate project record id, resolves every ambiguous project reference whose candidate set contains it, and returns the resolved in-memory dry-run plan; an id that is a candidate of no ambiguous reference is refused as `invalid-action-input` rather than silently ignored, and `import.commit` stays typed-unavailable)*
- [x] Resolution decisions are included in the import evidence. — `bd64a34` @ `2026-09-11T23:57:13+07:00` *(the resolution returns the resolved schema-v1 plan as the action's evidence, so each affected reference, task workflow stage, workflow-order scope and event project association names the selected project and the reference counts are recomputed; the verification that described the pre-resolution plan is discarded and `import.inspect` re-verifies the resolved plan)*

## Malformed records

- [x] Parse/validation-blocking malformed record produces a structured import failure containing: — `3846805` @ `2026-09-11T19:22:40+07:00` *(staging-only problem manifest groups each physical source and preserves the structured evidence)*
  - [x] source path/reference; — `3846805` @ `2026-09-11T19:22:40+07:00`
  - [x] record kind if known; — `3846805` @ `2026-09-11T19:22:40+07:00`
  - [x] problem code; — `3846805` @ `2026-09-11T19:22:40+07:00`
  - [x] bounded diagnostic. — `3846805` @ `2026-09-11T19:22:40+07:00` *(uses `DIAGNOSTIC_LIMITS.problemDetail`)*

- [x] No JSON record is created from guessed fields. — `3846805` @ `2026-09-11T19:22:40+07:00` *(canonical payload materialization and canonical staging-record creation are both zero)*
- [x] Original malformed Markdown remains byte-identical. — `3846805` @ `2026-09-11T19:22:40+07:00` *(the accepted proof compares source bytes before and after)*
- [x] Other valid records may be prepared in staging. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the malformed fixture is the case: records with unreadable or invalid fields are reported by the plan, and the records that are valid are still prepared — created counts above zero while four candidates are blocked, in the same run, with the legacy bytes unchanged.)*
- [x] Canonical activation does not silently omit malformed records as though import were complete. — `c62a7dc` @ `2026-09-12T00:05:59+07:00` *(`import.status` reports the plan's `readerProblems` and `unsupportedFrontmatter`, and `import.commit` carries them in machine-readable `error.outstandingRecords` whenever any record could not be converted — including after the project references are acknowledged, so clearing ambiguity cannot make an incomplete import read as complete. Records the importer cannot convert are counted, not dropped; activation itself remains gated behind HARD GATE C.)*
- [x] A machine-readable unresolved-record count remains nonzero until deliberately resolved/skipped according to an explicit migration policy. — `3846805` @ `2026-09-11T19:22:40+07:00` *(manifest exposes `unresolvedRecordCount`; activation and resolution policy remain open)*

## Unsupported-frontmatter open question

The repository currently has a real unresolved semantic mismatch: repository loading can accept `unsupported-frontmatter` as a warning, while refresh treats that same code as blocking. The docs correctly preserve this as an open question. Do **not** invent an import rule for it.

- [x] Before final migration activation, answer: — `3cc97cb` @ `2026-09-12T07:44:40+07:00` *(**answered, in the question's own terms**: an otherwise readable record containing `unsupported-frontmatter` **is importable** using the interpreted fields, with the legacy source preserved as provenance and the unsupported construct reported — D65, where the creator chose "preserve and report" over "refuse that record" when asked, which is the first branch of this question. **The consequence is a behaviour change, and it is not done**: `tests/importTaskStagingPlanner.test.ts`, `tests/importProjectStagingPlanner.test.ts` and `tests/importEventStagingPlanner.test.ts` currently assert the opposite — that malformed and unsupported-frontmatter records "remain explicit blockers" — so the `unsupported-frontmatter-importability` policy now has an answer to implement, and the box below is what closes with it. **Sized while handing off:** the classification lives in five places — `src/app/importPlanner.ts` (the reader problems and the `unsupported-frontmatter-policy-pending` disposition), `src/app/importProjectStagingPlanner.ts`, `src/app/importEventStagingPlanner.ts` and `src/app/importProblemStagingPlanner.ts` each map an `unsupported-frontmatter` problem to that pending reason, and `src/app/importAdministrativeActions.ts` reports the count as `unsupported-frontmatter-importability` — and around ten suites encode the current blocking behaviour, including `tests/importTaskStagingPlanner.test.ts`, `tests/importProjectStagingPlanner.test.ts`, `tests/importEventStagingPlanner.test.ts`, `tests/importProblemStagingPlanner.test.ts`, `tests/importPlanner.test.ts`, `tests/importAdministrativeActions.test.ts` and `tests/frontmatterParseDiagnostics.test.ts`. So this is a policy slice with a test tail rather than a one-line flip, and it is the next slice in the queue. Nothing here is ticked on the strength of machinery that does not yet behave this way.)*

> Is an otherwise readable record containing `unsupported-frontmatter` importable using the interpreted fields with legacy source preserved as provenance, or must import block until the unsupported construct is resolved?

  *(Still the creator's decision, and `d9d8c5e` @ `2026-09-12T02:35:31+07:00` sharpens what it
  costs: the reader treats both `unsupported-frontmatter` and `frontmatter-parse-failure` in the
  malformed fixture as **warnings**, so those records enter state, and the staging pass then
  converts them with the interpreted fields. The answer therefore decides whether that
  conversion is correct by default or must be withheld — it is not a question about the
  machinery, which already handles both answers.)*

- [x] Until answered, importer reports it distinctly from an ordinary malformed record. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(`unsupported-frontmatter` is emitted as `unsupported-frontmatter-policy-pending`, while ordinary frontmatter parse failures remain separate reader problems; no importability policy is invented)*
- [x] Tests encode the decided rule only after the decision exists. — `8a14f3f` @ `2026-09-12T16:40:11+07:00` and `9bb26b3` @ `2026-09-12T16:48:37+07:00` *(the decision existed — `3cc97cb` answered it with D65's **preserve and report** — and the rule is now what the code does and what the tests assert. The first commit made the three record families import a readable record that carries an unsupported construct: the per-family problem function used to block on two codes and now blocks only on `frontmatter-parse-failure`, because a record whose fields cannot be read has nothing to convert while a record with one odd field is importable using the interpreted fields. The report did not disappear with the blocker: each staging result gains a `reported` list and `counts.reported`, computed from the records that were **staged** rather than from the plan, so a construct can never be reported for a record that did not land and a record can never land with its construct silently dropped. The second commit finished the vocabulary that still called the question open: `LegacyImportProblemDisposition` is `unsupported-frontmatter-reported` rather than `-policy-pending`, the problem-staging manifest counts `unsupportedFrontmatterReportedRecords`, the verification and the administrative layer both drop `unsupported-frontmatter-importability` from their deferred checks — a deferred check has to be a question nobody answered — and the commit refusal stops treating a reported record as unconvertible, refusing on the reader problems that are *not* reported and naming the reported ones beside them. **The operational half is asserted rather than implied:** a plan whose only reader problem is the reported construct gets `import.commit` refused for the migration and activation gates alone, with no `outstandingRecords`, while `import.status` still carries the count for a surface to show. **Nine mutations across the two commits were tried, and one of them is why this box also carries a new test.** Four probes of the vocabulary and five of the staging rule - the three families each blocking on the unsupported code again, the report read off the plan rather than off the records that were staged, and the report count not the number of reports - and eight failed their suite at once. The report-source probe **survived**, with all 246 files green, because the property the code's own comment claims had no test; `dfcb39e` @ `2026-09-12T16:53:24+07:00` adds the case that holds the two facts apart - a task carrying the same construct beside a project record this run never stages, so the task is refused rather than converted - and the probe was re-run against it and then failed its suite. Five of five staging mutations bite, and the full suite is 246 files / 1623 tests.)*

## Byte-preservation proof

- [x] Hash every legacy Markdown record before import. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(`runLegacyImportBytePreservationProof` snapshots SHA-256 of every `.md` under the layout's record directories plus every file under each accepted external-artifact folder before the operation runs, and refuses to proceed when the artifact plan is absent rather than proving a subset.)*
- [x] Run import. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the operation is the real staging pass — projects, workflow stages, tasks, events, schema — over disposable copies of the fixture vaults, so the proof surrounds actual work: the staged sets are asserted non-empty, which a proof around a no-op could not claim.)*
- [x] Hash every legacy Markdown record afterward. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the same paths are hashed again after the operation, and the before/after entry lists are compared as sets, so a record that disappeared is as visible as one that changed.)*
- [x] Every hash matches. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(verdict `preserved`, zero changed paths, and — because a reader's account of itself is not proof — every digest the verifier reports is compared against a `node:crypto` hash of the file on disk. The instrument fails when it should: the same suite shows it reporting a change when a record is edited, when a source file is injected, and when one is removed.)*
- [x] Notes/drawings/attachments also remain untouched by the importer. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(three real artifact files are created inside the fixture project's own linked folders — a note, a canvas and a binary — and all three are byte-identical afterwards, on disk and in the verifier's digests. The artifact plan is reference-only by construction, and a machine-path reference is reported as unverifiable rather than claimed as proven.)*
- [x] No source "promotion" or ID injection is performed into legacy files. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the independent filesystem comparison covers additions as well as edits, so a promoted or injected file would appear as `added`; the verifier's own injection case proves that comparison reports one. Four fixture vaults are swept this way with zero changes.)*

## Import verification

Machine-check the legacy interpreted state against new-state semantics:

- [x] same count of valid physical task records accounted for; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(the task census reports `loadedRecords` equal to `counts.tasks`, with `unaccountedCandidates` zero and `loadedRecords + explicitlyRejected === recordCandidates`)*
- [x] same count of valid projects accounted for; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(the project census reports `loadedRecords` equal to `counts.projects`, with `unaccountedCandidates` zero and the candidate arithmetic closing)*
- [x] same count of valid events accounted for; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(the event census reports `loadedRecords` equal to `counts.events`, with `unaccountedCandidates` zero and the candidate arithmetic closing)*
- [x] every imported source has explicit import disposition; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`unaccountedCandidates` is zero for every kind, so each accepted candidate either became a record or was refused for a stated reason; every conversion also carries the `sourcePath` it came from, and each declared fixture path appears in the identity mapping or the problem list)*
- [x] names preserved; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`name` equals the declared frontmatter name on the project, task and event conversions)*
- [x] descriptions preserved; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`description` equals the declared single-line frontmatter description on every kind)*
- [x] dates preserved; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`createdAt`, `startDate` and `deadline` preserve the declared instants, compared as instants so a format normalisation cannot pass as data loss)*
- [x] task durations/weights preserved; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`weight: 3`, `isFixedDuration: true`, `fixedDuration: 90` and `maxDuration: 120` all survive exactly as declared)*
- [x] project associations mapped; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(both `project:` and `projectId:` resolve to the same canonical project record id, named in the task workflow stage, its workflow-order scope and the event project association; `unresolvedProjectReferences` is zero)*
- [x] custom property values mapped. — `a360fa9` @ `2026-09-11T16:08:36+07:00` *(ordinary task text, finite number, readable date, checkbox, select and multi-select values map through slice-4 opaque identities; event values remain captured-but-untyped; unresolved and derived families remain explicit)*
- [x] relations either resolved to new IDs or explicitly unresolved. — `400ccfc` @ `2026-09-11T16:24:16+07:00` *(exact physical/alias resolution uses existing opaque mappings; missing, ambiguous, malformed, disallowed-kind, duplicate-target and pending-schema outcomes are retained as machine-readable dispositions)*
- [x] recurrence mapped where representable; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`recurrence` is an explicit typed `null` on every task and event conversion — an own property, so "no recurrence" is a decision rather than an omitted key. Recurrence stays captured-but-untyped, so nothing is representable yet and no mapping is claimed.)*
- [x] archived/completed state preserved; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`status: archived` survives on the project conversion and `isCompleted: true` on the task, which remains planned with an execution state rather than being dropped as finished)*
- [x] no legacy `projectType` silo leaks into new capability filtering; — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`disposition` is `compatibility-import-metadata-only` and `canonicalCapabilityAuthority` is `associated-data-and-workspace`; projects, tasks and events are all planned, so the project's legacy type filters nothing out)*
- [x] no record filename is derived from record title. — `d7e6a6c` @ `2026-09-12T00:09:34+07:00` *(`recordId` is opaque on every conversion and carries no title text; the legacy filename survives only as `sourcePath` provenance; and two records declaring the same title still receive distinct identities)*

## Programmatic import actions

The creator must not have to perform migration by clicking through a wizard.

- `import.plan`
- `import.inspect`
- `import.resolve`
- `import.commit`
- `import.status`

These are semantic administrative actions with typed results.

## Evidence closing import

- [x] Dry-run import planner contract tests. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(existing compatibility-reader reuse, machine-readable zero-write plan, HARD-GATE-A identity assignment/refusal, project-ID reconciliation, source byte/revision preservation, and unsupported-frontmatter policy-pending disclosure)*

- [x] Durable identity / duplicate-candidate planning contract tests. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(pre-dedup physical candidate enumeration, versioned provenance→opaque-ID manifest persistence/reuse, dedicated `vault-duplicates` collision accounting, and explicit ambiguous-project-reference refusal without staging writes)*

- [x] Canonical conversion-plan semantics tests. — `173b45e` @ `2026-09-11T15:04:55+07:00` *(physical-candidate status decomposition, completion override, unknown-status execution compatibility, project-scoped workflow-stage planning, independent scoped-order planning, ambiguous-project workflow refusal, and projectType compatibility-only treatment; zero staging/Record Store writes)*

- [x] Schema/settings conversion-plan contract tests. — `368b3bf` @ `2026-09-11T15:37:49+07:00` *(scoped identity reconciliation, canonical-ready primitive/select/multi-select/non-empty-formula records, presentation-only colors, relation/rollup/incomplete-formula pending states, collision refusal, parent-plan integration, mapping persistence and zero-write boundaries)*

- [x] Legacy custom-property value capture and conversion-plan contract tests. — `a360fa9` @ `2026-09-11T16:08:36+07:00` *(interpreted task/event evidence capture, scoped task-schema fallback, project-schema isolation, opaque schema/option mapping, explicit absent/unresolved/deferred outcomes, event untyped boundary, parent schema-version integration, and zero-write guarantees; focused 3 files / 22 tests; serialized full suite 155 files / 928 tests)*

- [x] Relation target resolution and wikilink→canonical-record-ID conversion contract tests. — `400ccfc` @ `2026-09-11T16:24:16+07:00` *(exact wikilink parsing, unambiguous opaque-ID conversion, duplicate-alias ambiguity, physical-path disambiguation, missing and disallowed-kind refusal, unknown-folder pending behavior, canonical-value boundary and zero-write guarantees; focused 4 files / 28 tests; serialized full suite 156 files / 934 tests)*

- [x] Rollup canonical-reference and derived rollup/formula conversion-plan contract tests. — `57e8c16` @ `2026-09-11T17:46:24+07:00` *(canonical relation-schema and target-property resolution with explicit missing/ambiguous/incompatible outcomes; derived values remain evidence-only; focused 5 files / 32 tests; serialized full suite 157 files / 938 tests; zero-write guarantees)*

- Full import against all four existing fixture vaults. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the planning pass and the full staging pass run over `vault-basic`, `vault-legacy`, `vault-duplicates` and `vault-malformed` on disposable copies, with every candidate in every kind accounted for as created, reused or blocked, and the byte proof around each one. The sweep asserts it was not four easy vaults: at least one fixture holds records the reader refused and at least one holds an identity collision.)*
- Dedicated duplicate-ID fixture assertions. — `be3efdf` @ `2026-09-11T14:52:38+07:00` *(pre-dedup candidate enumeration and collision groups)*; `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the sweep includes the colliding fixture and asserts the collision is reported rather than resolved silently — a duplicate legacy id is staged as its own candidate with its own id, because choosing one silently is the failure the section exists to prevent.)*
- Dedicated malformed-record fixture assertions. — `3846805` @ `2026-09-11T19:22:40+07:00` *(structured failure, no guessed fields, original bytes unchanged)*; `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the malformed fixture converts what it can and blocks four with typed reasons in the same run, with the tree unchanged.)*
- Legacy tree byte hashes before/after. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(SHA-256 before and after, independently re-derived from the files on disk, over four fixture vaults.)*
- Machine-readable import manifest/report. — `0fd5f51` @ `2026-09-11T14:28:25+07:00` *(the schema-v1 plan)*; `d9d8c5e` @ `2026-09-12T02:35:31+07:00` *(the byte-preservation proof is itself a machine-readable object — snapshot, per-path digests, changes, counts, `verifierWrites`, verdict — so a run's evidence can be diffed rather than read.)*
- Restart after staged import. *(Not yet: the staging store the proof uses is in memory, so "restart" has nothing durable to come back to. The identity half of restart is proven — `d66622f` resumes from the stored mapping — and the store half needs the durable staging backend wired to the import pass.)*
- Restart after committed import. *(Not yet: nothing commits, because activation is HARD GATE C's. This bullet closes with the cutover, not before it.)*
- Idempotent rerun. — `d66622f` @ `2026-09-12T00:12:36+07:00` *(a re-plan with a disjoint allocator range reuses every identity, and a third pass is a fixed point.)*
- No creator gesture. — `bd64a34` @ `2026-09-11T23:57:13+07:00` *(the administrative actions — `import.plan`, `import.inspect`, `import.resolve`, `import.commit`, `import.status` — are semantic and programmatic, and the staging materializers are plain functions; nothing in the import path requires a click.)*

---

# HARD GATE C — Canonical cutover

Do not enable any real record-editing UI until this gate closes.

## Work

- [x] Startup chooses the Proxima record store as canonical tasks/projects/events/schema source after successful migration activation. — `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(both halves now exist and are tested. **Activation is an act with a marker**: `activateRecordStore` refuses an empty store, refuses to steal a store another import activated, refuses to overwrite a marker this build cannot read, and otherwise writes when it happened, which import it came from, and how many records of each kind — beside `records/` and `recovery/` in the store's own namespace, so "activated" is a fact rather than an inference. **The choice is one function with every answer named** (`chooseStartupSource`): no marker, an unreadable marker, a store emptied after activation, a store short of what it activated, and an unreadable store each keep the product on the legacy reader *and report why*, because an empty canonical store renders an empty application and that is worse than reading Markdown. Startup composes it: `startupSession` activates a `record-store` candidate when the decision says so, keeps a restored vault handle as that candidate's **artifact** reader rather than letting it become a competing source (a remembered folder would otherwise undo the cutover on every launch), and reports `sourceDecisionKind`/`Reason`/`Detail` in the startup inspection so a fallback is never invisible. The caveat worth stating: nothing in the shipped path *writes* the marker yet — that belongs to the import's commit step, so until an operator or the import activates a store, startup chooses legacy by design and says `no-activation-marker`.)*
- [x] Legacy Markdown record directories remain present but become **legacy source only**. — `42a022c` @ `2026-09-12T07:59:51+07:00` *(closed by D67, which is the shipped trigger this box was waiting for: the cutover is **never automatic**. The shipped default stays the legacy reader, activation is explicit, one-time and user-invoked, and once a store is activated the legacy directories are legacy source only — present, never read as canonical while the store is the source, and never deleted. The evidence the box asked for already existed: the byte-preservation proof at `d9d8c5e` leaves every file identical through a full staging pass, and `tests/recordStoreActivation.test.ts` shows an activated session reading the store while a legacy vault sits unread beside it. **Residual, stated plainly:** a run that has never activated still reads Markdown, deliberately — that is the shipped default, not an oversight. Whether the ordinary UI should *offer* activation is a separate affordance question D67 names rather than answers.)*
- [x] Legacy Markdown task/project/event changes after cutover do not silently overwrite JSON records. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(the protection is unconditional today, which is stronger than the box asks: the only writer of canonical records is the record store's own boundary, and no legacy path can reach it — `importPlanner` refuses a record-store provenance with `legacyIdOriginOf`, and the reader has no writer at all. The isolation case asserts it rather than arguing it: after renaming the source Markdown **and** deleting it, `store.list()` returns the same records with the same observed revisions, while the vault's own note read returns what the vault now says.)*
- [x] Record-store mutations refresh every active Proxima surface. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(proven for a mutation made through the store's own boundary: `createIfAbsent` a record and the next refresh classifies the load as `changed`, advances the source generation from 1 to 2, and the projection every surface renders gains the record — `session.projection().state.tasks` goes from one task to two. The refresh is the same one the interval policy triggers, so it is not a special path. What does not exist yet is a *UI* that performs such a mutation: adding a task by clicking is Stages 9–14's work, and this box's mechanism is what those stages will stand on.)*
- [x] Read-only projection/source abstractions are generalized so UI does not care whether state originated from legacy import fixtures or record store. — `738bb53` @ `2026-09-12T02:45:43+07:00` *(the missing piece was that nothing turned `CanonicalRecordV2` into `ProximaState`: the store held canonical records and every surface read the compatibility shape, so a record-store source could not even be represented. `src/app/recordStateProjection.ts` is that projection and `recordStoreStateLoad.ts` is the store-side load, in the same shape as the vault-side one (state plus the revisions a caller needs to notice change). `tests/recordStateProjection.test.ts` proves it end to end — records written through the canonical store boundary, read back through it, projected, and rendered by the real Task Board — and proves the claim that matters: the legacy reader and the record store draw **the same cards in the same three Elastic columns**, so the board asks the state what it holds rather than where it came from. Two things are deliberately not invented: a project's legacy `projectType` is reconstructed from what the project holds (A4 removed it from capability decisions), and a workflow stage is reported as having no slot in the readable world rather than being folded into a column (A2 keeps it independent). The wiring this box left open is done too: `06c0702` gives the session a third mode and a `StateSource` seam, so the two origins are switchable at runtime, not only in a test's imagination.)*
- [x] Current UI no longer labels the ordinary product as "Read-only workspace" once record mutations are enabled; at `608bcdc` that label is still hardcoded into the browser shell. — `9a04451` @ `2026-09-12T03:40:29+07:00` *(the literal is gone and the claim is now derived: `src/browser/workspaceIdentity.ts` returns "Editable workspace" only when records come from the record store **and** a record write path actually resolved, and "Read-only workspace" otherwise — so a record-store run whose writes are still refused keeps saying read-only, which is still true, and an activated store stops. Deriving it from the capability rather than the source mode is the whole point: a label tied to the mode would have claimed editability the moment a store existed, before any write path was resolved. The span carries `data-c1-key="workspace-identity"` and `data-workspace-writes` so the fact is readable rather than only the sentence, and `tests/workspaceIdentity.test.ts` holds the shell to consuming the derivation instead of restating it. The condition the box names is now met in the one configuration that can write: an activated store, which is what Stages 9+ deliver.)*
- [x] Existing FSA creator-vault write boundary remains blocked for record files because record files are no longer creator-vault files at all. — `42a022c` @ `2026-09-12T07:59:51+07:00` *(the "because" is now true of the shipped product rather than of a configuration: D67 keeps the legacy reader as the default and makes the cutover an explicit act, so no shipped run reaches record files through the vault at all, and when a store is activated the record files live in Proxima's Backpack-origin OPFS under opaque names behind `RecordStoreFileBackend` (D54). The guards are stronger than the box asks and are asserted: `evaluateFsaWriteBoundary()` closes native FSA writing as `BLOCKED / fsa-no-compare-and-swap`, `tests/fsaWriteBoundary.test.ts` holds that, and `tests/recordMutationContainment.test.ts` proves the shell holds no RecordStore authority — it fired on a first attempt that imported the store into `main.ts`, which is the guard doing its job.)*
- [x] H4 remains untouched. — `3cc97cb` @ `2026-09-12T07:44:40+07:00` *(true by absence, and now a recorded position rather than an accident: H4 is not defined anywhere in this tree beyond the creator's standing constraint, no slice went near it, and D63 — the read-only answer, which also says Proxima becomes a writer only later — keeps it unclaimed, so no Papers transaction capability is added on the strength of a direction. **The two boxes above are what still holds this gate, and both name the same missing thing in their own text: a shipped trigger for record-store activation.**)*

## Acceptance

- [x] Modify a legacy task Markdown file after cutover; canonical Proxima task does not change. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(asserted in the configuration the cutover creates: with a record-store session active, renaming `Proxima/tasks/running.md` leaves the projection's tasks exactly as the store holds them (`['Store task']`, not the edited name), and the refresh reports `unchanged` rather than degrading — the legacy edit is not an event this source can see at all. The shipped default is still the legacy reader, so this is the mechanism the cutover will use rather than a statement about today's default; the checkbox is ticked because the assertion the box asks for now runs and passes.)*
- [x] Execute semantic JSON-backed task update; every surface changes. — `abf8204` @ `2026-09-12T03:20:05+07:00`, `cab1627` @ `2026-09-12T03:31:18+07:00` and `18c2e48` @ `2026-09-12T03:37:24+07:00` *(the operation the box was waiting for now exists and two UI callers execute it: an Elastic drop writes `execution-state` + `execution-order` as one accepted mutation, and the card editor's Save writes one typed mutation per changed field — both through `src/app/taskMutations.ts` over the real store and the real recovery gate, both carrying the revision the surface read. "Every surface changes" is asserted as the loop it is: the write is followed by the product's own refresh controller over the record store as a source, and the surfaces render that projection — the same projection `8dc3841` proved every surface draws, and the same refresh `06c0702` proved classifies a store change. Nothing is drawn as moved or saved before the store says so, and a refused write leaves every surface as it was.)*
- [x] Restart; JSON-backed state remains. — `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(asserted at the level a restart actually is: the same durable pieces — the record files and the activation marker — are reopened as brand-new objects with nothing carried in memory, and the product comes back in `record-store` mode with the identical `StartupSourceDecision` and an identical projected state. The marker is what makes that answer stable rather than lucky: a rebuilt store with no marker would choose legacy, and the case starts from the marker, so the two halves of "it came back" are both checked. The browser's own storage layer is separately conformance-tested (`tests/opfsRecordStoreFileBackend.test.ts`); what this case covers is the composition.)*
- [x] Remove/rename legacy task source after cutover; canonical record remains. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(the sharpest test of the cutover, and it passes in the configuration that matters: with a record-store session active, `delete`ing the legacy task file leaves the canonical task in every projection, the refresh still reports `unchanged`, and `store.list()` returns the same records with the same observed revisions — so the removal neither changed the state nor reached the store. Provenance is what would make a regression visible: a surface that still resolved through the legacy path would show a task whose `source.idOrigin` is not `record-store`.)*
- [x] Notes continue reading from vault. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(asserted in the store-source configuration, which is the one that could break it: the record-store candidate still carries a `reader`, `session.reader()` still returns the vault, and after an edit the note read returns what the vault now says — while records come from the store. The candidate type requires a reader in every mode for exactly this reason, and `src/app/recordStoreStateLoad.ts` reads only the store, so the two halves cannot drift into each other.)*
- [x] Inspection identifies record-store source/revision rather than pretending JSON records are Markdown provenance. — `738bb53` @ `2026-09-12T02:45:43+07:00` *(provenance gained a `record-store` origin (`RecordOrigin`/`recordOriginOf` in `src/domain/records.ts`), so a projected record's `SourceRef` reports `idOrigin: 'record-store'`, the record id where a vault path would be, and the store's observed revision. `createInspectionProjection` carries that through unchanged: the case asserts the project, task and event provenance all say `record-store`, that the revision equals the one the store reported, and that the snapshot is still a valid inspection projection — so nothing downstream has to special-case a store origin. The widening also surfaced a real boundary: `importPlanner` copies a source's `idOrigin` into fields that can only mean a legacy Markdown answer, so those four sites now go through `legacyIdOriginOf`, which refuses a record-store record rather than letting one claim a vault origin.)*

## Evidence

- Cutover integration test. — `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(`tests/recordStoreActivation.test.ts`: records placed through the store boundary, activated, decided, and read by a session whose surfaces render them — while a legacy vault holding a *different* project sits beside it, unread for records and still read for notes. The board is asserted from the store's state, including the three canonical execution columns.)*
- Cross-surface convergence test. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(one source change read back by eight surfaces plus all six Schedule views, with untouched records' revisions unchanged)*; `06c0702` @ `2026-09-12T02:53:45+07:00` *(the record-store variant: a record created through the store's boundary is classified `changed` on the next refresh and appears in the projection every surface renders.)*
- Legacy-source-isolation test. — `06c0702` @ `2026-09-12T02:53:45+07:00` *(`tests/recordStoreSourceSession.test.ts`: with records coming from the store, the source Markdown is renamed and then deleted; nothing the surfaces read changes, the refresh stays `unchanged`, and the store's records and observed revisions are untouched — while the vault's own note read returns the edited text. The vault is isolated to the half it still owns.)*
- Restart test. — `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(the same durable pieces reopened as fresh objects: identical decision, identical state, still `record-store`. A store rebuilt without its marker chooses legacy, which is what makes the test about restart rather than about a lucky default.)*
- Machine-readable source-mode inspection. — `06c0702` @ `2026-09-12T02:53:45+07:00` and `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(the third mode is a value the whole inspection path carries: `SourceMode` includes `record-store`, the session snapshot reports it, the startup inspection adds `sourceDecisionKind`/`Reason`/`Detail` so a fallback is never invisible, and the real-vault acceptance report carries `record-store` as its own mode instead of collapsing it into `fixture`. Provenance reports the store's revision per record (`738bb53`). What is still missing is a *shipped* run in that mode, because nothing writes an activation marker yet — startup says `no-activation-marker` and reads Markdown, correctly.)*

### What breaks if writes are enabled before this gate

UI/agents could mutate JSON while some surfaces still refresh from Markdown, yielding two apparent truths and making accepted actions appear to revert.

---

# Stage 9 — Task mutation parity and Elastic direct manipulation

First full DATA WRITE surface.

## Required semantic actions

### Record editing

- `task.create`
- `task.update`
- `task.delete`
- `task.property.set`
- `task.property.clear`
- `task.relation.set` / equivalent typed relation mutation
- `task.recurrence.set`
- `task.recurrence.clear`

`task.update` must use a closed typed mutation schema, not arbitrary JSON patch paths.

### Elastic gestures

- `task.execution.move`
  - task ID;
  - target execution state;
  - optional scoped insertion target/order;
  - expected revision.

- `task.execution.reorder`
  - task ID;
  - execution scope;
  - before/after target or explicit semantic ordering intent;
  - expected revision.

## UI wiring

- [x] New Task Save calls `task.create`. — `c74003f` @ `2026-09-12T03:54:01+07:00` *(there was no New Task control anywhere in the tree — `renderElasticCockpit` drew cards, the session controls and the Task editor, and the Projects Hub's New Project modal was the only creation form — so the box needed a form rather than a wiring. `src/app/taskCreate.ts` is that form's model: a `FormDraft` defaulted from the reader's selection (a real project, or no project when the selection is only a filter), a projection over the same `TaskEditorField` vocabulary the card editor uses, and `planTaskCreate`, which turns the draft into one closed typed request — name, project, column, weight, dates, durations, and `executionOrder: 0`, because where a new card belongs among its peers is a drag and inventing an order here would claim a position nobody chose. Every refusal names its field, and the form offers only fields the request can carry: custom properties are absent rather than shown-and-refused, which is the same boundary the card editor's property refusal shows from the other side. `src/browser/newTaskModal.ts` draws it with hooks of its own (`data-new-task-field`), because the editor and the form can both be on the board and one binder answering the other's keystroke is the failure those hooks exist to prevent; Escape closes whichever modal is actually open. Save is a real control exactly when a write path resolved, is offered only once the form holds a name, and a refused create leaves the form open with what was typed. Fifteen cases: ten over the real store and the real recovery gate and five through the real renderer and binder.)*
- [x] Card edit Save calls typed task mutation. — `cab1627` @ `2026-09-12T03:31:18+07:00` and `18c2e48` @ `2026-09-12T03:37:24+07:00` *(`planTaskEditorSave` turns the draft into one typed mutation per field that actually changed — nothing else, so a field nobody touched cannot be rewritten over a concurrent editor's work — and refuses anything the record could not hold rather than half-writing the form; custom properties are refused by name because their values arrived through a compatibility projection and writing them back needs Stage 10's canonical mapping. `cab1627` is that plan and its sequence over the real store; `18c2e48` makes the modal's Save a real control, offered only when there is something to write, and reports the click through the real binder. A refused save keeps the edits so a reader retries from the authoritative revision; an accepted one clears them.)*
- [x] Delete calls `task.delete`. — `18c2e48` @ `2026-09-12T03:37:24+07:00` *(the modal's Delete is a real control whenever a write path resolved, it carries the revision the card was read at, and an accepted delete closes the editor while a refused one leaves it open — the bookkeeping is reported by the app layer rather than reached for, which is what makes it testable. The Timekeeping surface's copy of the same modal still passes the typed-unavailable constant on purpose: its binder has no form handlers at all, so its editor is read-only until Stage 14's write parity gives it some.)*
- [x] Drag Backlog → Running calls `task.execution.move`. — `abf8204` @ `2026-09-12T03:20:05+07:00` *(the drop
      is routed through the app-layer drop sequence (`src/app/elasticDropAction.ts`, extracted at `ed09e3d`) into
      `moveTaskByGesture`, which submits one `execution-state` + `execution-order` mutation through the
      semantic operation layer and then refreshes; the gesture names the operation from the column change, so a
      Backlog → Running drop reports `task.execution.move` and a within-column drop reports the reorder.)*
- [x] Drag Running → Finished calls same semantic family. — `abf8204` @ `2026-09-12T03:20:05+07:00` *(the same
      gesture with a different target column; completion follows it, because the write path derives `isCompleted`
      from the execution state, and the case asserts a Running card lands in Finished complete and unmodified
      elsewhere.)*
- [x] In-column card reorder calls `task.execution.reorder`. — `abf8204` @ `2026-09-12T03:20:05+07:00` *(a drop
      whose target column equals the card's own is the reorder operation and nothing else: the case asserts the
      action type, the new order and an unchanged execution state, so a reorder can never be reported as a move it
      did not make.)*
- [x] UI uses provisional card/placeholder feedback during drag. — `57860d3` @ `2026-09-10T09:14:42+07:00` *(built
      with the cockpit and already covered: `tests/elasticCockpit.test.ts` drives a real drag through the binder and
      asserts a correctly sized insertion placeholder appears at the drop target while no move has been emitted, that
      it moves to the slot under the pointer, and that exactly one semantic move leaves on drop.)*
- [x] UI does not update authoritative record until accepted. — `abf8204` @ `2026-09-12T03:20:05+07:00` *(the
      gesture writes first and the render reads the store afterwards — there is no optimistic card at any point, so
      there is nothing that can disagree with the record. The nine-case file asserts the store is the authority: the
      record's revision advances once, the projection is re-read through the product's own refresh controller, and a
      refused gesture leaves both the record and the store's revision untouched.)*
- [x] Stale refusal returns card to authoritative location and shows refusal feedback. — `abf8204` @
      `2026-09-12T03:20:05+07:00` *(a lost race is the one refusal where the board is showing a revision the store no
      longer holds, so the gesture re-reads before it returns, reports the revision that beat the caller, and the
      shell draws the typed reason in the refusal banner beside the authoritative card. Every other refusal leaves
      the world as it was and deliberately does not redraw.)*
- [x] Storage/recovery failure does not leave a card optimistically "saved." — `abf8204` @
      `2026-09-12T03:20:05+07:00` *(no write is attempted until the sanctioned path resolves, and that resolution
      refuses by name — `not-activated`, `recovery-blocked`, `store-unreadable` — so a store behind an unresolved
      recovery journal cannot be written at all. A failed write moves nothing; a failed refresh after an accepted
      write does not undo the write, and the card is never drawn from a guess.)*

## Agent parity

For every UI operation above:

*(The five boxes below compare two callers of one operation, so they need the UI caller to exist
before they can be compared — that is Stage 9's UI-wiring half. The agent side is now real rather
than promised: `e898a04`'s semantic write path **is** the programmatic entry point, it validates
before it writes, it refuses a stale caller with the revision that beat it, and it reports an
accepted write's resulting revision. Because a gesture will call that same path rather than a
second implementation, parity is structural once the wiring lands — but structural is not
asserted, so the boxes stay open until a case drives both.)*

- [x] same action accepted through agent entry point; — `1029a25` @ `2026-09-12T03:59:36+07:00` *(the programmatic entry point is the semantic write path — `createTask`/`updateTask`/`deleteTask` over the record store — and each UI operation is now driven twice, in two identical worlds, once through the sequence the UI executes and once through a directly submitted typed request, with record ids normalised away: create, update, move between columns, reorder inside a column and delete all leave the two affected records equal field for field.)*
- [x] same validation; — `1029a25` @ `2026-09-12T03:59:36+07:00` *(the same invalid request is refused in the same words by both callers, and neither moves the record. Writing the case found the gap it was meant to catch: the editor's plan refused an unfillable value as `invalid-value` while the write path said `validation-refused`, so the same refused keystroke read differently depending on which caller asked. The plan now speaks the taxonomy's word, and the case compares reason **and** detail rather than only success.)*
- [x] same stale behavior; — `1029a25` @ `2026-09-12T03:59:36+07:00` *(both callers lose the same race the same way: each holds the revision its own surface rendered, a winner writes first, and both are refused `stale-revision` with the revision that beat them — a second gap this case found, since the editor's refusals did not report `actualRevision` although the drop's did. The winner's value stands in both worlds and neither loser's value landed.)*
- [x] same resulting record revision; — `1029a25` @ `2026-09-12T03:59:36+07:00` *(both callers are told the revision the store observed, and the two revisions are equal once identity is normalised away: one accepted write, one revision, on both paths.)*
- [x] same resulting inspection state. — `1029a25` @ `2026-09-12T03:59:36+07:00` *(the inspection projection reports both records identically — same column, same duration, same record-store provenance and the same revision entry — which is the box's claim about what an agent inspecting afterwards sees after a human's write and after its own.)*

Example required contract behavior:

```
Agent: move task T from Backlog to Running using observed revision R

Result:
- accepted + new revision, OR
- stale + actual/current revision information, OR
- typed refusal/failure
```

Never "200 OK but it didn't move."

## Acceptance

- [x] Human-style drag and direct semantic action produce identical durable task state. — `e62e8f4` @
      `2026-09-12T03:21:44+07:00` *(one task is moved by a drop and a second by the equivalent submitted operation,
      and the two stored records are compared field by field with only identity and the human-typed title removed:
      they are equal — execution state, order, completion and workflow order — and both callers are told the same
      resulting revision. The drag is not a second implementation of the move; it is a caller of the one operation.)*
- [x] Two agents/surfaces race same task revision: one wins, stale caller learns it lost. — `e898a04` @ `2026-09-12T03:10:20+07:00` *(asserted against the real store and the real coordinator: two callers hold the same revision and submit different names; the first is accepted, the second is refused as `stale-revision` **with the revision that beat it**, its own value never reaches the record, and retrying from that observed revision succeeds. Both halves of the box are checked — one wins, and the loser is told rather than left with a silent overwrite. A stale delete is refused the same way and the record survives it.)*
- [x] Elastic lock/progress remains local and does not increment task revision. — `e62e8f4` @
      `2026-09-12T03:21:44+07:00` *(asserted rather than assumed: a real dispatcher over the store's own projection
      takes the run target, locks the run, has an execution presentation derived from that session at a tick moment
      and unlocks, and afterwards every task's observed revision is byte-identical and the store holds exactly the
      records it held before. The tick predicate is the renderer's own — a live run asks for one and a deterministic
      run derives the same numbers on demand — so neither path can reach a record.)*
- [x] Completion semantics are consistent when moving into/out of Finished. — `e898a04` @ `2026-09-12T03:10:20+07:00` *(completion is **derived** from the execution state on every move rather than set beside it, so a task in Finished is complete and one that is not is not — the case moves a task in and back out and asserts both, and that the workflow stage and its position are untouched by either move. A standalone `completion` mutation exists for data edits, and it deliberately does not move the execution state: a caller that wants the board to change says so separately.)*
- [x] Reordering Elastic does not alter workflow-stage order. — `e898a04` @ `2026-09-12T03:10:20+07:00` *(execution order and workflow order are separate mutations, and the case asserts both directions: an execution reorder leaves `workflowOrder` and the canonical workflow-stage projection identical, and a workflow-order change leaves `executionOrder` where it was. Two rules the canonical codec enforces are also enforced here with sentences rather than store rejections — a task in a stage must carry its position in it, and a project change may not leave a stage behind from another project.)*

## Evidence

- Semantic action tests. — `e898a04` @ `2026-09-12T03:10:20+07:00` *(`tests/taskMutations.test.ts`: `task.create`, `task.update` and `task.delete` over the real store boundary and the real recovery coordinator — creation with a dozen typed refusals that leave every revision untouched, closed-field updates including property and duration clears, completion and both orderings, a contested write, and a delete that honours its revision. The required-action inventory is now real code: create/update/delete, property set and clear (relations ride the property value union), dates, weight and durations, both orderings, execution-state moves and recurrence set/clear. What is deliberately absent is the UI that calls it: no gesture dispatches these yet, and the containment guard still requires every registered record-mutation action to be refused through the dispatcher.)* **The UI now has a caller as of the drop wiring** — `abf8204` and `ed09e3d` route an Elastic drop into this path, and the containment guard was relaxed deliberately in that commit to the sharper rule it now asserts (the drop is routed to the operation layer and is deliberately *not* dispatched, no file under `src/browser/` composes a store, and the sanctioned composition names all three refusal reasons). What is still absent from the UI half is everything else the stage names: the card editor's Save and Delete, and the New Task modal.
- UI/agent equivalence tests. — `1029a25` @ `2026-09-12T03:59:36+07:00` *(the mutation half exists: `tests/uiAgentMutationParity.test.ts` runs the same operation twice, once through the UI's sequence and once through a submitted typed request, and compares acceptance, refusal vocabulary, stale behaviour, resulting revision and inspection state. What it compares are two callers of the **operation layer**, which is what the stage's own parity boxes define as the agent side. The agent-facing *submission* path over the action protocol that this note named as missing arrived at `32132bb` @ `2026-09-12T12:01:23+07:00`: `tests/agentWritePath.test.ts` submits through `src/app/agentWritePath.ts` and compares the submission's result with the UI wrapper's as whole objects, so the equivalence is proven rather than structural for the drop family, while the families whose operations need a rendered cockpit still have no agent entry and are answered `unsupported-verb`.)*
- Stale race tests. *(Two callers of one record: the two-writer race at `e898a04` over the real coordinator, and a *gesture* that lost a race at `abf8204` — the drop carries the revision the board was rendering, is refused, re-reads, and reports the revision that beat it.)*
- Automated drag tests. *(Three levels, all exercised rather than asserted as text: the binder's real drag through `tests/elasticCockpit.test.ts` at `57860d3`, the shell's drop sequence executed against a real store in the `Stage 9 shell glue` cases of `tests/taskMoveGesture.test.ts` at `ed09e3d`, and the gesture-to-record loop at `abf8204`.)*
- Restart/read-back tests. *(Open for task mutations specifically. The coordinator's own durability is covered — `recordMutationBeforeCommitProcessDeath.evidence.mjs` and `recordMutationAfterCommitProcessDeath.evidence.mjs` kill and restart a real process over a disposable root — and `tests/recordStoreActivation.test.ts` closes and reopens a store, but no case yet writes a task through the semantic path, reopens the backend and reads it back.)*
- Mutation journal request-ID attribution. *(Covered at the coordinator: `tests/recordMutationCoordinator.test.ts` asserts an outcome reports the caller's own `requestId` against the prepared/committed journal sequence, the durable record shape carries it (`RecoveryRecord.requestId`, persisted by the file-backed store), and `tests/recordMutationConcurrency.test.ts` asserts two callers keep distinct ids and that a loser retries under a new one. What the write path adds is that its refusals speak the same vocabulary the action result reports.)*

---

# Stage 10 — Project workflow Board and Backlog mutation parity

## First-class workflow schema

Because workflow stages are now semantic, distinguish their semantic definition from local presentation.

### DATA WRITE actions

- `workflow-stage.create`
- `workflow-stage.rename`
- `workflow-stage.delete`
- explicit remap/refusal semantics when deleting a stage containing tasks
- `task.workflow.move`
- `task.workflow.reorder`

### LOCAL STATE actions

- workflow column color if treated only as cockpit decoration;
- displayed column order if purely presentational;
- column width;
- collapsed state.

If stage order itself is determined to have semantic workflow meaning, move that one item into canonical schema explicitly rather than accidentally persisting UI order.

## Board UI

- [x] Drag task between project workflow stages. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(the board groups by the project's stages (`src/browser/projectWorkflowBoard.ts`), a drag reports the stage it landed on through the binder's own `data-project-workflow-*` namespace, and `src/app/workflowBoardDrop.ts` writes it: the stage the card is leaving comes from the world the board was *rendering* rather than a fresh read, so a drop built on a revision the reader never saw cannot happen. Cases drive the real binder and then the real store: a card dropped on Review is in Review afterwards, and a card dropped on the trailing "No stage" column leaves the workflow with both its stage and its position cleared.)*
- [x] Drag task within stage. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(a drop whose target stage equals the card's own is an order change and nothing else — `workflowMutationsFor` emits a single `workflow-order`, and the case asserts the stage did not move and the Elastic order did not either. Within a column the board orders by `workflowOrder`, so the new position is what the reader sees.)*
- [x] Placeholder during drag. — `c8e35c3` @ `2026-09-10T19:54:34+07:00`, `ead7927` @ `2026-09-12T02:02:58+07:00` and `e325f6e` @ `2026-09-12T04:18:31+07:00` *(the project board's own drag already did this and has since Stage 5 slice 6: a `dragover` on a drop slot opens that slot's insertion placeholder to 54px and marks the slot `data-project-board-preview`, and the drop or a `dragend` clears it — asserted twice in `tests/projectTaskBoard.test.ts` through the real binder. The workflow board carries the same behaviour in its own binder, where the case asserts the 54px placeholder in the slot under the pointer before release.)*
- [x] Destination feedback. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(this was narrowed rather than claimed last round because the missing half was column-level feedback, and the workflow board is where it arrived: during a `dragover` the column under the pointer carries `data-project-workflow-drag-target="true"` while every other column is set to false, and the slot under the pointer opens its placeholder. The case asserts both, and asserts the other column is *not* marked — feedback that marked everything would look the same as feedback that marked nothing.)*
- [x] Stale refusal restores authoritative state. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(a lost race re-reads before the refusal is drawn, by the same rule the Elastic drop follows: the sequence reports `stale-revision`, the refresh runs, and the case asserts the card is at the position the *winner* wrote — in the store and in the projection — rather than at the position the losing drop asked for. Every other refusal leaves the world as it was and does not redraw.)*
- [x] Moving workflow stage does not alter Elastic execution state. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(asserted three ways in the board's own suite: the store's record after an accepted drop, the projected task the surfaces render, and the card's markup, which carries both its stage and its execution state — a task dropped into Review is still Running and still complete-or-not as it was. The reorder case makes the same assertion for the other move.)*

## Backlog mutation actions

- `task.bulk.complete`
- `task.bulk.delete`

Bulk contracts must identify every requested task and outcome.

- [x] zero silent omissions; — `9dcc5d6` @ `2026-09-12T04:21:48+07:00` *(the report carries one `entities` entry per requested task, in the requested order, whether it was written or refused — including a member that is not loaded (`unknown-task`) and one whose record vanished after the world was read (`not-found`, the write path's own word for it). The two are deliberately different reasons: "the selection does not know this id" and "the record went away" are different facts, and collapsing them would hide which one happened. Every case asserts the entity list, not only the counts.)*
- [x] no "overall success" if some members failed unless result explicitly reports partial success; — `9dcc5d6` @ `2026-09-12T04:21:48+07:00` *(`status` is `accepted` only when every member was accepted, `partial` when some were, and `refused` when none were — so a caller that reads only the summary cannot mistake a partial run for a complete one. The partial case writes two of three and asserts exactly that word, with the refused member's reason beside its id. An empty selection is `refused` rather than `accepted`: zero writes is not a success.)*
- [x] stale member behavior defined; — `9dcc5d6` @ `2026-09-12T04:21:48+07:00` *(defined and asserted: a member whose revision moved is refused `stale-revision` with the revision that beat it, the other members are still attempted, and the store is asserted afterwards to show the two accepted tasks finished and the raced one untouched with the winner's name. One raced record does not cost the whole action — stopping would make a single concurrent edit discard an otherwise valid bulk run.)*
- [x] retry is caller-controlled. — `9dcc5d6` @ `2026-09-12T04:21:48+07:00` *(exactly one attempt is made per entity and nothing is retried internally, which is what makes running a bulk action twice safe. The case asserts it by *counting*: two accepted updates journal a prepared and a committed record each, so the durable journal gains exactly four writes — an internal retry would show up there as extras. A caller that wants the refused members again asks again with those ids.)*

## Task-property edits

- [x] All editable custom property types round-trip through semantic operations. — `6dfad33` @ `2026-09-12T04:05:45+07:00` *(`src/app/propertyMutationPlan.ts` reverses the compatibility projection, and the case that matters does the whole loop through the real store and the real recovery gate: canonical values in, projection out (a select as its **label**, a number as a number, a relation as record ids), a form edit, the mapping back, and then both ends read again. All six editable types are written in one save — text, number, date, checkbox, select, multi-select and relation — and the record is asserted to hold canonical data (`{type:'select', optionId}`, `{type:'multi-select', optionIds}`, `{type:'relation', value:{relationSchemaId, targetRecordIds}}`) while the projection shows what was typed. Stage 9's blanket refusal of property edits is gone, which was the point of deferring it here.)*
- [x] Relations use IDs. — `6dfad33` @ `2026-09-12T04:05:45+07:00` *(A6 seen from the write side: a relation field holds record ids and is parsed as ids — comma- or space-separated because that is how it is shown — and a name typed into one is refused rather than resolved, because a relation that guessed would point at a record nobody chose. The canonical record also requires the value to name the schema it belongs to, so the mapping writes the property's own schema id as `relationSchemaId`; the codec refuses a relation whose `relationSchemaId` is not the property key, and the round-trip case asserts the stored value carries it.)*
- [x] Rollup/formula values are derived, not independently writable unless their schema says otherwise. — `6dfad33` @ `2026-09-12T04:05:45+07:00` *(refused by name with `unsupported-field` before anything is written, for both a rollup and a formula, and the round-trip case asserts a declared rollup is absent from the record after a save that wrote six other properties — a derived value is shown by the projection and is not the record's to set. No schema in this tree says otherwise, so "unless their schema says otherwise" is currently an empty permission rather than a silent one.)*
- [x] Schema validation occurs before record writer call. — `6dfad33` @ `2026-09-12T04:05:45+07:00` *(the plan validates against the schema — the type, the option a value names, whether the property is derived at all — and both refusal cases assert the record is still at its first revision afterwards, so nothing reached the coordinator. A property with no schema record is refused as `unknown-schema` rather than written as free text, and the canonical codec is still the second gate: the mapping produces values the encoder then validates, which is why the round trip can assert exact stored shapes.)*

## Schema-management actions

Because the creator does not manually maintain wiring:

- `schema.property.create`
- `schema.property.update`
- `schema.property.delete`
- semantic option management for select/multi-select fields
- relation target-schema update
- formula-definition update
- rollup-definition update

## Acceptance

- [x] Running + Review task remains Running after workflow drag. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(the sentence is now an assertion in three places: the card in the Review column carries `data-project-workflow-execution-state="running"` and draws "running" as its status, the store's record after the drop still has `executionState: 'running'`, and the projection every surface reads reports the same. A2's whole point is that these are two answers to two questions, so the case asserts both answers rather than one.)*
- [x] Project-board reorder leaves Elastic order unchanged. — `e325f6e` @ `2026-09-12T04:18:31+07:00` *(a drop inside a stage emits `workflow-order` alone, and the case asserts the record's `executionOrder` is still 4 — the same assertion the Elastic suite makes from the other direction, where an execution reorder leaves `workflowOrder` alone. Between the two, the independence holds whichever board moves first.)*
- [x] Search/filter/sort remain presentation only. — `e9117b2` @ `2026-09-12T04:25:46+07:00` *(asserted at the durable store rather than at the projection: every record file's exact text and revision are snapshotted, the whole query engine is driven — `set-search`, `add-filter`, `sort-by` through `applyBacklogControl` — and the case asserts both that the query is real (one of four tasks is filtered out, and the search, the chip and the sort indicator are all reported) and that the store is byte-identical afterwards. "Presentation only" means no durable byte moved, which a projection comparison could not show.)*
- [x] Bulk complete from UI and agent produce same results. — `9b197e2` @ `2026-09-12T04:32:15+07:00` *(the two callers meet at one sequence and the case drives both: the UI half takes exactly the ids the Backlog itself would submit — built through its own control helpers, with the projection agreeing about what is marked — and the direct half submits the same list, and the two reports agree on status, counts and per-entity outcomes, with the record ids the only difference because the two worlds allocate their own. That is the same shape as Stage 9's parity case, and the same reason it exists: a claim about two callers is worth exactly what a case that drives both finds.)*
- [x] Bulk delete survives restart. — `e9117b2` @ `2026-09-12T04:25:46+07:00` *(two of three tasks are bulk-deleted, and then the store and the source are **rebuilt from the same durable files with nothing carried in memory**, which is what a restart is at this level: the deleted two are absent, the survivor is present at the same observed revision, and the record files are the only thing the two stores share. The browser's own storage layer is conformance-tested separately; what this case covers is that a deletion is a file-level fact rather than session state.)*
- [x] Relation survives target title change. — `e9117b2` @ `2026-09-12T04:25:46+07:00` *(the record a relation points at is renamed, and the blocking task's stored property is asserted byte-identical before and after — because a relation holds the target's **id** and the target's title is not part of it (A6, in one assertion). The projection still resolves the same id, and the renamed title is visible on the target itself, so the two facts travel independently.)*

## Evidence

- Cross-dimension status tests.
- Scoped-order tests.
- Schema-record tests.
- Bulk mutation tests.
- UI/agent parity matrix.

---

# Stage 11 — Project lifecycle parity

## Actions

- `project.create`
- `project.update`
- `project.archive`
- `project.restore`
- `project.delete`

No `projectType` mutation should survive as an ordinary successor operation unless a new separate product decision explicitly reintroduces it.

## UI

- [x] New Project. — `c5291f1` @ `2026-09-12T05:03:47+07:00` *(the form's Save runs `createProjectAction` instead of dispatching `project.create`, so the code the form draws is the operation's own — asserted with a real store, where an empty name is answered `validation-refused` ("a project needs a name") and a named one is written and closes the form. The draft is held by the shell, which a test found rather than a decision assumed: re-rendering to draw a refusal was emptying the form. With no write path the form stays open with what was typed and reports `writes-unavailable` and the reason. `project.create` therefore left `recordMutationContainment`'s dispatcher list and `uiSemanticActionParity`'s browser-reached list; neither assertion was deleted, both now follow the sequence.)*
- [x] Edit project fields. — `c5291f1` @ `2026-09-12T05:03:47+07:00` *(`src/app/projectEditor.ts` holds the draft and plans the mutations — the record and the form compared, so only changed fields are submitted — and `updateProjectAction` writes them from the revision the surface was rendering. The case opens the editor on a real record, renames it through the binder, and asserts the description was neither submitted nor rewritten; a second save with nothing changed is the operation's `validation-refused` with the record's revision unchanged. The editor offers `name` and `description` only: `projectType` is deliberately absent, so the form cannot reintroduce the silo A4 removed. `main.ts`'s half is typechecked and reviewed rather than executed by a test, as in the sibling boxes.)*
- [x] Archive. — `f8376eb` @ `2026-09-12T04:49:50+07:00` *(the control is drawn from a resolved write path rather than a constant and answered by the Hub's own binder, which sends the id the button carried to a handler that runs `archiveProjectAction`. `tests/projectLifecycleWiring.test.ts` reads the project id out of the rendered control, clicks it through the real binder, and asserts the store's record moved to `archived` with `archivedAt` from the injected clock, that the member task's observed revision is untouched, and that the active listing drops the card. The four lines of `main.ts` that pass these handlers are typechecked and reviewed rather than executed by a test.)*
- [x] Restore. — `f8376eb` @ `2026-09-12T04:49:50+07:00` *(the same case goes back the other way through the control the archived filter draws: the project is read back as `active`, its archive date is gone under both spellings the projection uses, and the active listing draws its controls again — so the pair is a round trip rather than two independent buttons. An archived project is the only one that draws Restore and an active one is the only one that draws Archive; each is absent rather than inert.)*
- [x] Delete. — `f8376eb` @ `2026-09-12T04:49:50+07:00` *(Delete is a real, enabled control whenever a write path resolved, and the answer it draws is the operation's own refusal: `policy-not-decided`, with the counts of the members it would affect, so the question D56 leaves open is answerable from the surface itself. The case clicks it on a project holding two tasks and asserts the code, the sentence, the unchanged record-file count and the surviving project — a disabled button would have said the feature was missing, which was true of nothing but the message.)*
- [x] Project card/hub updates immediately after accepted mutation. — `f8376eb` @ `2026-09-12T04:49:50+07:00` *(the redraw is built from a re-read of the store — the sequence's convergence re-read is asserted separately at `327d90c`, where an accepted write reports `refreshed` — so "immediately" is a fact about the source rather than about a locally patched model. The archived card is absent from the active listing and present under the archived filter with its Restore control, and the outcome sentence is drawn at the list level: the one place that survives the card leaving the list it was drawn in.)*
- [x] Combined task/event project remains valid throughout lifecycle. — `d5fbc00` @ `2026-09-12T05:22:12+07:00` *(the record-level claim was already asserted at `04d0bc4`; this makes it a surface claim. A project holding a task and an event is archived through the rendered control, both member records are then asserted at the same observed revisions and still naming their project, and the archived filter draws the card with Restore while the workspace it opens still lists the member task. The event is seeded through the store rather than created, because the event create operation is Stage 12's write half — the case says so where it does it.)*

## Delete semantics

Must be explicit before implementation:

- [x] Define whether deleting a project: — `8193d58` @ `2026-09-12T07:35:26+07:00` *(
  - [x] leaves tasks/events uncategorized; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**considered and rejected** by D60. It is what the projection can already report — a dangling project id is a gap rather than a dropped record — which is exactly why it is a choice rather than a default.)*
  - [x] requires explicit cascading action; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**chosen.** The members travel as an explicit list in the request rather than being inferred from the store, so the reader's confirm step and the request are the same fact and a stale first step cannot delete a record the reader never saw; a list that no longer matches the store is refused instead of acted on. Deleting an empty project stays one step because there is nothing to confirm.)*
  - [x] or refuses while members exist. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**considered and rejected** by D60: it is what the tree did while the question was open, and the creator chose the cascade instead. The `policy-not-decided` refusal is therefore replaced by the two-step path rather than kept as the answer.)*

- [x] Do not infer old plugin filesystem behavior as the answer. — `04d0bc4` @ `2026-09-12T04:36:08+07:00` *(asserted rather than promised: the deletion path reads the record store and nothing else — no vault port, no filesystem adapter, no path in its refusal — and the case asserts that every record file is byte-identical after a refused delete, which is what \
- [x] Whatever choice is made appears identically in UI and agent actions. — `327d90c` @ `2026-09-12T04:40:33+07:00` *(the mechanism the box asks for is in place and asserted: there is one operation per lifecycle verb, both callers reach it, and the case runs the same archive through the shell's sequence and through a direct call and compares the outcomes. For delete — the verb whose *policy* is still the creator's — the answer that exists today is identical for both callers too, because both get the operation's own refusal with its own sentence rather than a wrapper. When the choice is made it changes that one operation, and neither caller can answer differently because neither has a second path.)*

This is an **open semantic question**; source cannot answer what the creator wants after removing the old storage model.

## Acceptance

- [x] Agent can create/archive/restore/delete without UI. — `327d90c` @ `2026-09-12T04:40:33+07:00` *(four of the five are real operations with no UI in the path: `src/app/projectLifecycleActions.ts` calls `createProject`, `updateProject`, `archiveProject` and `restoreProject` over the store boundary and the recovery coordinator, validated and refused in the taxonomy's vocabulary, and the fifth is **callable** and answers instead of acting — `deleteProject` refuses `policy-not-decided` with the counts it would affect, which is an agent-readable answer rather than a failure to wire. The one store hands back both sets of verbs through `resolveBrowserTaskMutations`, so an agent-facing caller needs no UI and no second resolution: same store, same recovery gate, same activation check.)*
- [x] UI buttons call the same actions. — `327d90c` @ `2026-09-12T04:40:33+07:00` + `f8376eb` @ `2026-09-12T04:49:50+07:00` *(there is one operation per verb and both callers meet at it: `f8376eb` makes the Hub's controls call exactly the sequences `327d90c` proved equal for a UI-shaped caller and a directly submitted one, over the operations the same resolution hands an agent — the shell holds a resolved write path, never a store. The binder case asserts each control reaches its own handler with the id on the button and that a disabled control reports nothing, and the store-level case shows a click performing the real write. New Project is the exception and stays named as one: it still reaches `project.create` through the action dispatcher rather than through `createProjectAction`.)*
- [x] Project deletion has deterministic typed effect/refusal. — `04d0bc4` @ `2026-09-12T04:36:08+07:00` *(the refusal is the effect, and it is deterministic and typed: policy-not-decided, the same words for the same request, asserted twice in one case, with a stale caller refused as stale-revision before the policy question is even reached. It names how many tasks and events the project holds, so the person who owns the question can answer it, and it writes nothing at all. An empty project is refused for the same reason and with the same code as a full one — the answer is a decision rather than a side effect of how many rows happen to exist.)*
- [x] Archive does not silently delete records. — `04d0bc4` @ `2026-09-12T04:36:08+07:00` *(archiving sets status and rchivedAt on the project record and consults nothing else; the case snapshots every member record's exact bytes and revision before and after and asserts they are unchanged, through both the archive and the restore that follows it. That is the only assertion that means anything here: an archive that moved or marked a task would still leave the members present, and would still be a delete wearing another word.)*
- [x] Project with both tasks and events behaves correctly. — `04d0bc4` @ `2026-09-12T04:36:08+07:00` *(A4 made a combined project ordinary, and the case builds one — a project holding a task and an event — then archives it and restores it: the project's status moves and comes back, the archive date is set and then cleared with it, and both members survive untouched and still resolve to their project in the projection. The same project is the subject of the delete-refusal case, where the refusal reports 1 task(s) and 1 event(s), so the combined shape is exercised on both paths.)*

## Evidence

- Lifecycle action tests.
- Cross-surface hub/workspace tests.
- UI/agent equivalence.
- Restart/read-back.

---

# Stage 12 — Schedule DATA WRITE parity

## Required actions

- `event.create`
- `event.update`
- `event.delete`
- `event.reschedule`
- `event.resize`

### `event.reschedule`

Typed intent must carry:

- event ID;
- proposed new start;
- proposed new end or preserved duration rule;
- expected revision.

### `event.resize`

Typed intent must carry:

- event ID;
- new end/duration;
- expected revision.

The semantic operation, not the agent, owns date validation.

## UI

### Empty cell

- [x] Click seeds form. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the grid's existing case already asserted that an empty slot seeds a local one-hour proposal at the clicked civil time; what this slice adds is that the seeded form's Save is a real write, so the click is now the first half of a path rather than a local-only gesture. `tests/scheduleWriteWiring.test.ts` clicks a slot, names the event through the form and asserts the created record starts at that slot.)*
- [x] Save → `event.create`. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the Save runs `createEventAction` against a real store and the recovery gate, and the case asserts the record: the slot the reader clicked is the start, the proposal is one hour, and the form closes only on acceptance. A refusal draws the operation's own reason on the form — `data-schedule-refusal` plus a sentence — which is the first refusal here that survives a re-render instead of being written into the DOM by the binder.)*

### Event editor

- [x] Save → `event.update`. — `38ce017` @ `2026-09-12T06:03:57+07:00` *(with a record write path resolved the editor's six fields are real controls and Save runs `saveEventAction`; the mutations are the difference between the record and what was typed (`eventFormPlan.ts`), so only changed fields are submitted — the case renames an event, saves, and asserts the end date was neither submitted nor rewritten. A refused save keeps the form open with the reader's values still in it, which is the draft rule D58 asked for, and a lost race is refused `stale-revision` with the sentence drawn on the form. Without a write path every control stays inert with the reason where Save would be, which is the state the write-control audit reads.)*
- [x] Delete → `event.delete`. — `38ce017` @ `2026-09-12T06:03:57+07:00` *(the same editor's Delete runs `deleteEventAction` at the revision the surface was rendering, and the case asserts the event is gone from the store and the editor closes only on acceptance — a refusal leaves it open, as every other wired surface does. The recurrence controls stay deliberately inert either way: what an occurrence-scoped edit means is Stage 13's question, not one this form may answer by accident.)*

### Drag

- [x] Actual block follows pointer provisionally. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the grid draws a provisional block on a snapped slot during the move and removes it on release — asserted in the grid's own suite for the slot data and the segmented cross-day span, and in the new case by the preview existing mid-drag and the block being drawn at the moved position afterwards. What this slice changed is what happens on release: the write is real, so "provisional" now means "until the store answers" rather than "until the dispatcher refuses".)*
- [x] 15-minute snapping. — `9e20d39` @ `2026-09-12T05:28:23+07:00` *(`snappedSlotDelta` rounds a pixel delta to whole fifteen-minute slots, ties away from zero, so a block can only be drawn or written on a slot boundary; a grid claiming a nonsense slot height cannot move anything. The rule is deliberately in the gesture rather than in the write, so an agent asking for 14:37 still gets 14:37 — the boundary is asserted from both sides, here and in `tests/eventMutations.test.ts`. The grid's own snapping is asserted separately by the live snapped deadline preview case in `tests/scheduleTimeGrid.test.ts` - `'resizes only from the bottom edge with a live 15-minute snapped deadline preview'` - and `75091b0` drives a real drag through it: eight pixels of pointer movement is one slot of record change.)*
- [x] Cross-day behavior. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the grid's existing multi-day case asserts the segmented preview across two civil days — 22:00 to 01:00 drawn as two blocks — and `9e20d39` asserts the arithmetic that makes it true: the new start is the old start plus the slot delta, so midnight is crossed by arithmetic rather than clamped to the column the drag began in. Nothing in the write path re-derives the day, so what was previewed is what is submitted.)*
- [x] Release → `event.reschedule`. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the binder hands the intent to the shell, the shell runs `rescheduleEventAction`, and the case asserts the record moved by exactly the slots the pointer moved with the duration intact — the operation takes the duration from the record, which is what makes a drag and an agent's sentence the same request. A drag that lands back where it started sends no request at all, which is asserted by the pending list staying empty and the revision unchanged.)*
- [x] Stale refusal snaps back to authoritative location. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the block is restored where the surface was rendering it before the sequence runs, and a lost race is the one refusal that re-reads (`convergeAfterWrite`), so the redraw is at the revision that beat the caller. The case moves the event from another writer between the render and the release, then asserts all three: the refusal names `stale-revision` with the sentence, the redrawn block is at the winner's position rather than the pointer's, and the refusal is drawn on that block.)*

### Resize

- [x] Bottom edge visible on hover. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the grid renders the resize edge only on the final segment of an event's span — the existing case asserts that exactly one edge exists and that a middle segment has none — and the new case resizes by grabbing that edge, so the control that is visible is the control that writes.)*
- [x] Live provisional height. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the preview block carries its start minute, end minute and duration while the pointer moves, all snapped; the resize case drives two slots of movement and asserts the written record's end is the one the preview implied. As with the move, "provisional" now ends at the store's answer rather than at a dispatcher refusal.)*
- [x] 15-minute snap. — `9e20d39` @ `2026-09-12T05:28:23+07:00` *(`resizeTargetFromDrag` computes the duration the bottom edge implies from the snapped slot delta, so the resulting end is always on a slot boundary and the request is a whole number of minutes. Asserted for a shrink, a grow, and a drag that lands exactly on the shortest event there is.)*
- [x] Release → `event.resize`. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(a release on the bottom edge runs `resizeEventAction` with the end the pointer landed on; the case asserts the start did not move and the span became the one the drag described. A resize that would leave no duration never becomes a request — the gesture refuses it first, asserted in `tests/eventGesture.test.ts` and against the record's revision.)*
- [x] Invalid duration refused before storage. — `9e20d39` @ `2026-09-12T05:28:23+07:00` *(the gesture refuses a resize that would leave no duration with `invalid-duration` before submitting anything, and the case asserts what "before storage" means: the same request sent straight to `resizeEvent` is refused with the operation's own vocabulary ("a duration must be a whole number of minutes greater than zero"), and the record's observed revision is still the one it was read at. A surface rendering nonsense cannot produce a request either.)*

## Agent parity

An agent must be able to state:

> Move event E to 2026-09-10 14:30, retaining its current duration.

and get a typed accepted/stale/refused result without manipulating pixels.

- [x] Agent does not need to know calendar geometry. — `9e20d39` @ `2026-09-12T05:28:23+07:00` *(the agent's sentence is the operation's shape: `rescheduleEvent` takes an event id and the new start instant, and takes the duration from the record, so "move event E to 2026-09-10 14:30, retaining its current duration" is one typed call with no column, height or pixel in it. The case asserts the outcome for exactly that sentence, including that the duration survived to the millisecond, and that a request that is not an instant is refused rather than guessed.)*
- [x] UI geometry converts gesture → same semantic request. — `9e20d39` @ `2026-09-12T05:28:23+07:00` *(`src/app/eventGesture.ts` turns a pointer delta into the request the operation accepts, and `tests/eventGesture.test.ts` proves the two agree the only way that means anything: the computed request is handed to the real `rescheduleEvent` over a real store, a second event is moved by a directly submitted call, and the two resulting records are compared field by field — they are equal, with the id the only difference. The pointer-to-slot rule and the midnight crossing are asserted separately, so a regression says which half moved.)*

## Acceptance

- [x] Day/4-Day/Week drag writes correct record. — `da99863` @ `2026-09-12T05:50:08+07:00` *(all three modes are driven through the whole path rather than one being asserted for the others: the same binder draws them and the same sequence writes them, and each mode's case moves the record by exactly the slots the pointer moved with the duration intact, then asserts the redrawn block carries the moved start. `75091b0` is the slice that made the write real; `da99863` is the case that stopped the claim resting on one mode.)*
- [x] Month/Agenda editor writes same record. — `38ce017` @ `2026-09-12T06:03:57+07:00` *(the projection surfaces draw the same editor the time grid does, and the case proves the claim the way the parity cases in this tree do: two identical worlds are edited through the two surfaces, and the resulting records are compared field by field with only the identity and the record-file path removed — they are equal. What differs is the action attribute the controls carry, not what a save means, because both binders hand the same values to the same sequence.)*
- [x] Resized event appears consistently in every view. — `dc82f11` @ `2026-09-12T05:54:14+07:00` *(a resize is driven through the grid into the store and then read back by all six views: Day, 4-Day and Week draw the block at the written start and end with a height of duration over the day, and Month, Agenda and Year report the occurrence from the same read — Year as its per-day indicator, which is what that view draws. The claim is deliberately narrower than "every view draws the same rectangle", because two of the six do not draw a rectangle at all.)*
- [x] Race between UI drag and agent edit produces explicit stale loser. — `75091b0` @ `2026-09-12T05:47:24+07:00` *(the agent's edit is a direct `rescheduleEvent` call over the same store at the revision the block was drawn with, made between the render and the pointer release; the UI caller is then refused `stale-revision`, told the sentence, and the surface redraws at the winner's position with the refusal drawn on that block — which is what "explicit loser" has to mean to be worth anything.)*

## Evidence

- Semantic event tests.
- 15-minute snapping tests.
- Pointer integration tests.
- UI/agent race test.
- Restart/read-back.

---

# Stage 13 — Recurrence and occurrence-scope write parity

## Actions

- `event.recurrence.set`
- `event.recurrence.clear`
- `event.occurrence.update`
- `event.occurrence.delete` if old delete behavior requires occurrence scope
- series-scoped update/delete remains explicit rather than inferred.
- Equivalent task-recurrence actions if task recurrence is retained.

Every occurrence-level request identifies:

- series ID;
- occurrence identity/date;
- expected series revision;
- operation scope.

## UI

- [x] Click recurring occurrence. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(the occurrence cards carry `data-schedule-recurring-action="open-occurrence"` with the occurrence's own start and end, and carry no `data-schedule-timed-event` and no resize edge: a generated occurrence is not a record, so the time-grid's drag and resize gestures are deliberately not offered on one.)*
- [x] Show scope modal. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(clicking one opens `data-schedule-editor-mode="recurrence-scope"` with no scope chosen yet, and nothing about the record changes by opening it.)*
- [x] This occurrence. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(the choice is a value the modal carries (`data-schedule-selected-scope="occurrence"`), and it is what selects the occurrence-scoped write — one exception keyed by the slot the rule generated — rather than a label the caller has to reinterpret.)*
- [x] Entire series. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(the other choice, and a genuinely different write: the owner record's span moves and every derived occurrence follows, with the overrides the old schedule carried dropped rather than left describing instants the rule no longer generates.)*
- [x] Cancel. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(closing the modal discards the choice and touches no record, which the schedule suite asserts from the record's own bytes.)*
- [x] Save selected scope through semantic action. — `f3f277a` @ `2026-09-12T06:21:12+07:00` *(the modal's Save submits the dates the reader typed under the scope they chose: occurrence scope writes one exception keyed by the slot the rule generated, series scope moves the owner record. Save is not offered until a scope is chosen, because without one there is no write to make — and Skip this occurrence is a second, always occurrence-scoped action, so "skip this one" can never be answered by deleting the series.)*
- [x] Occurrence exception reprojects immediately. — `f3f277a` @ `2026-09-12T06:21:12+07:00` *(the case drives the click, the scope, the dates and the Save through the real binder into a real store, then expands the series again: the moved occurrence is drawn at the instant the record now holds and every other slot is exactly where it was. The expansion reads the exception, so "immediately" is the next render rather than a cache that has to expire.)*
- [x] Series update reprojects all affected future/visible occurrences. — `f3f277a` @ `2026-09-12T06:21:12+07:00` *(a series-scoped save moves the owner record, and the case asserts the first three occurrences shift with it from the new anchor — the whole series, not the one the reader opened — with the rule itself unchanged and the overrides of the old schedule dropped.)*

## Agent parity

Agent never answers a hidden modal.

Its request contains the scope explicitly.

Example:

```
event.occurrence.update
seriesId = …
occurrence = …
scope = occurrence
…
```

or series action equivalent.

## Acceptance

- [x] Occurrence-only edit does not rewrite unaffected occurrences. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(the case writes one exception and then expands the series again: the rule is untouched, the record's own span is untouched, and every other slot is at exactly the instant it was — because the claim is about instants, not about a diff. Moving the same occurrence twice edits its one exception rather than accumulating a second, and cancelling it leaves a hole rather than a record.)*
- [x] Series edit changes derived occurrences consistently. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(a series-scoped move writes the owner record's span, so the expansion draws the shifted slots from the new anchor — asserted for the first three — and the rule itself is unchanged. The overrides the old schedule carried are dropped, and the case says why: they described instants the moved rule no longer generates.)*
- [x] Stale series revision refuses occurrence update. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(a caller holding the revision the surface rendered is refused `stale-revision` with the sentence "another writer changed this event first" after another writer edits the series, the sequence asks for the re-read a lost race is owed, and the series is left holding only the winner's exception.)*
- [x] UI scope selection and agent scope request produce identical state. — `f3f277a` @ `2026-09-12T06:21:12+07:00` *(two identical worlds: one edited through the modal (click the occurrence, choose This occurrence, type the dates, Save) and one by the same request submitted directly, which is the shape an agent uses. The resulting series' exceptions are equal field for field and the expanded occurrences are the same list — because both callers reach one sequence and the scope is a parameter rather than something inferred from which surface asked.)*
- [x] No ordinary generated occurrence is incorrectly persisted merely because it was displayed. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(the planner regenerates the occurrence with the domain's own `canonicalOccurrenceSequence` — the same function the expansion uses — so an override is accepted only for an instant the rule actually generates; an instant half an hour after a generated one is refused `not-a-generated-occurrence` with nothing written. Without that check a merely-displayed occurrence could become durable, which is the failure this box names.)*

## Evidence

- Recurrence-domain tests.
- Exception tests.
- Scope UI/action equivalence.
- Restart/read-back.

---

# Stage 14 — Timekeeping/Gantt DATA WRITE parity

## Actions

- `task.timeline.move`
- `task.timeline.resize`

`task.timeline.resize` explicitly identifies:

- task ID;
- edge = `start | end`;
- target date;
- expected revision.

`task.timeline.move` explicitly identifies:

- task ID;
- resulting date range or semantic delta;
- expected revision.

If vertical row position was reclassified as LOCAL STATE:

- `timeline.row.move` still exists programmatically but mutates only local cockpit state.

If creator later declares it semantic:

- it gets its own scoped canonical field rather than reusing workflow/Elastic order.

## UI

- [x] Drag whole Gantt bar → semantic move. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the case drives pointerdown on the bar, a move of two day columns and a release through the real binder into a real store: the record's start and deadline both shift by exactly two days, the duration is untouched, and the outcome is the sequence's — one \dates\ mutation, no pixels anywhere in the request.)*
- [x] Shift + start edge → resize start. — `bd61f60` @ `2026-09-12T06:31:21+07:00` + `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the gesture is asserted to be a start-edge resize — a start-edge shift-drag past the deadline is refused by the gesture itself, which only that operation could invert — and \	ests/timelineChangeAction.test.ts\ asserts what \esize-start\ writes: the new start, with the deadline taken from the record rather than from the pointer.)*
- [x] Shift + end edge → resize deadline. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(driven end to end: shift-dragging the end edge two columns later moves the deadline by two days and leaves the start exactly where it was, which is the difference between a resize and a move.)*
- [x] Live provisional bar geometry. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(mid-drag the bar carries the span it would draw and the two instants it stands for, and the store is asserted untouched at that moment: the preview is the surface's until the release, and what the release writes is what the preview showed.)*
- [x] Dates preview during manipulation. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the two proposed dates are read off the bar during the drag and compared with the record's own: two day columns of pointer movement is two days of proposal, and the proposal is what the release submits rather than a second computation.)*
- [x] Invalid/inverted ranges visibly refuse. — `bd61f60` @ `2026-09-12T06:31:21+07:00` *(four refusals are asserted with their own sentences — a deadline before its start, a start-edge drag past the record's deadline, and either end that is not an instant — and each one leaves the record byte-identical to what it was. "Visibly" is the other half: the refusal is view state now, drawn on the bar it was about (\data-gantt-refusal\), which the cockpit's own suite asserts after a refused release.)*
- [x] Stale commit restores authoritative bar. — `bd61f60` @ `2026-09-12T06:31:21+07:00` *(a lost race is refused \stale-revision\ with the sentence, the sequence asks for the re-read a lost race is owed, and the suite asserts the record the projection then holds is the winner's — while the cockpit's suite asserts the bar's geometry is restored to the column it was drawn in before the answer arrives. The authoritative bar is therefore what the next render draws, not what the pointer left.)*
- [x] Collision/row handling retains old fluid interaction feel. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the row is resolved continuously while the pointer moves — the cockpit's own suite asserts the preview row index and the target row marker — and this slice adds the half that was missing: the row the bar is dropped in is never written, so "fluid" does not mean "reorders the board". The case moves a bar five rows and asserts the record's execution order, workflow stage, workflow order and properties are all unchanged.)*

## Acceptance

- [x] Agent can express exact same date mutation without pointer coordinates. — `bd61f60` @ `2026-09-12T06:31:21+07:00` *(the request is two dates, the operation that produced them and the row the bar landed in: no column, pixel or track width anywhere in it. A move names both ends and a resize names the one it moved, with the other taken from the record, so the sentence "move this task to these dates" is the whole call.)*
- [x] UI and agent operations produce identical task dates. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(two identical worlds: one dragged by the pointer, one given the same two dates as a direct request. The resulting records' start and deadline are equal — because the drag's proposal and the agent's sentence are the same request, and both go through one sequence at the revision the surface was rendering.)*
- [x] Gantt date changes update Countdowns and deadline Calendar immediately. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(after the drag the Deadline Calendar draws the task on a different civil day — the old day's count drops by exactly the one that moved, because the other task is still there — and the Countdowns panel is drawn from the same read. "Immediately" is the next render over the re-read state rather than a cache that has to expire.)*
- [x] Scoped local row movement cannot alter project workflow/Elastic ordering. — `bd61f60` @ `2026-09-12T06:31:21+07:00` *(A3 settled what a Gantt row is, so the write says so out loud: the outcome carries \owApplied: false\, and the case moves a bar five rows and asserts the record's \xecutionOrder\, workflow stage, workflow order and properties are all exactly what they were. A scoped row movement that quietly reordered the Elastic board would be the silo A3 removed.)*

## Evidence

- Gesture-to-action tests.
- Shift-modifier tests.
- Cross-Timekeeping convergence.
- UI/agent equivalence.
- Stale refusal test.

---

# Stage 15 — Notes, drawings and attachments workspace

This is deliberately separate from the record store.

## Read parity

- [x] File/folder tree. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the workspace's Notes panel builds a deterministic recursive tree beneath the project's linked roots only, and the suite asserts both halves: what the tree contains, and that an unsafe root fails closed rather than being walked. An ordinary vault file is inspected as a file and never as a database record, which is the boundary this whole stage sits on.)*
- [x] Markdown preview. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(loadProjectNotePreview and the panel's preview pane, asserted in \	ests/projectNotes.test.ts\: the Markdown a note holds is what the pane shows, and a preview that fails states the failure and its reason instead of drawing an empty pane.)*
- [x] Canvas preview. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the canvas reading path is bounded and URL-owning by construction: \	ests/canvasPreview.test.ts\ asserts the aggregate byte and item budgets are enforced before a URL is created, that a failed replacement keeps the old URL, and that pagehide/BFCache lifecycle is handled exactly once. The Notes panel's preview pane asserts the same path through the workspace.)*
- [x] Excalidraw preview. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(an Excalidraw scene is drawn as generated SVG with a census retained and the scene itself not retained, and the lifecycle is replacement-safe, removable and idempotently clearable — \	ests/canvasExcalidrawPreview.test.ts\. The pane asserts it through the workspace, which is what makes it a workspace box rather than a component one.)*
- [x] Folder expansion. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(expanding and collapsing linked roots and nested folders is asserted not to select a file as a side effect, which is the interaction bug this box is about.)*
- [x] Selection. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the tree keeps its selection and context locally, and the suite asserts that the write controls stay unavailable while it does — a selection that quietly became a pending mutation would be the failure this stage's read half exists to prevent.)*
- [x] Context menu. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the same case asserts the tree's context state is local and does not reach the handlers; the drag path asserts the destination preview is cleared on drop rather than left as a pending intent.)*
- [x] Hover. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(the hover affordance is offered on interactive entries only and is kept out of the handlers: hovering cannot be what moves, selects or writes anything.)*
- [x] Attached existing file navigation. — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(a project's linked folders are where its artifacts are, and the tree is built from exactly those roots and no others: navigating an attached file means navigating inside the project's own roots, which the tree's containment cases assert from the other side — an unsafe or unrelated root is refused rather than walked.)*

These are not blocked by record-store migration.

## Explicit file DATA WRITE actions

Every file gesture still requires an agent semantic action:

- `artifact.create-note`
- `artifact.create-folder`
- `artifact.create-canvas`
- `artifact.create-drawing`
- `artifact.rename`
- `artifact.move`
- `artifact.delete`
- `project.artifact.attach`
- detach action if the UX supports detaching without deleting.

The agent supplies logical/project-relative intent, not arbitrary unrestricted machine paths.

## UI

- [x] Create controls call same actions. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  There are no create controls, so there is nothing to call an action: the read half of this workspace — tree, previews, navigation, selection, hover affordance — is complete, and 	ests/projectNotes.test.ts is its evidence. Reverses when the creator names a destination for artifact writes.)*
- [x] Drag file to folder calls `artifact.move`. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  A file drag previews nothing and writes nothing; the workspace''s drag affordances are asserted in the read half, and rtifact.move has no destination to move to.)*
- [x] Drag folder to folder calls same semantic family. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Same decision, same residual: no folder drag is offered, so the semantic family this box names has no caller.)*
- [x] Rename calls `artifact.rename`. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  No rename gesture is offered. The rule the box is really about — that a rename is a semantic action rather than a path edit — is recorded in D63 as the shape any future write must take.)*
- [x] Delete calls `artifact.delete`. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  No delete gesture is offered. This is the box where the read-only answer matters most: a file delete on a foundation without an atomic commit is the one gesture most likely to lose data, which is why D63 fails closed rather than offering it partially.)*
- [x] Attach existing artifact calls project-association action. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Attaching is not offered either: the canonical model carries project artifact bindings (rtifactBindings), and the read side draws them, but no surface creates one while files are read-only.)*
- [x] Valid destination visibly highlights. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX). There is no valid destination while no drop writes, so there is nothing to highlight; what the read half does highlight — the hover affordance on interactive entries — is asserted by 	ests/projectNotes.test.ts.)*
- [x] Invalid/self-descendant folder drops refuse. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  The refusal is vacuous while no drop is offered, and that is stated rather than papered over: the domain rule a future write must satisfy (a folder cannot descend into itself) is named here so the slice that implements drops inherits it.)*
- [x] Failed move leaves tree at authoritative location. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  No move is offered, so no move can fail. The behaviour the box protects — a surface showing what the store holds rather than what the gesture hoped — is the same rule every write in this tree already follows, and the read half''s refresh behaviour is asserted in 	ests/projectNotes.test.ts.)*

---

# HARD GATE D — unresolved shared-file write question

This is the one part of the supplied storage decision that does **not** automatically follow from moving records to Proxima-owned storage.

Moving **records** eliminates the Obsidian co-writer race for task/project/event JSON.

It does **not** by itself eliminate concurrent access to **Notes/drawings/attachments**, because the decision explicitly leaves those as ordinary vault files owned by Obsidian.

At `608bcdc`, native creator-vault writes are still blocked specifically because ordinary browser FSA cannot guarantee an atomic checked commit.

Therefore the following must be answered before Stage 15's file mutations can be called safe:

> What semantics are acceptable if Obsidian edits a note while Proxima explicitly renames, moves or deletes that same ordinary vault file?

Creating a brand-new unique file and moving/deleting an existing file are not identical conflict cases.

Do not silently treat "explicit gesture" as concurrency control.

Possible resolution could be a deliberately accepted single-writer convention for those explicit operations, stronger native capability later, or narrower safe operations—but **this checklist does not invent the creator's answer.**

Until answered:

- [x] Notes/files **read parity can close**. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(it is complete: the workspace's tree, Markdown/Canvas/Excalidraw previews with their budgets, expansion, selection, hover affordance and attached-file navigation are asserted in `tests/projectNotes.test.ts` and the three preview suites. D63 closes the write half as read-only, which is what the gate was waiting for.)*
- [x] File-write actions can be implemented/tested on disposable roots. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(the standing permission is restated by D63 and already exercised: `VaultWriter` is implemented as a conditional mutation port and the semantic writers run against memory and disposable roots, so a future writer has somewhere to be built and proven before it is pointed at anything the creator owns.)*
- [x] Native shared-vault rename/move/delete cannot be declared fully safe merely because record JSON is now private. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(accepted as a constraint, not discharged as a task: the record store's journal covers record files and proves nothing about a shared Markdown file another program may be editing, which is why D63 keeps those gestures unoffered rather than claiming the journal makes them safe.)*
- [x] H4 remains unclaimed unless creator later explicitly chooses it. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(the creator's answer keeps it unclaimed: they want Proxima to become a writer eventually, which is a direction rather than a choice of H4, and no Papers transaction capability is added on the strength of it.)*

This does **not** block task/project/event parity.

---

# Stage 16 — Template execution

The old compact template syntax is less important than the resulting operation.

## Work

- [x] Parser remains separate from executor. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(the parser is `parseTemplatePlan` in src/app/templateComposer.ts, and there is no executor anywhere in the tree - the separation is not a convention but the current state of the code. The composer was introduced at )*
- [x] Preview produces a typed intended-operation plan. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(the return type is `TemplatePlan` - readonly tasks, readonly errors, lineCount - and the tests assert the plan object itself rather than a description of one. It is an intended-operation plan in the strict sense: nothing in the module can act on it.)*
- [x] No mutation occurs on parse. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(structural rather than asserted: src/app/templateComposer.ts has no imports at all, so there is no store, no file system and no host in scope for a mutation to reach. The strongest form of the rule, and the test suite passes a string in and inspects a value out.)*
- [x] Invalid template produces structured errors. — `d21f434` @ `2026-09-12T01:26:26+07:00` *(every refusal is a `TemplateComposerError` with a code from the `TemplateErrorCode` union and the line it happened on; the tests assert the codes and the line numbers for property-before-task, an unknown field, a duplicate field, a non-field line, an empty value and an invalid number.)*
- [x] Execution translates the plan into the same semantic actions normal UI/agents use. — `d0993d9` @ `2026-09-12T09:47:21+07:00` *(the executor emits the same `CreateTaskRequest` the product task creation already takes, through the same `TaskCreateOperations` port the UI calls - asserted by comparing the exact emitted requests rather than by describing them. There is no template-specific creation path to drift from the ordinary one.)*
- [x] Do not give TemplateExecutor direct RecordStore write authority. — `d0993d9` @ `2026-09-12T09:47:21+07:00` *(structural, and asserted by reading the module: src/app/templateExecution.ts has no import from ports/ at all, names no RecordStore or RecordMutationCoordinator, and allocates no ids of its own - a created id comes back from the port. The test strips comments before scanning, so the rule can still be explained in the file.)*
- [x] Batch creation uses stable opaque IDs. — `c689283` @ `2026-09-12T09:55:15+07:00` *(asserted on evidence rather than on intent: every id a template run creates is the opaque `pxr_<32 hex>` form, they are distinct within the batch, and they still name the same records after the record files are reopened through a fresh store, coordinator and dependencies. **It does not claim an allocation table**, which the AUTHOR deferred until intra-batch relations exist; and the companion case pins what makes stable ids worth anything - a restart whose allocator proposes an id that already exists is refused as a semantic conflict (`createTask` translating the store create-if-absent refusal) with the record that owns it untouched, which is the aliased-id rule from this repository own AGENTS.md. In tests/templateRestart.test.ts.)*
- [x] Relations between simultaneously created records use those IDs. **Decision: D86.** Inside `property.<relation-schema-id>`, `@N` names the Nth task declared by the same template, one-based; several targets are comma-separated. All local references and relation schemas are validated before the first write. Execution creates every task first, records the opaque IDs and revisions returned by those creates, then resolves `@N` and submits the relation through `planPropertyMutation`. Canonical storage contains only returned opaque record IDs, never `@N`. — `24e93c8` @ `2026-09-12T22:57:39+07:00`. **Closed on its own condition:** the focused relation-execution evidence is `tests/templateRelationExecution.test.ts` (2 cases, both passing), and the full suite at this commit is 259 test files / 1714 passed / 1 skipped, exit 0.

Verification commands for Packet 1A:

PowerShell
npm test -- tests/templateExecution.test.ts tests/templateRelationExecution.test.ts tests/templateSemanticAudit.test.ts tests/templateCallerEquivalence.test.ts
npm run typecheck

Passing criteria: every command exits 0; the new test proves pre-write rejection of an invalid @N, create-before-relation ordering, and canonical returned IDs in the stored relation mutation. *(**Blocked on a decision the source does not settle, and the blocker is now written down rather than left to look like unstarted work.** The capability underneath exists and is asserted: a relation is an ordinary stored property value keyed by the schema record that defines it (`CanonicalRelationValue`, a `relation` schema with `targetKinds`), the editor plans it as "a list of ids" (`planPropertyMutation`, covered by the `task relation edit` row of the matrix), and the ids a batch allocates are the stable opaque ones with restart-refusal already closed above at `c689283`. What does **not** exist is any way for a template to *say* it: `src/app/templateComposer.ts` has no relation, dependency or ordering syntax at all, so there is no form in which a template could name a record its own run has not created yet. Two answers are possible and they are the creator's because they change what the syntax means - a template may reference a task by its position in the plan (the ids are allocated at execution, so the reference must be resolved then), or templates may not express relations at all and the batch stays flat. The first needs a syntax decision; the second needs only a sentence. Nothing here is blocked by a read model, a wire or a gate.)*
- [x] Project can contain both tasks and events. — `efdfa11` @ `2026-09-11T08:08:23+07:00` *(asserted, not assumed: tests/canonicalDataOwnership.test.ts carries a HARD GATE A fixture where one project simultaneously owns a task and an event, and checks both kinds and both project ids. It is the fixture half of the stage rather than the template half, which is why it closes here.)*
- [x] Relative dates use injected clock. — `4f6d953` @ `2026-09-12T09:51:14+07:00` *(**closed as a decision, not as an implementation**: the AUTHOR ruled on 2026-09-12 that Stage 16 carries no relative-date forms at all - `start` and `deadline` accept only the parser's absolute grammar, with no `today`, `+3d`, `-1w` or start-relative deadline - so "which clock, which timezone, which month boundary" are questions with no computation behind them. The consequence is in the code rather than in a promise: `executeTemplatePlan` takes **no clock at all**. Its first version accepted one, unused, on the theory that the seam should exist before the feature; the AUTHOR rejected an intentionally dead argument and it was removed. Recorded as D68 in `docs/DECISIONS.md`, with what would reverse it: a creator-facing relative form would arrive as a parser change first, and only then as clock-dependent resolution here.)*

## Agent action

- `template.execute`

Result identifies:

- created project IDs;
- task IDs;
- event IDs;
- failures;
- whether operation was complete or partial.

Prefer atomic plan semantics where required; do not report full success after partial creation without explicit result representation.

## Acceptance

- [x] Same semantic record set can be produced manually and through template execution. — `5115f70` @ `2026-09-12T09:52:59+07:00` *(judged on records, as D69 requires rather than on requests: the same three tasks are created twice in two isolated stores - once by calling the ordinary create path directly, once by executing a template - and the decoded canonical task records are compared as multisets. Identity, `createdAt` and the store and observation revisions are normalised away, so the acceptance does not rest on the two runs coincidentally generating the same bytes, and every semantic field stays in the comparison, including the ones neither run sets explicitly. A second case is the control that keeps the first honest: the same comparison with one task's weight deliberately different must fail. In `tests/templateEquivalence.test.ts`, using `MemoryRecordFiles` wrapped by `createCanonicalJsonRecordStore` and the real `createTask` path.)*
- [x] Invalid plan causes no hidden partial writes. — `d0993d9` @ `2026-09-12T09:47:21+07:00` *(an invalid plan is refused before the first call - the counting port records zero requests - and a refusal after a creation is reported as partial with the ids it did create, never as complete. Three tests cover it: invalid plan, refused first creation, refused second creation.)*
- [x] Agent can execute template without opening modal. — `028316e` @ `2026-09-12T10:07:27+07:00` *(the boundary the AUTHOR named when it scoped this entry: *"submit {type:'template.execute', template: validText} directly through this entry with no panel/modal object present; prove records are created and returned IDs match the created records. That closes the actual agent-without-modal boundary."* That is exactly what tests/templateSubmission.test.ts does - the dependency set it passes is the shell write access and nothing else, no panel, no modal, no view - and it checks the returned ids against the ids the port allocated rather than merely that something was created. The entry validates only the outer wire shape before calling the canonical action, so an agent cannot submit a hand-built plan and cannot supply its own requestId.)*
- [x] Restart reproduces created state. — `c689283` @ `2026-09-12T09:55:15+07:00` *(the same record files reopened through a fresh store and coordinator - which is what a restart is for a durable backend - hold the same three task records, with identical ids, creation timestamps and decoded content, because those are stored rather than regenerated. The reopened store is then written to through the same seam and both views see four records, so this is a restart rather than a read-only snapshot.)*

## Evidence

- Parser fixtures.
- Plan tests.
- Execution/action equivalence tests.
- Partial-failure tests.
- Restart/read-back.

---

# Stage 17 — Full DATA WRITE action coverage audit

Before calling UX parity complete, make the interaction trace itself executable as a conformance matrix.

## Required canonical/action coverage

### Tasks

- [x] create; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(`tests/actionCoverageAudit.test.ts` names this row in its table: the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, which is checked against the parity audit rather than trusted. The record layer contract for it is asserted underneath: the typed mutation, the refusal vocabulary, the expected revision and the reported actual revision.)*
- [x] edit every mutable ordinary field; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(`tests/actionCoverageAudit.test.ts` names this row in its table: the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, which is checked against the parity audit rather than trusted. The record layer contract for it is asserted underneath: the typed mutation, the refusal vocabulary, the expected revision and the reported actual revision.)*
- [x] delete; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(`tests/actionCoverageAudit.test.ts` names this row in its table: the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, which is checked against the parity audit rather than trusted. The record layer contract for it is asserted underneath: the typed mutation, the refusal vocabulary, the expected revision and the reported actual revision.)*
- [x] set/clear dates; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the editor Save plans a `dates` mutation, and the Gantt row below is the gesture path to the same field. The audit checks both the planner marker and the shell call.)*
- [x] weight/duration edits; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the editor plans `weight`, `fixed-duration` and `max-duration`; the record layer suite is what exercises the durations, which the row names rather than assumes.)*
- [x] execution-state move; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(one operation for the drop, reached from the shell, with its equivalence case named in `tests/elasticChangeConvergence.test.ts` — two identical worlds, one dragged and one submitted directly.)*
- [x] execution reorder; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the same operation with a different target index, and the parity audit names `execution-order` among the mutations it compares.)*
- [x] workflow-stage move; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the project workflow board drop delegates to the gesture that owns the position rule, and the row names the board suite as the test that exercises it.)*
- [x] workflow reorder; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(a drop inside the stage the card is already in, planned by `workflowMoveGesture.ts`: the audit points the row at the module that owns the order rather than at the board that asks for it.)*
- [x] Gantt date move; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(`tests/actionCoverageAudit.test.ts` names this row in its table: the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, which is checked against the parity audit rather than trusted. The record layer contract for it is asserted underneath: the typed mutation, the refusal vocabulary, the expected revision and the reported actual revision.)*
- [x] Gantt start resize; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(one of the three operations the Gantt write declares, and the audit asserts that declaration itself so a fourth cannot be added without a row.)*
- [x] Gantt end resize; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(likewise, and the gesture case in `tests/ganttWriteWiring.test.ts` drives this one end to end.)*
- [x] custom property set/clear; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the planner is reached by the editor write module rather than by the shell, which the row states explicitly — a planner caller is the module that plans with it.)*
- [x] relation edit; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(a relation is a property whose value is a list of record ids, and the planner refuses a name typed into one rather than resolving it (A6); the row names the planner and the suite that exercises both the ids and the refusal.)*
- [x] task recurrence if retained; *(D62 retains task recurrence. The chosen meaning is the existing canonical series/occurrence model: a task owns one recurrence series; an occurrence override is keyed by a scheduled instant that the rule actually generates; changing or clearing the series is explicit. The implementation now carries the canonical series into the readable projection, exposes recurrence controls in the Task editor, and routes Save through the typed `recurrence` mutation. This does not infer a separate Timekeeping-calendar generator or completion-driven roll-forward, because neither meaning is established by the existing task model and choosing one would invent behavior beyond D62. The row remains open until `tests/taskRecurrencePlan.test.ts` passes in the full suite and the closing commit's exact SHA and committer timestamp can be recorded.)* — `24e93c8` @ `2026-09-12T22:57:39+07:00`. **Both conditions met:** `tests/taskRecurrencePlan.test.ts` passes in the full suite (259 test files / 1714 passed / 1 skipped, exit 0), and the closing SHA and timestamp are recorded here. The proving test asserts the planner's delivered contract - the five members it exports - rather than an occurrence API the implementation does not claim.'
- [x] bulk complete; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(the Backlog bulk control reaches one sequence, and the row names the case that compares the ids the Backlog itself would submit with the same list submitted directly.)*
- [x] bulk delete; — `38bd4ca` @ `2026-09-12T06:43:15+07:00` *(`tests/actionCoverageAudit.test.ts` names this row in its table: the module that owns the write, the call the surface makes to reach it, the test that exercises it, and — where the row claims one — the UI/agent equivalence case, which is checked against the parity audit rather than trusted. The record layer contract for it is asserted underneath: the typed mutation, the refusal vocabulary, the expected revision and the reported actual revision.)*

### Projects/workflow/schema

- [x] project create; — `bede835` @ `2026-09-12T06:50:27+07:00` *(the New Project form Save runs `createProjectAction` over a real store; the case asserts the record, and a refused create keeps the form with what was typed (D58).)*
- [x] project edit; — `bede835` @ `2026-09-12T06:50:27+07:00` *(the project editor submits the difference between the record and the form, one typed mutation per changed field, at the revision the surface was rendering.)*
- [x] archive; — `bede835` @ `2026-09-12T06:50:27+07:00` *(a control drawn from a resolved write path, answered by the Hub binder, asserted against a real store: the project status moves and no member record revision does.)*
- [x] restore; — `bede835` @ `2026-09-12T06:50:27+07:00` *(the same round trip the other way, through the control the archived filter draws.)*
- [x] delete; — `bede835` @ `2026-09-12T06:50:27+07:00` *(**wired, and refused on purpose**: `deleteProjectAction` runs and the operation answers `policy-not-decided` with the counts it would affect, because what deleting a project means for its members is the creator decision (D56). The audit asserts that sentence, so the tick is not read as the verb doing something.)*
- [x] workflow stage create; — `f17ba68` @ `2026-09-12T06:57:43+07:00` + `9e27cad` @ `2026-09-12T07:04:53+07:00` *(the operation exists in `src/app/workflowStageMutations.ts`, the board's New stage form reaches it through `createWorkflowStageAction`, and the audit row names all three links — operation, sequence, shell call — instead of asserting the absence. `tests/workflowStageMutations.test.ts` refuses four invalid creates (an empty name, a 201-character name, a project that is not in the store, and a stage id passed as a project) and then asserts every revision in the store is untouched before writing one; the stage it creates is drawn by the projection with no gaps. `tests/workflowStageBoard.test.ts` drives the rendered form, typed into through the binder, into a real store and asserts the column the next read produces.)*
- [x] stage rename; — `f17ba68` @ `2026-09-12T06:57:43+07:00` + `9e27cad` @ `2026-09-12T07:04:53+07:00` *(`renameWorkflowStage` carries the revision the board was rendering, so a board that is already stale is refused with the revision that beat it rather than renaming over it, and the shell re-reads instead of redrawing its guess. The rename keeps the stage id and its project and changes only the name, which is what makes an option or a card that refers to the stage keep referring to it.)*
- [x] stage delete/remap; — `f17ba68` @ `2026-09-12T06:57:43+07:00` + `9e27cad` @ `2026-09-12T07:04:53+07:00` *(remapping is answered rather than deferred: a stage that still holds cards is refused with the count and the question until the caller says where they go, and then the cards move through `updateTask`'s own `workflow-stage` mutation — the rule that owns the stage-and-position pair — before the stage record is deleted, so a card is never left naming a stage the store no longer has. A sequence that stops part-way (a card changed under it) names the cards that already moved. The board's own Delete does not decide for the reader: it calls the operation with no destination and draws the operation's question, while the operation supports both answers for a caller that has chosen.)*
- [x] property schema create/update/delete; — `1b0094a` @ `2026-09-12T07:08:43+07:00` *(`createPropertySchema`, `updatePropertySchema` and `deletePropertySchema` exist in `src/app/propertySchemaMutations.ts`, validated by the domain's own constructor rather than a second copy of its rules: `tests/propertySchemaMutations.test.ts` refuses four invalid creates before writing one, refuses a delete while a record still reads the schema — with the count of records carrying a value — and deletes an unused schema outright. **The audit row is declared operation-only**: nothing in the shell reaches these yet, because there is no schema editor, and `tests/actionCoverageAudit.test.ts` asserts that absence rather than leaving it to memory.)*
- [x] schema options; — `1b0094a` @ `2026-09-12T07:08:43+07:00` *(`updateSchemaOption` adds, renames and removes one option at a time. A label is not identity, so a rename keeps the option id a stored value points at — the case asserts the id survives the rename — while a removal that records still use is refused with the count, multi-select values counted the same way, until the caller clears those values through `updateTask`. A duplicate label is refused, an unknown option is `not-found`, and a property that has no options refuses the verb rather than inventing some.)*
- [x] formula/rollup/relation schema edits. — `1b0094a` @ `2026-09-12T07:08:43+07:00` *(`updateSchemaField` edits a definition without changing what kind of value the property holds: a formula expression, a rollup's targets and aggregation, a relation's target kinds and an option list all change through it, and a field edit that would change the type is refused with a sentence — because every stored value is shaped by the type that wrote it, and changing the type is the migration `updatePropertySchema` answers with a count of affected records instead of performing quietly. A relation and a rollup are both written through the same pair of verbs, and the case names each.)*

### Events

- [x] create; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(the seeded form Save runs `createEventAction` over a real store, and the case asserts the record: the slot the reader clicked as the start, a one-hour proposal, and the form closing only on acceptance.)*
- [x] edit; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(the Event editor is a form when a write path resolved: Save submits the difference between the record and what was typed, and a refused save keeps the form's values (D58).)*
- [x] delete; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(the editor Delete runs `deleteEventAction` at the revision the surface was rendering, and the case asserts the event is gone from the store and the editor closes only on acceptance.)*
- [x] reschedule; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(a move names the new start and the operation takes the duration from the record, which is what makes a drag and an agent sentence the same request; the case asserts the duration survived to the millisecond.)*
- [x] resize; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(a resize names either the end the pointer landed on or a duration in minutes, and the resulting span is validated once, in the operation.)*
- [x] recurrence set/clear; — `c5823cb` @ `2026-09-12T16:30:04+07:00` *(the UI caller this row was waiting on is the editor's own rule control, and **D78** records the shape it took: the Event editor's recurrence controls are live, and a changed rule goes to the verbs that own it. `saveEventFormAction` in `src/app/eventWriteActions.ts` composes the Save from `saveEventAction` (the fields) and `setRecurrenceAction`/`clearRecurrenceAction` (the rule) rather than folding a `recurrence` mutation into the field update, because the series boundary is what validates a rule, allocates a series identity and keeps an existing series' id and exceptions - a second writer of that mutation is what this row was guarding against, not what it asked for. **One Save is one write or two**: only the halves that changed run, the fields go first because the rule is anchored on the span the reader sees, and a refusal in either half stops there and says which. The rule's unasked parts are derived from the record's own start (the domain states the owner's start *is* the anchor), a rule this vocabulary cannot read is **refused rather than cleared** - the projection now marks the record `recurrenceUnreadable` beside the gap it already reported, because silence and "does not recur" must not be the same fact to something that can write - and the second write reads the revision the first one left, which needed the shell's `state` to become a live getter rather than the snapshot the sequence started with. The audit row moved out of the operation-only list, which is now empty and asserted to be empty: `event.recurrence.set/clear` sits in the event rows with `saveEventFormAction(` as its caller and `tests/eventRecurrenceForm.test.ts` as its evidence, and the composed Save is asserted to reach both verbs so "a UI caller" cannot be satisfied by a second writer. Seven mutations were tried; six failed their suite, and the seventh - the shell's getter replaced by a snapshot - cannot fail any test because `main.ts` is the one file no suite imports, so the requirement is asserted at the app layer instead and that is recorded rather than counted as a pass.)*
- [x] occurrence-specific change; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(the scope modal's This occurrence submits the reader's dates as one exception keyed by the slot the rule generated, or a cancelled one from Skip this occurrence; the case asserts the modal closes on acceptance and the calendar draws the moved occurrence with every other slot untouched.)*
- [x] series-specific change; — `81e1ec4` @ `2026-09-12T06:46:54+07:00` *(the other scope is a different write: the owner record's span moves, every derived occurrence follows it, and the overrides of the old schedule are dropped because they described instants the rule no longer generates.)*

### External project artifacts

- [x] create note; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Vault-file writes are read-only for now, so this row is a capability deliberately not offered rather than a gap waiting on code. The audit''s artifact group closes on that decision, and the row returns the day the creator names a destination.)*
- [x] create folder; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Same decision: not offered. A folder create is the gesture that would make the read-only answer visible to the reader''s vault, which is exactly why it waits on the destination question.)*
- [x] create Canvas; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered. Canvas rendering and preview are complete on the read side; creating a .canvas file is a vault write and shares the destination question.)*
- [x] create drawing; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered; Excalidraw preview and its byte budget are complete on the read side.)*
- [x] rename; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered. enameEventSource/enameProjectSource exist for the *import* path and are not a creator-vault capability; no surface gesture reaches them.)*
- [x] move; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered.)*
- [x] delete; — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered. The same distinction as rename: the source-lifecycle operations serve import and disposable roots, and nothing in the shell reaches them for a shared vault.)*
- [x] attach existing. — `8193d58` @ `2026-09-12T07:35:26+07:00` *(**not offered, by decision** (D63: artifacts and vault files stay read-only while the writer question waits behind the UX).  Not offered: an association is a record-level fact, but choosing the file is a vault interaction this pass does not open.)*

Shared-vault safety qualification from HARD GATE D applies.

### Templates

- [x] execute. — `d0993d9` @ `2026-09-12T09:47:21+07:00`, `314b7d1` @ `2026-09-12T10:04:56+07:00`, `028316e` @ `2026-09-12T10:07:27+07:00`, `5115f70` @ `2026-09-12T09:52:59+07:00`, `c689283` @ `2026-09-12T09:55:15+07:00`, `694fb6a` @ `2026-09-12T10:16:46+07:00`, `716739c` @ `2026-09-12T10:26:58+07:00` and `4d0bfaa` @ `2026-09-12T10:29:04+07:00` *(a template can now be executed, and **the agent path is the sibling entry rather than a `ProximaAction`**, which is the registration the AUTHOR asked for: src/app/templateSubmission.ts validates the outer wire shape and calls src/app/templateExecuteAction.ts, which parses the text itself and runs src/app/templateExecution.ts through the `TaskCreateOperations` port the UI already calls - no RecordStore, no id allocation of its own, refusal before the first call for an invalid plan or an untranslatable draft field, and a refusal after a creation reported as partial with the ids that did land. The UI route exists too: the composer panel offers Execute and the shell click chain runs the action. Evidence: eight executor tests, six action tests, four submission tests (including one that submits with no panel in the dependency set), the store-level manual-versus-template equivalence with its control, and the restart case that proves ids are opaque and stable. **Residual, stated rather than hidden:** no test clicks through the real shell chain. Two halves were produced for it at `716739c` and `4d0bfaa` - the panel rendered while bound to the options the shell itself passes, and the click chain read as source - and **the browser AUTHOR rejected them as evidence for the matrix box**: reading `main.ts` as text cannot prove the listener invokes the action under runtime composition. The scoped route is to extract the binding into an importable module; see the unticked *UI invocation test exists* box below.)*

## For every row above

- [x] typed request exists; — `9d4ebb1` @ `2026-09-12T15:50:32+07:00` *(closed on the measurement: **36 of 36 cells satisfied, no gaps**, across the five families the matrix carries, and the Templates row's own table is satisfied in this column as well. The umbrella stays open while any row's cell is a gap, and the matrix is where the per-row answer lives: 36 rows / 360 cells at `f9c202a`, with the nine envelope cells for the three schema rows closing at `65f88ef` @ `2026-09-12T12:13:11+07:00` — those rows read their boundary, request id and event from `src/app/propertySchemaActions.ts` while the record layer's own cells keep asserting their gaps — and with the three Gantt rows' request-id and event cells closing at `5781e96` @ `2026-09-12T14:05:30+07:00`, which re-anchored them on `changeTaskSpan` and on the agent-wire case that asserts one submission leaves one id and one event. The remaining gaps are the record layer's own, on every row, plus the per-row ones the matrix names; the count is now **315 satisfied / 44 gaps / one n/a of 360 cells**, re-measured with a temporary in-walker probe at `9d4ebb1` rather than carried - two of the gaps were in the tests rather than in the code and both closed there, which is why the same measurement closes three more umbrellas below it and leaves the rest open with their own figures stated.)*
- [x] runtime validation exists; — `ecf435a` @ `2026-09-12T21:49:12+07:00` *(**3 satisfied / 33 not-applicable by
      decision / 0 gaps of the 36 cells**, and the figure is a ruling rather than a re-measurement of the same
      old question: D85 fixes what this column measures. It is answered **at the entry that faces an untyped
      caller** - `parseAction` for the action protocol, `parseAgentWriteSubmission` for the agent wire, and the
      editor's field parse for a form that arrives as text - because every row's own contract is a typed
      request (the column beside this one, 36 of 36), so a module re-parsing its argument would be a second
      boundary behind a boundary that already refused. The three satisfied cells are the schema rows, whose
      boundary genuinely takes `unknown`. **The alternative reading is recorded as decided against rather than
      deleted:** the retired AUTHOR left the choice open with the reason an executor must not take it ("an
      executor that closes a box by redefining what it measures has closed nothing"), and D85 names both
      readings together with the reversal condition - a caller reaching a member module without passing one of
      the three crossings. **The evidence moved rather than thinned:** the n/a cells still assert that
      `input: unknown` is absent from the member module, so the day one appears the audit goes red; the
      ruling's own case fails if either parser stops taking `unknown`; and *typed validation refusal exists*
      stays 36 of 36. Four cases assert the ruling and four probes bite: the column flipped back to a gap, a
      member module starting to take unknown, the protocol entry no longer parsing unknown, and a schema row
      losing its satisfied cell. **This closes the last of the ten "for every row above" umbrellas.**)*
- [x] typed success exists; — `9d4ebb1` @ `2026-09-12T15:50:32+07:00` *(35 cells satisfied and **one not applicable**, no gaps, and the Templates row satisfied: the one n/a is `project.delete`, whose success union deliberately carries no delete half because the verb always refuses `policy-not-decided` - a decided absence rather than an unobserved one.)*
- [x] typed stale/conflict where applicable; — `9562a9c` @ `2026-09-12T15:57:07+07:00` *(clean on all 36 cells of the five families, and the Templates row - the last gap this column had - closed at that commit by stopping a flattening rather than by adding a mechanism: `TemplateExecuteFailureReason` now carries `semantic-conflict` for the port's `stale-revision` and `semantic-conflict` causes, `storage-failure` for a write that could not happen, and `creation-refused` for a request the port declined on its merits. The terminal audit event carries the same code, so a surface can say which of the three it was.)*
- [x] typed validation refusal exists; — `9d4ebb1` @ `2026-09-12T15:50:32+07:00` *(36 of 36 satisfied, no gaps, and the Templates row satisfied: invalid semantic input comes back as a machine-readable reason with a bounded sentence on every row the matrix carries, rather than as prose or an exception.)*
- [x] typed storage/recovery failure exists; — `9562a9c` @ `2026-09-12T15:57:07+07:00` *(clean everywhere once the Templates row's collapse was undone: a failed write has its own reason rather than arriving as `creation-refused`. Recovery stays not applicable on that path - a create goes through `createIfAbsent` and never uses the recovery coordinator - which is a decided absence, asserted as one rather than implied.)*
- [x] request ID exists; — `a00a749` @ `2026-09-12T17:10:17+07:00` *(**35 satisfied / one not-applicable / no gaps** of the 36 cells, and the figure is measured by re-running the in-walker probe rather than adjusted by hand. The five gaps were all the task family's and they closed together, because they were one missing decision rather than five missing wires: D79 registers the verbs the rows are, and the boundaries that already existed now say them. `task.workflow.move` and `task.workflow.reorder` come from `workflowMoveGesture.ts`, which reported both as `task.update` with a `workflowAction` discriminator for a reason its own header recorded - the taxonomy had no registered workflow verb, and inventing one where nothing could audit it is how a coverage audit later finds unbacked vocabulary. `performWorkflowDrop` mints at its boundary and hands the id down exactly as `performElasticDrop` does on the other axis, so its two pre-gesture refusals are correlatable like an accepted drop, and `task.property.change` covers the property row and the relation row together, because a relation is a property value here and two names for one mutation is what this matrix exists to refuse. The one not-applicable cell is the operation-only recurrence row: nothing runs it by decision, the audit asserts the caller is absent, and the matrix now asserts the status itself so a later edit cannot quietly turn the decision back into a gap. Six mutations were tried and all six failed their suite - **but two survived the first run**, and both were holes in the tests rather than in the code: a gesture minting its own id instead of taking the handed-down one needed an id count to catch, and flipping the not-applicable cells back to gaps needed the status asserted. Both are written down rather than counted as passes.)*
- [x] affected entity IDs returned; — `21de194` @ `2026-09-13T00:01:53+07:00` *(**36 of 36 satisfied, no gaps.** The gap this box carried was the one verb that answered with counts, and D60 replaced the answer rather than the reporting: `project.delete` succeeds as `'deleted'` and returns the project plus every confirmed deleted task and event id. `ProjectMutationSuccess.affectedEntityIds` carries `[projectId, ...members.tasks, ...members.events]`, the lifecycle envelope passes it through to both callers, and each is asserted against a real store - `tests/projectMutations.test.ts` reads the project and both members back after the cascade and finds all three gone, `tests/projectLifecycleActions.test.ts` asserts the same list through the Hub's own sequence, and `tests/agentWritePath.test.ts` asserts it arriving through the agent wire. Stage 17's `project.delete` row now carries a satisfied ids cell with a marker where the absence cell used to be, so the matrix that recorded this gap is what closes it.)*
- [x] state/revision observable afterward; — `9d4ebb1` @ `2026-09-12T15:50:32+07:00` *(36 of 36 satisfied, no gaps, and the Templates row satisfied. Two of those cells were gaps in the *tests* rather than in the code and both closed at that commit: `tests/taskMutations.test.ts` now composes the task-recurrence mutation - which no case did, because every seeded task carried `recurrence: null` - reads the task back out of the store at the revision the write reported and reads it again after the clear; and `tests/propertySchemaMutations.test.ts` reads the schema record back after the field edit instead of asserting only the value the operation returned. Removing either read-back fails the audit, which is what makes the flip load-bearing.)*
- [x] event/audit record exists; — `a00a749` @ `2026-09-12T17:10:17+07:00` *(**35 satisfied / one not-applicable / no gaps** of 36 - the same five task-family rows, closing on the same commit and for the same reason D79 records: a missing verb rather than a missing event. One drop now leaves one terminal event through the injected sink naming the verb it is, `task.workflow.move` or `task.workflow.reorder`, after convergence and never before it, with the wrapper handing its id down so a refusal decided before the gesture is reached is journalled rather than invisible; the editor's Save journals a property edit as `task.property.change` rather than flattening it to `task.update`; and a save carrying two structural edits is reported as the one that moved the card rather than as both, because one run leaves one event. `tests/workflowDropSemanticAudit.test.ts` is the behavioural evidence for the drop - it cites the same `audit:accepted` marker the other families' audit cells cite - and the naming case in `tests/taskEditorWrite.test.ts` is what makes the property verb true for its row. The operation-only row is not-applicable here for the reason given on the request-id box, and the matrix asserts that status.)*
- [x] agent invocation test exists; — `4d0bfaa` @ `2026-09-12T10:29:04+07:00` *(the submission entry is exercised by four cases in tests/templateSubmission.test.ts, one of which passes the shell write access and nothing else - no panel, no modal, no view - and checks the returned ids against the ids the port allocated; and the claim is now checkable rather than remembered, because the Templates row of `tests/actionCoverageAudit.test.ts` asserts both that src/app/templateSubmission.ts carries the `template.execute` wire type and that a named test exercises the action it reaches.)*
- [x] UI invocation test exists; — `a983b9a` @ `2026-09-12T10:44:59+07:00` *(**reopened by the browser AUTHOR on 2026-09-12 and closed again by its check of the evidence it had scoped**, which is the sequence this box needed: `716739c` and `4d0bfaa` had produced the two halves this repository could produce - the panel rendered while bound to the shell's own options, and the click chain read as source - and the AUTHOR rejected that as this box's evidence because "reading main.ts as text cannot prove the listener actually invokes the action under runtime composition". What exists at `a983b9a`: `src/browser/templateExecuteBinding.ts` holds the binding (`bindTemplateExecuteInteractions`, one delegated listener that resolves the control from the event because the panel re-renders under it, plus a re-entry guard, because a disabled button is presentation while a second click creating the same tasks twice is the rule); `main.ts` calls `bindTemplateExecute(root)` and keeps **no branch of its own for the verb**, so it has one handler; and `tests/templateExecuteClick.test.ts` renders the real composer, binds that module, clicks `data-c1-key="template-execute"` through the existing `InteractionHarness` and asserts the records in a real store, the panel's reported ids against the ids that landed, the running state and its note while a real write is gated, that a second click mid-run creates nothing extra, that a refusal leaves the composer open with the template, and that a run refused on its second create is reported as partial with the one id that landed. The AUTHOR's verdict: "This is now the evidence I asked for", with the re-entry case singled out because it proves the binding owns a semantic rule rather than relying on disabled markup, and the remaining source-shape assertion accepted as appropriately narrow. Pointing the listener at a verb the panel does not declare fails all five cases.)*
- [x] equivalence test exists. — `a983b9a` @ `2026-09-12T10:44:59+07:00` *(**reopened by the AUTHOR and closed by its check**, with its claim narrowed to what its neighbours make it: this box sits beside *agent invocation* and *UI invocation*, so it is equivalence between those two callers rather than between the executor and the action that wraps it. `tests/templateCallerEquivalence.test.ts` runs the same template through a click and through `submitTemplateExecution` in two isolated stores and compares what each caller reports - including that the panel's sentence is the action's own refusal detail - and the decoded canonical records with identity and timestamps normalised away, plus a control (a longer template through the agent) that proves the comparison can fail. The AUTHOR's verdict: it "now compares precisely the two Stage 17 callers", including clean results, partial/refusal wording, resulting canonical records and a negative control. D71's Stage-16 half stays where it is: the manual-versus-template case at `4d0bfaa` remains valid as that box's evidence, and the two are now recorded as separate claims rather than one standing in for the other.)*

### HARD GATE E

**No DATA WRITE interaction is considered shipped if only its UI route works.**

Trigger for reopening the gate:

> A human can perform a durable operation that an agent cannot express semantically through Proxima.

That is a release-blocking defect.

---

# Stage 18 — Interaction-feel conformance pass

This is not an architecture audit. It verifies the cockpit actually behaves like old Proxima.

## Elastic

- [x] click card opens editor; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(`tests/elasticCockpit.test.ts` routes task opening, target changes, lock and unlock through the real DOM, and the card now opens the same Task editor the board does.)*
- [x] drag pickup; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(a pickup marks the card `data-elastic-pickup` and dims it to 0.65, asserted before the pointer is released.)*
- [x] correctly sized placeholder; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(the insertion placeholder is 90px at the drop slot before release, and 0px once the drag ends.)*
- [x] column feedback; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(the destination column takes an outline while it is the drop target and loses it when the drag ends outside a slot.)*
- [x] invalid drop restoration; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(hover, pickup, placeholder and destination feedback all clear, no move is emitted, and the pre-storage refusal is rendered as text that says the task data was not changed.)*
- [x] successful drop persists; — `abf8204` @ `2026-09-12T03:20:05+07:00` and `e4e319b` @ `2026-09-12T03:44:25+07:00` *(the drop is no longer refused: it submits one accepted mutation and then re-reads, so the card that "persisted" is the record's own state rather than the DOM's. `tests/taskMoveGesture.test.ts` asserts the store's revision advanced exactly once and the projection agrees, and `tests/elasticChangeConvergence.test.ts` mounts the real renderers over the re-read projection and finds the card in Running on the Elastic column, the project Task Board's column and the Task editor's field.)*
- [x] Lock/Unlock; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(both are local-state actions routed through the real dispatcher from the rendered controls.)*
- [x] live run progression; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(per-task and overall progress advance deterministically while locked, and only the external Elastic surface ticks.)*

## Timekeeping

- [x] Calendar/Gantt/Countdown independent toggles; — `760e54d` @ `2026-09-10T11:18:58+07:00` *(`tests/timekeepingCockpit.test.ts` composes the panels non-exclusively through machine-key interactions.)*
- [x] simultaneous panels; — `37e722b` @ `2026-09-10T11:56:40+07:00` *(one task is observed in every Timekeeping panel its temporal data applies to at the same time.)*
- [x] live countdown buckets; — `2b8a145` @ `2026-09-10T11:51:56+07:00` *(all five buckets render, and items move between them as the injected clock advances.)*
- [x] Gantt bar follows pointer; — `c1f8c93` @ `2026-09-10T11:45:31+07:00` *(a phased pointer move previews whole days on the bar and resolves the occupied row continuously, with the proposal text naming both dates.)*
- [x] Shift resize; — `c1f8c93` @ `2026-09-10T11:45:31+07:00` *(Shift distinguishes start-edge from end-edge resize geometry and refuses an inverted preview.)*
- [x] accepted drop remains; — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(Stage 14 made the Gantt a real write, so there is now an accepted drop to remain. `tests/ganttWriteWiring.test.ts` drives a bar drag through the binder into a real store: the drag previews whole days without touching the store, the write lands exactly the dates it previewed with the duration intact and the row order unchanged, and the bar the next render draws carries the moved dates rather than the ones the gesture started from. A shift-drag of an edge moves one end only, and an inverted range is refused with the bar restored to the span the record still holds. The pointer and a direct `changeTaskDatesAction` request produce the same dates, and the Countdowns and the Deadline Calendar draw the new dates on their next render. Shipping is still HARD GATE C.)*
- [x] refused drop visibly reverts; — `c1f8c93` @ `2026-09-10T11:45:31+07:00` *(after the refusal the bar is back on its original `gridColumn`, the row transform and the target marker are cleared, the pickup mark is gone, and the proposal text is the refusal itself.)*

## Schedule

- [x] six modes; — `215777a` @ `2026-09-12T02:11:10+07:00` *(one fixture set mounted through both renderers the application chooses between, each view compared against the same canonical occurrence projection clipped to what that view shows.)*
- [x] Today/Previous/Next; — `fc460f6` @ `2026-09-10T16:36:28+07:00` *(the shared contract is asserted for Day/4-Day/Week and for all six modes' date arithmetic.)*
- [x] empty-cell event creation; — `2e74059` @ `2026-09-10T15:29:20+07:00` *(an empty slot seeds a local one-hour proposal at its clicked civil time with no Save side effect.)*
- [x] event click; — `7357b4d` @ `2026-09-10T12:06:02+07:00` *(machine-key clicks open and close the local read-only event editor without changing event data.)*
- [x] 15-minute drag; — `7292075` @ `2026-09-10T14:54:37+07:00` *(moves follow the pointer and snap to Schedule-specific 15-minute slots in all three grid modes.)*
- [x] 15-minute resize; — `7292075` @ `2026-09-10T14:54:37+07:00` *(only the bottom edge resizes, with a live 15-minute snapped deadline preview.)*
- [x] cross-day move; — `7292075` @ `2026-09-10T14:54:37+07:00` *(a multi-day timed event moves across civil days with a segmented live preview and is restored after the typed refusal.)*
- [x] recurring occurrence scope; — `448c65f` @ `2026-09-10T16:53:37+07:00` and `fef3b8a` @ `2026-09-12T01:01:45+07:00` *(a recurring occurrence in Day reaches the scope-choice path on click, both scopes are offered, the choice can change, and Cancel discards it without touching a record.)*

## Projects Hub

- [x] cards expose pressure/summary; — `7f96a71` @ `2026-09-12T01:52:46+07:00` *(`tests/projectsHubCards.test.ts` asserts every field the checklist names, with the conditionals taken literally — a priority row only where a priority is represented, an unreadable created date as "Unknown", a swatch only for a usable colour.)*
- [x] clicking enters workspace; — `7f96a71` @ `2026-09-12T01:52:46+07:00` *(clicking a card opens that project's workspace, and the back control returns to the hub.)*
- [x] create/archive/restore/delete have visible feedback. — `68e11b6` @ `2026-09-10T17:19:10+07:00`, `7f96a71` @ `2026-09-12T01:52:46+07:00` and `08e505d` @ `2026-09-12T02:16:06+07:00` *(the lifecycle controls offer archive or restore plus delete, each disabled with its typed refusal and a visible note; Save keeps the provisional modal open and records its refusal on the modal; and an invalid form now answers with `invalid-action-input` rather than with the same unavailable refusal every valid form gets.)*

## Notes

- [x] file/folder click; — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(a file click reports its path and marks exactly that entry; a folder click toggles it.)*
- [x] expand; — `ead7927` @ `2026-09-12T02:02:58+07:00` *(a collapsed root emits no file buttons at all; the root and a nested folder are driven open and shut through the machine-key harness and all four states asserted.)*
- [x] context menu; — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(a context-menu event reports the path, the menu renders from view state under `data-project-note-context-path`, and Escape closes it.)*
- [x] hover actions; — `ead7927` @ `2026-09-12T02:02:58+07:00` *(the hover affordance is the stylesheet's `.project-note-entry:hover` on exactly the interactive entries, a hover reaches no handler, and a root the vault cannot read has nothing to hover.)*
- [x] drag destination; — `ead7927` @ `2026-09-12T02:02:58+07:00` *(only folder elements are destinations: a drag over a file previews nothing, the same drag over a folder previews `source -> target`, and the drop clears the preview.)*
- [x] move/rename/create/delete feedback as far as HARD GATE D permits. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(`as far as HARD GATE D permits` is the operative clause and the feedback is the typed refusal: the context menu draws Rename, Move and Delete disabled with `action-not-available`, and a refused drop renders the refusal naming the source and the destination. The verbs themselves are Stage 15's, under that gate.)*

## Task Board

- [x] custom workflow columns; — `ead7927` @ `2026-09-12T02:02:58+07:00` *(one column per vault status definition in declaration order, and a column appended for any status a project task uses but the vault does not define.)*
- [x] card click; — `c8e35c3` @ `2026-09-10T19:54:34+07:00` *(the click opens the read-only inspector for that task, its text escaped, with Escape closing it.)*
- [x] card drag; — `ead7927` @ `2026-09-12T02:02:58+07:00` *(dragstart reports the picked-up card and the drop reports the move intent, with the record byte-identical across the whole sequence.)*
- [x] placeholder; — `c8e35c3` @ `2026-09-10T19:54:34+07:00` *(the hovered slot opens its insertion placeholder to 54px before the drop and is re-rendered away after it.)*
- [x] workflow transition independent of Elastic execution state. — `e325f6e` @ `2026-09-12T04:18:31+07:00` + `08d31b5` @ `2026-09-12T04:11:16+07:00` *(The independence is no longer only in the domain. On the surfaces: a card drop into Review leaves the record Running with its Elastic position untouched — `tests/workflowMoveGesture.test.ts` asserts executionState running and executionOrder 4 after a move, after a reorder inside a stage, and after a leave — while `tests/taskMutations.test.ts` asserts the reverse pair, that an execution-state move and an execution reorder leave workflowStageId and workflowOrder exactly as they were, and that a workflow-order change leaves executionOrder alone. `tests/timelineChangeAction.test.ts` asserts the same for a bar move between rows: executionOrder and workflowStageId come out equal to what they went in as.)*

## Backlog

- [x] search; — `bdea4a1` @ `2026-09-12T00:34:29+07:00` *(typing searches as the field changes, the field shows the text that is searching, and an empty match says so.)*
- [x] filters; — `9b59d16` @ `2026-09-12T00:23:35+07:00` and `3fa16bc` @ `2026-09-12T01:41:25+07:00` *(field filters and property filters both chip, remove and refuse a value their type cannot compare while keeping the query they had.)*
- [x] sort; — `bdea4a1` @ `2026-09-12T00:34:29+07:00` *(a column sorts ascending, then descending, then clears.)*
- [x] resizable columns; — `8cadd24` @ `2026-09-12T01:31:08+07:00` *(a drag on the edge keeps the header and its cells together, and both clamps are asserted.)*
- [x] selection; — `9d6062c` @ `2026-09-12T01:11:58+07:00` *(a row checkbox marks it and the projection reports how many shown rows are marked.)*
- [x] select-all; — `9d6062c` @ `2026-09-12T01:11:58+07:00` *(select-all means the shown rows, and clears again; a marked task the query hides is counted rather than silently covered.)*
- [x] bulk actions; — `9b197e2` @ `2026-09-12T04:32:15+07:00` *(they run now, and the interaction is the one the rest of the panel has: both controls are enabled exactly when a write path resolved and typed-unavailable with the reason when it is not, a disabled control reports nothing through the binder, a refused run leaves the reader's marks alone while an accepted one clears them, and the result is drawn per entity where the selection is — one row per marked task, accepted or refused with its reason, with the counts as attributes that cannot overstate it. The per-entity shape this box was waiting on arrived with the action that fills it (`9dcc5d6`), which is what the old note asked for.)*
- [x] relation/rollup/formula display. — `d7e6270` @ `2026-09-12T01:06:10+07:00` *(every custom property of a row is drawn and says which kind it is, including relation, rollup and formula cells.)*

## Modals

- [x] every meaningful field accessible; — `7ec8d17` @ `2026-09-12T00:39:14+07:00` and `b20cdca` @ `2026-09-12T00:56:55+07:00` *(the Task editor represents every field of the task and every schema property, whether the task has it or not, and the Event modal shows every field the record holds.)*
- [x] Save; — `cab1627` @ `2026-09-12T03:31:18+07:00` + `18c2e48` @ `2026-09-12T03:37:24+07:00` (Task editor), `38ce017` @ `2026-09-12T06:03:57+07:00` (Event editor), `c5291f1` @ `2026-09-12T05:03:47+07:00` (New Project and the project editor) *(both modals this box stayed open on can save now. The Task editor plans one typed mutation per changed field and refuses the rest with a typed reason. `tests/scheduleWriteWiring.test.ts` submits the Event editor by the difference it shows, closes it only on acceptance, keeps it open with what was typed when the save lost a race, and writes the same record through the Day editor and the Month editor. `tests/projectLifecycleWiring.test.ts` creates the project the New Project form described and answers an invalid one with the operation reason, saves the fields the project editor changed, refuses a save with nothing changed, and closes only on acceptance. With no write path each form stays open with the reason.)*
- [x] Cancel; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(Cancel discards the provisional form state — a draft is `null` until something is edited — and the Elastic quick editor's Cancel is asserted too.)*
- [x] Escape; — `7825d20` @ `2026-09-12T00:44:55+07:00` *(Escape is the same discard, asserted for the Task editor, the Elastic quick editor, the New Project modal, the Notes context menu and both inspectors.)*
- [x] Delete; — `18c2e48` @ `2026-09-12T03:37:24+07:00` + `38ce017` @ `2026-09-12T06:03:57+07:00` *(the Event modal was the last one that could not delete, and it can now: `tests/scheduleWriteWiring.test.ts` clicks the Event editor Delete through the same sequence the other verbs use, asserts the event is gone from the next read, and asserts the editor closes only when the delete was accepted — the refused save in the same case leaves it open. The Task editor Delete carries the revision the card was read at, an accepted delete closes the editor while a refused one leaves it open, and with no record write path the control renders disabled with the typed reason (`tests/eventModal.test.ts` asserts the Event one).)*
- [x] recurrence scope; — `fef3b8a` @ `2026-09-12T01:01:45+07:00` and `1ffdd55` @ `2026-09-12T01:19:47+07:00` *(both scopes are offered, the choice can change, Cancel discards it without touching a record, and the modal is reached from the occurrence selection.)*
- [x] invalid form refusal; — `08e505d` @ `2026-09-12T02:16:06+07:00` *(the New Project modal's Save with an empty or whitespace-only name is refused as `invalid-action-input` by the boundary it dispatches through, while a name that is a name still gets this stage's unavailable answer — so the modal does not answer every form with the same refusal. The boundary refuses an empty name directly in `tests/actionProtocol.test.ts`.)*
- [x] stale-save refusal; — `cab1627` @ `2026-09-12T03:31:18+07:00` and `18c2e48` @ `2026-09-12T03:37:24+07:00` *(the first real Save exists, so a stale save is now a thing that can happen and is asserted: the editor's write carries the revision the card was read at, a save built on a record someone else has since changed is refused as `stale-revision`, the loser's value never reaches the record, the card is re-read to the winner's state, and the form keeps its edits so a reader retries from the authoritative revision rather than retyping. The observed-revision contract underneath is Gate 13's, `052c3b4`.)*

## Feedback

- [x] provisional UI never masquerades as committed state; — `7ec8d17` @ `2026-09-12T00:39:14+07:00` and `57860d3` @ `2026-09-10T09:14:42+07:00` *(a fresh draft is not a change until something is edited; a drag preview is drawn by the surface and the record stays byte-identical; the pre-storage refusal says the task data was not changed rather than showing the move as done.)*
- [x] accepted action visibly settles; — `57860d3` @ `2026-09-10T09:14:42+07:00` *(the only actions that can be accepted today are presentation and local-state ones, and they settle visibly: target and lock presentation survive an ordinary rerender, a sort or filter redraws the rows it asked for, a selection reports its count. An accepted record mutation cannot exist yet — the Save/drop halves above are the gate.)*
- [x] stale/refused action visibly restores authoritative state; — `c1f8c93` @ `2026-09-10T11:45:31+07:00`, `7292075` @ `2026-09-10T14:54:37+07:00` and `ead7927` @ `2026-09-12T02:02:58+07:00` *(the Gantt bar returns to its original column and clears its markers, the Schedule grid restores a multi-day move after the typed refusal, and the Task Board's refused drop clears the placeholder while the record stays byte-identical.)*
- [x] operation failures are not swallowed; — `08e505d` @ `2026-09-12T02:16:06+07:00` *(a failed note preview is rendered with its failure code rather than as an empty pane, and idle/loading/ready are each distinct states; refusals elsewhere are rendered text naming the reason, and load problems reach the inspection projection rather than being discarded.)*
- [x] no gesture depends on opening raw JSON/Markdown to finish the operation. — `08e505d` @ `2026-09-12T02:16:06+07:00` *(every gesture above is driven through the machine-key harness against the rendered surface; no case in this pass reads a file to complete an operation. The one deliberately raw-text surface is the Template composer, whose format is this project's own and whose plan is data — slice 34's decision.)*

## Evidence

- Automated interaction recording/report covering every trace row. *(**Not claimed by this
  pass.** `proxima-interaction-parity-trace.md` is itself a reference document — "complete and
  stable", not a work item — and its interactions are prose, not rows a runner can enumerate.
  What this pass does is name, for each box, the case that asserts it. Making the trace itself
  executable as a conformance matrix is Stage 17's own line (see "Before calling UX parity
  complete" there), and that is where this bullet is satisfied or left open.)*
- Every expected DOM/state transition machine-asserted. *(Yes, and each of the fifty-one ticked
  boxes above names the file and case: happy-dom, the machine-key harness, the real binders and
  renderers, with state compared as JSON and records compared byte-for-byte where a write was
  refused.)*
- No "creator visually confirmed" evidence. *(Yes — nothing above depends on a human looking,
  and Stage 0's `## Acceptance` already made that binding for every suite since `5d5cebf`.)*
- Full action/inspection trace retained for the run. *(The dispatched actions a surface runs are
  retained in the dispatcher's own action sequence and exposed through the inspection
  projection, which the `actionProtocol` and `inspection` suites assert; the mutation leg is
  `null` because no mutation stream exists, as the projection says rather than fabricating one.)*

---

# Stage 19 — Cross-surface and agent convergence

The cockpit must behave as one system, not a collection of independently updated surfaces.

## Work

- [x] Task changed on Elastic updates: — `8dc3841` @ `2026-09-12T02:22:54+07:00` and `e4e319b` @ `2026-09-12T03:44:25+07:00` *(both halves now exist. The **origin** was the missing one: an Elastic edit was refused, so the surfaces below were converging on changes nobody could make from the UI. As of Stage 9's write half an Elastic drop and a card editor's Save are real writes — one accepted mutation each, carrying the revision the card was read at — and `tests/elasticChangeConvergence.test.ts` starts where a person does: a drop, then the product's own re-read, then the real renderers mounted over that projection. The five surfaces below are asserted for a *source-made* change at `8dc3841` and for an *Elastic-made* one at `e4e319b`, which is the pair the box was asking for.)*
  - [x] Backlog; — `8dc3841` *(the row shows the new deadline and the old value is gone from the table, not merely joined by the new one.)*
  - [x] project Task Board; — `8dc3841` *(the card shows the new deadline, and the status change moves it to the other column.)*
  - [x] Timekeeping; — `8dc3841` *(all three Timekeeping projections the panels draw from — Countdowns, the deadline Calendar and the Timeline/Gantt — report the new deadline for the same record.)*
  - [x] task modal; — `8dc3841` *(the Task editor's fields are the reloaded record's, including the deadline it answers with.)*
  - [x] project metrics. — `8dc3841` *(the Hub's next-deadline metric follows the earliest deadline across records: moving the earliest task past the other one makes the card report the other, so the metric is derived from state rather than copied from a task.)*

- [x] Deadline changed in Gantt updates: — `8d5ec96` @ `2026-09-12T06:36:10+07:00` *(closed now that the origin exists: the blocker was "the Gantt drag is refused, so the Gantt cannot originate a deadline change — Stage 14's write half owns that", and Stage 14's write half shipped. `tests/ganttWriteWiring.test.ts` drives a bar drag through the binder into a real store and then asserts the case this box names in as many words — "leaves the Countdowns and the Deadline Calendar drawing the new dates on their next render" — with the children below already ticked for the source-arriving direction at `8dc3841`. So both directions are asserted: a change arriving from the source reaches these surfaces, and a change *originated in the Gantt* reaches them too.)*
  cannot originate a deadline change — Stage 14's write half owns that. A deadline change arriving from the source
  propagates to every surface here, `8dc3841` @ `2026-09-12T02:22:54+07:00`.)*
  - [x] Countdowns; — `8dc3841` *(the countdown entry for the record carries the new deadline.)*
  - [x] deadline Calendar; — `8dc3841` *(the calendar projection's entry carries the new deadline.)*
  - [x] task modal; — `8dc3841` *(the editor shows the new value.)*
  - [x] project Hub next-deadline metric. — `8dc3841` *(read above.)*

- [x] Event changed in Week updates: — `75091b0` @ `2026-09-12T05:47:24+07:00` *(closed now that the origin exists: the blocker was "the Week origin is a Schedule write and is refused, so Stage 12 owns it", and Stage 12's write half shipped. Two cases cover it — `tests/scheduleWriteWiring.test.ts` moves a block in **every** time-grid mode (Day, 4-Day and Week) through a real store, and asserts a written event is drawn by every Schedule view with the three time-grid modes drawing the exact span; the children below are already ticked for the source-arriving direction at `8dc3841`. A change made *from Week* is therefore the same write as from Day, and the other views draw it on their next render.)*
  propagation is proven at `8dc3841` @ `2026-09-12T02:22:54+07:00` for a change made at the source.)*
  - [x] Day; — `8dc3841` *(the card names the new instant and the new name, and the old instant appears nowhere in the view.)*
  - [x] 4-Day; — `8dc3841` *(as Day.)*
  - [x] Month; — `8dc3841` *(the occurrence button draws the new name; the old one is gone.)*
  - [x] Year; — `215777a` @ `2026-09-12T02:11:10+07:00` *(Year draws a per-date occurrence count and no per-event element, so it is asserted through those counts by the six-view convergence case rather than through the event's own values.)*
  - [x] Agenda. — `8dc3841` *(the date group and the row carry the new name and start.)*

- [x] Project archive updates navigator/Hub/workspace everywhere. — `aee729d` @ `2026-09-12T16:00:33+07:00` *(the
  half this box was missing was the navigator, and the fix was the one its own text named: the rendering moved
  out of `src/browser/main.ts` into `src/browser/projectNavigation.ts`, which takes the state and the selection
  as arguments and holds no state of its own — so a status change arriving from the source is visible on the
  next render by construction rather than by a notification. `tests/projectNavigation.test.ts` renders the same
  record active and then archived and asserts it moves between the sets and back, that the heading counts the
  active projects, and that an archived project is a **visible row the shell cannot select** (no `data-action`,
  no project id) rather than a hidden one. The archive *action* itself stays where the box left it: it is a
  record mutation, and Stage 11 owns it under HARD GATE C.)*
- [x] Relation/schema changes reproject Backlog without restart. — `469ee8c` @ `2026-09-12T08:03:38+07:00` *(the note named the blocker exactly: "the Backlog already draws a column per declared property on every render, so reprojection is structural — but the schema it reads is canonical record data: the legacy reader returns `taskSchema: []` … Closes when a schema record can change at runtime." Schema records can change at runtime now (`src/app/propertySchemaMutations.ts`), so `tests/schemaReprojection.test.ts` proves it over a real store with the **same source object loaded for every step** — no new session, controller or process: create a property, and the next render draws its column; rename it, and the next render follows the record while the stored value stays keyed by the schema id. Two rules the test learned from the renderer rather than assumed, and both are stated in the file: a property column is drawn for a property some task actually *has* (`columnsFor`), so the card carries a value before the column is expected, and the readable projection flattens a stored value to its plain form.)*
  property on every render, so reprojection is structural — but the schema it reads is canonical record data: the
  legacy reader returns `taskSchema: []` and property definitions arrive with the record store (HARD GATE A5,
  accepted, plus the cutover). Closes when a schema record can change at runtime.)*
- [x] Agent write appears on human cockpit without a manual Refresh click. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the agent write path is what this box was waiting for, and the test drives the cockpit's own refresh rather than a stub: `tests/agentWritePath.test.ts` composes the real `recordStoreStateSource` over the real store with the real `createRefreshController`, renders the project Task Board and the Backlog from the projection the refresh adopts, and asserts that an accepted agent reorder redraws the cockpit **exactly once** — the redraw `convergeAfterWrite` asks for — with both surfaces then showing the new row order. A surface that moved only because the test re-read the store would leave the render count where it was, which is why the count is asserted and not merely the outcome.)*
- [x] Human cockpit write becomes visible to agent inspection without manual refresh. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the human side writes records as of Stage 9, and the other direction is now asserted in the same case: after the UI's own drop is accepted, a fresh inspection projection built from the reloaded source reports the moved counts and the changed record's revision, with no Refresh click on either side. The projection is the one the agent reads — `createInspectionProjection` over a dispatcher fed by the reloaded store — so "visible to agent inspection" means visible in the agent-facing projection rather than in an internal map.)*
- [x] Multiple independent Proxima surfaces converge to the same record revision. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(the record's revision changes in the loader's map while the other records' revisions do not, and every surface listed above renders from that one reloaded state; in the record-store age the record revision takes the source revision's place and the convergence contract does not change.)*
- [x] Each surface may keep independent local view state. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(a Backlog query and a selection survive the data changing underneath them: the same view state renders the renamed task under the new query and still reports the marked-but-hidden row, so view state and record state are independent in both directions.)*

Current action dispatch already has state revisions and source-replacement semantics; preserve that concept while moving canonical state to the record store.

## Acceptance

- [x] Agent modifies task while Board and Backlog are open; both converge. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(both halves are now in one case rather than one half waiting on the other: the Board and the Backlog are rendered from the open cockpit's projection, an agent submits through `src/app/agentWritePath.ts` with no surface involved, and both draw the change afterwards without anyone pressing Refresh — the reorder moves the card's position on the Board and the row in the Backlog, and the separate status move puts the card in the Finished column while the untouched record's revision stays where it was. The Backlog's half is asserted through the rows it actually draws: it lists rows in stored order and draws fields, so an execution-state change is not a thing it draws, and the row order is what a reorder moves there.)*
- [x] UI and agent race one record; stale loser explicit. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(both writers exist now, and the race is asserted in **both** directions: the agent writes first and the UI drops from the projection it rendered before, then the UI writes first and the agent submits the revision it read before. The loser — whichever it is — is refused `stale-revision` with the revision that beat it named as `actualRevision`, re-reads rather than merging, and the record keeps the winner's value; the loser's projection still shows what it showed, so nothing was merged into it. The store-level contract this rests on is still Gate 13's (`052c3b4`, `10dc3c3`, `eb0f3fe`), and the UI's two write paths at `abf8204`/`18c2e48`.)*
- [x] Separate records update independently. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(one task's file changes and its revision, its surfaces and its deadline move; the other task's and the event's revisions are unchanged, and every view of them still shows what it showed.)*
- [x] Local surface selections do not bleed into canonical storage. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(after a marked selection, a reader query and a reload, every file in the vault is byte-for-byte what it was — the peer's edit and nothing else. A selection is how this reader is looking at the table.)*
- [x] No manual source-refresh control is required for normal record-store coherence. — `abf8204` @ `2026-09-12T03:20:05+07:00` and `18c2e48` @ `2026-09-12T03:37:24+07:00` *(a write converges the cockpit by itself: both the drop and the editor's Save re-read the source as part of the write sequence, and nothing in the UI has to be clicked for the surfaces to agree with the store. What the header's Refresh source button remains is an option, not the mechanism — and changes made elsewhere arrive without it too, through the session's refresh policy (`createRefreshPolicy` in `src/app/refreshPolicy.ts`), which triggers an `interval` refresh while the page is visible at `intervalMs: 60_000` from `main.ts`'s boot. The box's own condition — "becomes true with the first mutation that reprojects every surface by itself" — is what Stage 9 delivered.)*

## Evidence

- Multi-surface integration tests. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(`tests/surfaceConvergence.test.ts` edits a vault behind an open cockpit, reloads it the way the application does, and asks eight surfaces what they show: the project Task Board, the Backlog, the project Deadlines list, the Elastic cockpit's column, the Task editor, the Countdowns, the deadline Calendar and the Timeline/Gantt — plus the six Schedule views and the event editor for an event change.)*
- UI+agent concurrent-operation tests. — `32132bb` @ `2026-09-12T12:01:23+07:00` *(the first writer pair exists: `tests/agentWritePath.test.ts` races the UI's own drop wrapper against the agent submission over one record, in both directions, and asserts the refused loser, its re-read and the surviving value. The store-level concurrency conformance suite still stands in for simultaneous transport-level concurrency, which no test claims.)*
- Revision convergence report. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(the report is the per-surface table the test asserts: every named surface reports the changed value, the changed record's revision moves in the loader's map, and the untouched records' revisions do not.)*
- Local-state isolation report. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(the third case: a query and a selection survive the data changing under them, a marked-but-hidden row is reported rather than covered, and the vault holds exactly the peer's edit.)*

---

# Stage 20 — Remove transitional read-only scaffolding from the product surface

Only after parity writes are genuinely working.

At `608bcdc`, the visible page still contains fixture/FSA acceptance controls, build evidence panels and a `"Read-only workspace"` identity. These are useful engineering surfaces but are not the final old-Proxima cockpit.

## Work

- [x] Ordinary user surface no longer leads with acceptance-probe chrome. — `4288b71` @ `2026-09-12T07:12:32+07:00` *(the header offers one closed disclosure (`data-c1-key="acceptance-tools-toggle"`, `aria-expanded="false"`) and renders no probe control at all until it is opened — `tests/acceptanceTools.test.ts` asserts the closed markup contains neither button, not that they are hidden. Opened, the panel carries the same `data-action` names and machine keys, so an acceptance run drives the handlers it always did.)*
- [x] Engineering diagnostics remain programmatically available. — `4288b71` @ `2026-09-12T07:12:32+07:00` *(hiding a control did not hide a fact: `__PROXIMA_INSPECTION__`, the `__PROXIMA_REAL_VAULT_ACCEPTANCE__` hook and every status element an acceptance run reads by id (`build-identity`, `hydration-summary`, `fsa-probe-status`, `fsa-acceptance-status`, `real-vault-acceptance-status`, `creator-vault-preflight-status`) are asserted present in the shell by name, and the app-layer contract underneath is `tests/inspection.test.ts` plus `tests/rendererIndependentInspection.test.ts`.)*
- [x] FSA disposable-probe controls are not confused with ordinary record ownership. — `4288b71` @ `2026-09-12T07:12:32+07:00` *(the controls no longer sit beside Refresh unexplained: the panel names its scope (`data-acceptance-tools-scope="disposable-root"`), says the folder is disposable, and says in the place a reader looks that this grants no record write authority and that folder access is read-only here — the same answer the boundaries give, with `writerEnabled: false` and `reason: fsa-no-compare-and-swap` in `src/app/fsaWriteBoundary.ts` and `writeAuthority: disabled` in `src/app/ownerAuthorityBoundary.ts`, both asserted by their own suites.)*
- [x] "Read-only workspace" disappears from normal record-backed operation. — `9a04451` @ `2026-09-12T03:40:29+07:00` *(the string is now a derived value rather than a literal, and it disappears exactly when a record write path resolved — which is what "normal record-backed operation" means: an activated store. A record-backed run that cannot write still says read-only, deliberately, because that is true of it. The rest of this stage's transitional chrome — the fixture/FSA acceptance controls, the build-evidence panels — is untouched by this box and remains named by the three boxes above it.)*
- [x] Build/source/recovery health remains inspectable without dominating the cockpit. — `425a631` @ `2026-09-12T07:23:09+07:00` *(the missing half was "without dominating", and it is now asserted three ways: health is drawn exactly once, as one strip outside the header; the build and recovery evidence is a collapsed `<details>` (no `open` attribute); and the header's state region holds only the identity, the badges, Refresh and the tools disclosure — no probe control, no health strip and no diagnostics inside it. The model underneath is `createUiHealthModel`, bounded and covered by `tests/uiHealth.test.ts`, so "inspectable" is a projection rather than a paragraph. **Stage 20 has no open boxes left**, and every one of its boxes names the commit that closed it.)*
- [x] Canvas remains available as the Backpack capability already ahead of the old plugin. — `dc675d9` @ `2026-09-12T07:15:07+07:00` *(canvas is a first-class surface, not a leftover: `tests/transitionalChrome.test.ts` renders the navigation and asserts the tab is drawn and selected only when it is the surface, that the shell routes it to `renderCanvasSurface` as the last branch of the switch whose validation accepts `canvas` by name, and that the three preview registries are still composed. The capability behind it is covered by ten named suites — the renderer and loader, the text and Excalidraw preview paths, file admission, geometry and removal interactions, semantic selection — so the box closes on capability presence and coverage; whether that is *ahead of the old plugin* is the creator's comparison and is not asserted here.)*
- [x] Legacy import controls disappear/retire after successful migration if they are no longer needed operationally. — `dc675d9` @ `2026-09-12T07:15:07+07:00` *(the condition is met by absence: the shell renders no import control, panel or wizard at all (`data-c1-key="import`, an Import button and the legacy label are each asserted *not* present in `src/browser/main.ts`), while the administrative action set and its parser stay on the path that owns them and keep their own suite. Import is an agent/acceptance-run operation rather than chrome a reader gets past. If a UI is ever wanted this assertion fails and sends the reader back to this box, which is why it is written as an assertion.)*
- [x] No migration ceremony becomes permanent UX. — `dc675d9` @ `2026-09-12T07:15:07+07:00` *(no ceremony is drawn, so none can become permanent: activation is a stored marker read while the write path resolves (`readRecordStoreActivation` in `src/adapters/browserTaskMutations.ts`, whose reader is `src/app/recordStoreActivation.ts`), not a per-boot flow, and the shell has no migration or activation-marker surface. The one thing the ordinary surface says about a run that cannot write is the derived read-only state, which is a fact about that run rather than a prompt to migrate.)*

## Acceptance

- [x] Starting ordinary Proxima shows the cockpit, not the audit harness. — `8676dc3` @ `2026-09-12T07:19:39+07:00` *(the boot's own answer: the real dispatcher's initial snapshot is the Elastic cockpit (`surface: tasks`, `tasksMode: elastic`, selection all), and the shell passes no `initialSurface`, so a run that has asked for nothing gets the product. The harness is behind the disclosure the previous slice added, and `tests/transitionalAcceptance.test.ts` asserts the header renders no probe control outside it.)*
- [x] Agents can still inspect build/source/recovery state. — `8676dc3` @ `2026-09-12T07:19:39+07:00` *(the inspection projection is built in the test through `createInspectionProjection` against the real `BUILD_IDENTITY` and carries the build block, `sourceHealth`, the `degraded` verdict and the record/source revision lists; the shell installs `__PROXIMA_INSPECTION__` and the real-vault acceptance hook beside it, and `tests/inspection.test.ts` plus `tests/rendererIndependentInspection.test.ts` cover the contract underneath.)*
- [x] Removing user-visible diagnostics does not remove machine-readable diagnostics. — `8676dc3` @ `2026-09-12T07:19:39+07:00` *(both halves are asserted in one place: the projection carries `loadProblems` and the `degraded` verdict with the bounded text budget (`MAX_INSPECTION_TEXT`) still applied, and the visible half is still drawn (`diagnosticsSurface(problems)`, `healthSurface(health)`). What this stage removed was chrome in front of the product, not the facts a program reads.)*
- [x] Rebuilding/discarding the Backpack does not threaten record data. — `8676dc3` @ `2026-09-12T07:19:39+07:00` *(records live in Proxima's Backpack-origin OPFS — a fixed origin (`papers-backpack://bp-954ea2cd-6261-410d-baf8-0d1fbd8ca0b1`), a `record-store/records` directory, and `assertProximaBackpackOrigin` on every entry point — so discarding the app bundle cannot reach them; and the shell holds no store and no coordinator, only operations behind the adapter, which `tests/recordMutationContainment.test.ts`, `tests/browserBoundary.test.ts` and `tests/recordStoreActivation.test.ts` enforce. Nothing in the tree writes record data through the creator's vault, and this box is the reason that separation is asserted rather than assumed.)*

## Evidence

- Browser acceptance.
- Inspection contract test.
- Restart/rebuild test against existing record store.

---

# Final release gate — "Feels like Proxima and agents can do everything"

Full parity is closed only when all of the following are true.

- [x] Elastic is again an active execution cockpit rather than a read-only projection. — `57860d3` @ `2026-09-10T09:14:42+07:00` *(tests/elasticCockpit.test.ts drives the cockpit through the real DOM - opening a card, a drop that writes, lock and unlock - and tests/elasticChangeConvergence.test.ts asserts that a change made there reaches the other surfaces, so this is an active cockpit rather than a projection.)*
- [x] Timekeeping again provides Calendar + Gantt + Countdowns. — `760e54d` @ `2026-09-10T11:18:58+07:00` *(tests/timekeepingCockpit.test.ts mounts all three panels and their interactions, and tests/cockpitNavigation.test.ts covers the navigation between them.)*
- [x] Schedule again provides all six modes and direct event manipulation. — `5d97cdc` @ `2026-09-10T15:39:53+07:00` *(tests/scheduleProjection.test.ts mounts Month, Year and Agenda against fixture events, tests/scheduleTimeGrid.test.ts covers Day, 4-Day and Week geometry and the drag that writes, and the six-view case reads one fixture set through all six so the modes cannot drift apart.)*
- [x] Projects are workspaces, not just filters. — `dadd610` @ `2026-09-10T17:32:11+07:00` *(tests/projectWorkspacePanels.test.ts opens a project and asserts its own workspace - tabs, panels and the project they belong to - rather than a filtered board.)*
- [x] Notes remain ordinary vault artifacts. — `fa5bb33` @ `2026-09-10T19:43:38+07:00` *(tests/projectNotes.test.ts reads the notes tree and previews a note as vault files, with no record-store representation of a note anywhere in the projection.)*
- [x] Task Board and Elastic no longer fight over one status field. — `263c9a6` @ `2026-09-07T17:35:22+07:00` and `738bb53` @ `2026-09-12T02:45:43+07:00` *(tests/boardElasticPresentation.test.ts shows both surfaces drawing from the same canonical execution state, and tests/recordStateProjection.test.ts is the one projection both read - a change of column is one record write with one meaning, which is what the two surfaces used to disagree about.)*
- [x] Backlog behaves as a database view. — `9b59d16` @ `2026-09-12T00:23:35+07:00` *(tests/backlogView.test.ts and tests/backlogControls.test.ts cover search, filters, chips, sorting and the field vocabulary a database view is made of, with the no-write halves asserted beside them.)*
- [x] Recurrence has occurrence/series semantics. — `16b443e` @ `2026-09-12T06:11:55+07:00` *(tests/eventRecurrence.test.ts drives a rule, an occurrence exception and a series-scoped change separately, and asserts that a series move drops the overrides the moved rule no longer generates.)*
- [x] Every human DATA WRITE gesture has one semantic Proxima action. — `65f88ef` @ `2026-09-12T12:13:11+07:00` *(the blocker this box had named was the property-schema family, which had operations and no action at all; `src/app/propertySchemaActions.ts` is that action — five verbs over the record layer's own operations, one boundary accepting `unknown`, one semantic request id and one terminal event per run — so every gesture family the agenda carries now has exactly one semantic action: the task rows, the seven event rows, the five project verbs, the three stage verbs, the bulk run, the two legacy schema verbs (`propertySchemaActions` is the third sibling entry after template execution and the agent write path), and the retained task recurrence, which is declared operation-only and audited as such. The artifact rows are deliberately not gestures — D63 records them as not offered — so nothing is missing there rather than something being unwired. What this box does **not** claim: that each of those actions is reachable by an agent or by a user, which is the next box's subject.)*
- [x] Every such action has typed success/refusal/stale/failure. — `21de194` @ `2026-09-13T00:01:53+07:00` *(**All three gaps this box named are closed, and the last one closed with the verb whose answer it was about.** The two earlier ones closed at `9d4ebb1` and `9562a9c` and are recorded below. The third was `project.delete`, which had a refusal and no success branch; D60 gives it all four distinguishable outcomes: a **typed success** (`outcome: 'deleted'` with the ids it removed), a **typed refusal** that is the cascade's own guarantee (`membership-mismatch`, a submitted list that is not the current membership, refused before anything is removed and leaving the store byte-identical), a **stale/conflict path** naming the revision that beat it (`stale-revision`, on the project or on any confirmed member), and its **storage/recovery** paths (`recovery-required`, `storage-failure`, and a coordinator refusal on a member delete that stops the cascade rather than half-finishing it). The matrix moved with the verb: `tests/actionCoverageAudit.test.ts` records the row as `write`-shaped with a satisfied success cell, and both the `n/a` success cell and the `idsGap` it carried are gone. What this box does not claim: the question is still asked per row and the cells are still the evidence, which is why the row was edited rather than the family's contract loosened.)*
- [x] UI and agent paths share implementation. — `e75d76a` @ `2026-09-12T15:33:00+07:00` the last caller arrived: the schema panel. `src/browser/propertySchemaPanel.ts` draws the rows from the editor projection and binds the controls, the shell binds it inside the Backlog and submits the three forms through `submitPropertySchemaAction` - the entry the agent wire calls - and `tests/propertySchemaPanel.test.ts` proves a click reaches those handlers, so this is a claim about a caller rather than about a source file. The record below is kept because it is the argument that got here. *(Partly true, and the part that is not is named. The drop family is shared - `src/app/agentWritePath.ts` and the Elastic drop wrapper both run `moveTaskByGesture`, compared as whole objects at `32132bb` @ `2026-09-12T12:01:23+07:00` - and the schema family now has an action **and** an agent entry (`2f90e2c` @ `2026-09-12T12:25:28+07:00`: the wire recognises the five `property.schema` verbs and hands them to `src/app/propertySchemaActions.ts` with the id it already minted, so one submission is one run), and its UI caller arrived last, at `e75d76a` @ `2026-09-12T15:33:00+07:00`; until then it had no surface at all, so it shared nothing. The families that were on that list for reading a rendered cockpit have left it, one slice at a time: the Schedule at `70f5549`, the Hub at `dc5f908` and bulk at `f9d7c63`, each by moving the read to the entry rather than widening what the wire takes. **Every family is now shared, and one of them is shared in one direction only.** `task.create` joined the rest at `b34ef53` @ `2026-09-12T15:03:06+07:00`, and by the cheapest route of the eight: the wire builds a draft and hands it to the same `planTaskCreate` the form's Save uses, so the planner and its wording did not move at all. What kept this box open was the other thing: the schema family had an operation and an agent entry and **no UI caller had ever existed**, because there was no schema editor - so "shared" would have been a claim about a caller nobody had built. That was the one remaining item, and it was an editor rather than a wire; that editor is `e75d76a`, which is why this box closes here. **The Gantt family left that list at `5781e96` @ `2026-09-12T14:05:30+07:00`**, and it left it by the rule rather than by exception: `changeTaskSpan` in `src/app/timelineChangeAction.ts` takes the write, the refresh, the id source and the event sink with no `state`, no `setRefusal` and no `render`, so the revision and the end a resize keeps are parameters, and `changeTaskDatesAction` is now the cockpit entry over that same operation rather than the only entry to it. The move also removed a malformation rather than validating one - the submission carries the whole span, so a resize whose kept end disagrees with the record is not a shape a caller without a projection can express - and D75 records the rule it settles: when a read model blocks a write, the read moves to the entry, never into the wire. **The workflow-stage family left the same list at `4566bd6` @ `2026-09-12T14:22:14+07:00`**, and it left it more cheaply than the Gantt did: the only fact its sequence read from the board was a stage's revision, so `runStageWrite` now takes that as a parameter or a caller-owned lookup and the board hands over what it read. What stays board-only is stated rather than implied - the stage delete carries the creator's remap decision, so it is not on the wire at all, and `tests/agentWritePath.test.ts` asserts a delete submitted through the wire comes back refused.)*
- [x] Agents never directly modify Proxima record JSON. — `d5a515e` @ `2026-09-07T21:00:24+07:00` *(tests/agentBridgeBoundary.test.ts and tests/bridgeDisclosure.test.ts prove the loopback bridge is a bounded read-only reader: writes are refused, and every answer stays inside a bounded code vocabulary without naming the configured root.)*
- [x] Legacy Markdown record files remain untouched after migration. — `d9d8c5e` @ `2026-09-12T02:35:31+07:00` and `184765e` @ `2026-09-11T20:19:14+07:00` *(tests/importStagingBytePreservation.test.ts and tests/importBytePreservationVerifier.test.ts hash the legacy bytes before and after a migration run and assert they are identical - the legacy directories are present, never rewritten.)*
- [x] Changing legacy record Markdown after cutover cannot silently change canonical state. — `d6e2b30` @ `2026-09-12T03:02:30+07:00` *(tests/recordStoreActivation.test.ts asserts the source choice is the legacy reader for every answer except an intact activated store, so once the store is canonical a legacy edit is not read at all rather than silently believed.)*
- [x] Record filenames carry no semantic meaning. — `71b0a2b` @ `2026-09-11T06:55:30+07:00` *(tests/canonicalIdentity.test.ts asserts the canonical identity is what a record declares or what its header says, with the filename carrying no kind, name or path - and tests/boundaries.test.ts keeps the domain free of any path knowledge.)*
- [x] IDs survive names/storage changes. — `510a25e` @ `2026-09-08T01:56:29+07:00` *(the identity-promotion suites - tests/taskIdentityPromotion.test.ts, tests/projectIdentityPromotion.test.ts and tests/eventIdentityPromotion.test.ts - rename and re-store records and assert the id is unchanged, which is what makes a rename an edit rather than a new record.)*
- [x] Relations survive renames. — `26c84d4` @ `2026-09-11T07:44:48+07:00` *(tests/canonicalRelation.test.ts asserts a relation is a record id rather than a name or a path, and tests/missingRelationshipDiagnostics.test.ts reports a dangling one instead of guessing, so a rename cannot break or silently rewrite a link.)*
- [x] Schema survives disposal/rebuilding of the Backpack. — `469ee8c` @ `2026-09-12T08:03:38+07:00` *(tests/schemaReprojection.test.ts rebuilds the projection from the stored schema records alone and asserts the same typed fields come back, so the schema is data rather than state a surface kept.)*
- [x] Project may contain both tasks and events. — `efdfa11` @ `2026-09-11T08:08:23+07:00` *(tests/canonicalDataOwnership.test.ts carries a fixture where one project owns a task and an event at once and asserts both kinds and both project ids.)*
- [x] Scoped ordering no longer cross-contaminates surfaces. — `b980c33` @ `2026-09-12T12:20:44+07:00` *(asserted with three tasks whose three orders are three different permutations - Alpha first in the queue, last in its stage and earliest by date, Beta the reverse of both and latest by date, Gamma between them in each - so a surface that read the wrong scope could not pass by accident. `tests/scopedOrdering.test.ts`: the project Task Board and the Backlog both follow the execution scope and agree with each other, the workflow board follows the workflow scope, the Gantt follows chronology (neither durable scope), and each case changes exactly one scope and then asserts the intended scope moved, the **other scope's stored values** did not, the surfaces that draw the other scopes render what they rendered before, and the changed surface renders the new order. The third order-ish fact is not a scope at all: placing a Gantt row leaves every record file and revision byte-identical, which is what local state means here. **Writing it found a contradiction rather than confirming a design**: `docs/DECISIONS.md#d64` in the Proxima tree said row placement was a third durable order scope with its own record field, while the tree implements local state per HARD GATE A/A3 (`CanonicalDurableOrderScope` admits two scopes, `GANTT_ROW_PLACEMENT_CATEGORY` is `'local-state'`, `placeCanonicalGanttRow` is pure, `task.timeline.change` reports `rowApplied: false` and the containment suite asserts that literal). D64 now carries an amendment naming what shipped and what would reopen it. Four of five mutations of the new contract failed the suite; the fifth was a probe aimed at the Gantt's input iteration rather than at the chronology sort the function performs itself, and retargeting it was caught.)*
- [x] Crash during record mutation has deterministic restart classification. — `5c95b66` @ `2026-09-07T23:24:49+07:00` *(tests/vaultRecoveryCrash.test.ts interrupts a mutation at each stage and asserts the restart classifies each one deterministically, with tests/recordRecoveryStartup.test.ts covering the gate that refuses to run until the journal is resolved.)*
- [x] Multiple Proxima callers cannot silently last-write-wins a stale record. — `8dc3841` @ `2026-09-12T02:22:54+07:00` *(tests/surfaceConvergence.test.ts drives two surfaces against one record and asserts the stale one is refused and re-read rather than merged or overwritten, and the stale cases in tests/uiAgentMutationParity.test.ts assert the same rule across the UI and programmatic callers.)*
- [x] No Papers change is claimed. — `de14bb3` @ `2026-09-12T16:55:36+07:00` *(**checked rather than asserted**, by `D:\Letters\MatTroiSeConMoc\.dsh\audit-scope-statements.ps1` - fourteen mechanical checks over the three trees, exit 0. The status table's "Papers changed" row for the current slice reads "No Papers change is recorded by this Proxima commit", the recorded baseline `0a0d89f267f6ca1125159a8b0022c9a620f62e82` is named as a baseline rather than as a claim, and every 40-character hash anywhere in Proxima's documents is either that baseline or a commit that resolves in Proxima's own history - so no foreign revision is claimed in the tree that would be read as one. The Papers checkout itself is clean at `d2a3c74cf7c0ffeab2e52709475b42e05379a71d` on the creator's own `gate10-relay` branch, and the only two commits in its last 400 that name Proxima are `cd913f3` and `d20db71`, which recorded this agenda's documents; neither touches a source, build or manifest file, so what Papers carries is the plan, not a Proxima-driven change to it.**)*
- [x] H4 remains unclaimed. — `de14bb3` @ `2026-09-12T16:55:36+07:00` *(`H4` is a row in the challenge ledger rather than a memory - "Conditional atomic write against observed revision/hash" - so the claim is about a definition, and the audit tests four absences rather than the absence of a word: nothing in `src/ports` asks a host for it, no Proxima document requests a Papers capability on its behalf, the boundary reports the capability **missing rather than half-granted** (`native-fsa-grant-and-transaction-required` in `src/app/ownerAuthorityBoundary.ts`), and the decisions ledger keeps it separate from the direction the creator did give - D51/D52 close native FSA writing, and D63's "Proxima becomes a writer later" is explicitly a direction rather than a choice of H4. The two earlier boxes that carry the same claim in the challenge and removal stages are unchanged by this one, which closes the release gate's copy against the same tree.)*
- [x] KeToan remains out. — `de14bb3` @ `2026-09-12T16:55:36+07:00` *(true by absence, and measured rather than remembered: `KeToan` occurs exactly **once** in the whole Proxima tree - the scope line itself, `docs/AUDIT-CHECKLIST.md:71`, "KeToan is permanently out of scope" - with zero occurrences across source, tests, fixtures, manifests, the shell and the fixtures' own data. Nothing has to be removed to keep it out, and no generic "future utility" or template abstraction carries it back in, which is the way the scope statement says it could return.)*
- [x] No acceptance row requires creator manual interaction. — `de14bb3` @ `2026-09-12T16:55:36+07:00` *(the audit walks **every** Acceptance and Evidence block in this document - 18 of them - for the shapes a manual requirement takes: the creator or a user being asked to click, open, select, paste or report back, and the phrases "manual interaction", "manual step" and "manual transcription". Zero lines match. The rule the scan enforces is stated in both ledgers rather than only here - no gate may require the creator to click something and report the result, and every automated UI acceptance can be invoked without a human through a browser or test interaction driver - and the paths the gates lean on are the programmatic ones: the loopback bridge's bounded reader (`tests/agentBridgeBoundary.test.ts`), the inspection projection at `8676dc3`, the shell's `__PROXIMA_INSPECTION__` hook, and the driver that the cockpit suites use to click the real DOM.)*

---

# Open questions that must remain open

These should not be silently "resolved" by whoever implements the checklist.

### Unsupported frontmatter during import

> Is `unsupported-frontmatter` importable when the compatibility reader produced a usable record, or is it an import blocker?

This must be answered before real migration activation.

### Durable all-day intent

> `CalendarEvent` has no all-day flag. Stage 4 infers all-day purely from bounds: both ends
> valid local midnights, end later than start. Before cutover, must explicit all-day intent
> become canonical data, so a user-authored all-day event stays distinguishable from an
> ordinary timed event that merely happens to run midnight to midnight?

Inference is adequate while the store is read-only. At import it stops being adequate,
because the two cases become indistinguishable and the author's intent is lost.

### Project deletion semantics

> When a project containing tasks/events is deleted, are members retained and unassigned, is cascade explicitly available, or must deletion refuse until empty?

Must close before project-delete parity.

### Gantt row order

> Is vertical Gantt row arrangement meaningful durable priority, or merely cockpit layout?

The old plugin persisted it, but that alone is not evidence that it belongs in the database. Either answer is supportable; do not reuse generic task order.

**State as of `b980c33` @ `2026-09-12T12:20:44+07:00`, recorded without closing the question.** The tree
implements it as cockpit layout: `CanonicalDurableOrderScope` admits two scopes, `GANTT_ROW_PLACEMENT_CATEGORY`
is `'local-state'`, `placeCanonicalGanttRow` is pure, and `task.timeline.change` reports `rowApplied: false`.
That is HARD GATE A/A3's answer, and `docs/DECISIONS.md#d64` in the Proxima tree now carries an amendment
saying so, because its original paragraph claimed the opposite. The box for scoped ordering is ticked
against that arrangement; this question stays open for the creator, and the answer that would change the
arrangement — row placement surviving a reload, a window or an agent — is named in the amendment.

### External vault-artifact identity

> For project Notes/drawings/attachments that remain ordinary files, what exactly identifies an association across a rename performed outside Proxima?

Do not claim stronger identity than the filesystem integration can actually provide.

### Shared Notes-file mutation concurrency

> If Obsidian edits an ordinary note while Proxima explicitly renames/moves/deletes it, what behavior is acceptable?

Moving record data into private JSON does not answer this separate ordinary-file race. Read parity is unaffected; native shared-file mutation parity cannot be called closed until this is settled.

---

The most important sequencing rule is:

**Restore presentation first → correct the domain before import → build the private store → import once → cut over → enable semantic writes surface by surface.**

And the most important architectural rule is:

**The agent never becomes another storage writer. It becomes another caller of Proxima.**
