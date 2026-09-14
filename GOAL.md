# Goal: make Papers good to use

Not: close 358 checkboxes. The boxes are stale — written before the thing they
describe existed, and measured against a plan rather than against use. The Proxima
rebuild proved how that ends: 2,242 boxes ticked against a fixture the app could
never escape, every one of them honestly earned, and the result was unusable.

So the checklists under `papers/` are **design references**, in exactly the way the
Proxima interaction trace was: read them to learn what was intended and why, never
as a work queue. A box is not a task. The question is always *does this serve the
way the creator actually works.*

## What is being built

| Thing | State | Lane |
| --- | --- | --- |
| **Quick Run** — hotkey, type, Enter, gone | Built, reviewed twice, two closures from merged | Lane 3 |
| **Window layouts that stay honest** — a saved group of windows that does not quietly rot | Design only | Lane 4 |
| **Foreign windows inside Papers** — Obsidian or VS Code living in a Papers pane | Design only | Lane 5 |

The last two land in `D:\Letters\MatTroiSeConMoc\Products\Papers\Source` — `Futahua/Papers-3`,
host baseline green at `d2a3c74`, 942 passed / 4 skipped in 5.4s.

## How this runs

I coordinate and decide. Lanes are DSH sessions that build; reviewers are separate
ChatGPT threads that read the result and rule on it. A lane never accepts its own
work — that separation is the one thing that survived the previous attempt.

    brief -> lane builds -> I commit and push -> reviewer rules -> I decide -> repeat

**Reviewers are asked about use, not conformance.** The most valuable review this week
was the one where the checklist was deliberately withheld and the question was "is this
good, and what will annoy the creator on day thirty that looks fine on day one." It
found a false-success write path, a reveal that silently did nothing, and a wheel
contract that existed in the description and not in the code. A conformance pass would
have found none of it.

The rules that were earned rather than assumed:

- **Verify by running, not by reasoning.** Every real finding this week came from
  driving the thing. Several green results were tests that could not distinguish the
  situation they claimed to prove.
- **Refuse, never coerce.** A contradictory state is reported, not clamped into
  something plausible. The same bug — a silent rewrite that reads as a correct answer
  — has appeared at least four times in this codebase.
- **A finding enters the ledger the moment it is reported**, actioned or not.
- **The record must reproduce.** A claimed test count nobody can re-run is not evidence.

## Order, and why

**Quick Run first.** Two closures from merged. A finished feature the creator presses
dozens of times a day is worth more than three half-built ones.

**Window layouts second.** Its own design names the constraint: exact window-instance
identity has to land before "remove invalidated processes immediately", or a Chrome tab
switch silently deletes Chrome and Obsidian from the creator's layouts during ordinary
use. That makes the early work identity work — which is reversible, and testable without
touching anything the creator is looking at.

**Foreign windows last**, deliberately. It moves, hides and re-stacks applications the
creator is actually using. A mistake is not undone by `git revert`. Its own design says
to start with a disposable experimental follower and look at it before committing to
anything — an afternoon, not a plan.

## What only the creator decides

Not blockers to route around — decisions:

1. **Papers host changes.** Both unbuilt features modify `Papers-3`. A host change was
   declined on 2026-09-13; building these reopens that.
2. **Anything with a human in the loop at the machine** — watching real windows move.
   No test coverage substitutes for it.
3. **Anything irreversible**: the live vault, real layouts, real windows.

A lane that reaches one of these stops and says so rather than inventing an answer.

## Watching

Lanes: `dsh-plugins/harness/wait-idle.mjs` for one, `wait-any.mjs` for several. Both poll
`_dsh/session/state` over the ACP control plane and fire only after a session has been
continuously idle, so a lane between two queued turns cannot trigger them and a lane
thinking without writing cannot hide. File-mtime watching was tried first and was wrong
in both directions.

Reviewers have no such signal — they are browser tabs. They are polled by a completion
detector that latches that generation *started* before it will report finished, because
the absence of a running indicator is also what a page looks like before it begins.
