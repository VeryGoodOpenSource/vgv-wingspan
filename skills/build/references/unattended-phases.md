# Unattended Phases

How `/build` runs every remaining phase without a stop between them, once the user chose
**Run all phases unattended** in Phase 0. Each phase runs in its own subagent, so each one
starts with a fresh context and the user never has to clear and restart.

| Role | Does |
| ---- | ---- |
| Main session | Dispatches one phase at a time, checks each result, reports progress, asks the user when a phase is blocked, then runs the surgical-diff gate, review, and ship as usual |
| Phase subagent | Builds one phase: reads its context, implements, tests, validates, marks it `Done`, commits it |

Dispatch one subagent at a time, in plan order. Phases build on each other, so never run two
at once.

## Before the first dispatch

Run `git status --porcelain`. If it lists anything, a phase commit would sweep those changes
in, so use **AskUserQuestion** before dispatching:

1. **Continue with them** — they are partial work from an interrupted phase; the next
   subagent builds on them.
2. **Stop here** — the user sorts them out first, then runs `/build` again.

## The brief

Dispatch the phase with the `Agent` tool (a general-purpose subagent), wait for it, and
substitute the placeholders:

```text
You are building one phase of an implementation plan, as one step of an unattended build.
Build Phase <N>: <PHASE_NAME> of the plan at <PLAN_PATH>, and nothing else. Do not invoke
/build or any other skill that runs the whole plan.

1. Read the plan, then this phase's Files touched and their immediate neighbors. Treat the
   plan's conventions or codebase context section as the source of truth for patterns.
2. Implement only this phase's Scope. Write tests for every testable unit; never skip them.
3. Run this phase's Validation, then the project's linter and tests. Fix each failure and
   re-run, up to 3 attempts per failure.
4. When everything passes, set this phase's `**Status:**` to `Done` in the plan file, then
   stage this phase's changes and commit them with this message. Do not push.

   <TYPE>: <PHASE_NAME>

   <one-line summary of what the phase delivered>

5. You cannot ask the user anything. If a failure survives 3 attempts, or the phase needs a
   decision the plan and the codebase do not answer, stop. Do not mark the phase Done and do
   not commit. Report it instead.

End your reply with exactly one of these blocks:

STATUS: done
COMMIT: <short hash>
SUMMARY: <one line on what the phase delivered>

STATUS: blocked
REASON: validation | decision
DETAIL: <what failed, or what is undecided>
TRIED: <what you tried>
OPTIONS: <the choices you see, one per line>
```

`<TYPE>` is the plan's type (`feat`, `fix`, `refactor`, …), the same commit format as
auto-commit.

## When a phase reports done

Confirm it before moving on: the plan shows the phase's `**Status:** Done`, and `git log -1`
shows its commit. If either is missing, handle the phase as blocked on validation.

Then print the checkpoint and dispatch the next phase without asking:

```text
Phase <N>/<TOTAL> done: <PHASE_NAME> — <SUMMARY> (<COMMIT>). Next: Phase <N+1>: <NAME>.
```

## When a phase reports blocked

Use **AskUserQuestion**. Put `DETAIL` and `TRIED` in the question, offer the subagent's
`OPTIONS` (at most three), and add **Stop here** as the last option.

- **An answer** — pass it back to the same subagent so it keeps its context, then handle its
  reply like any other. If the harness cannot continue a subagent, dispatch a new one with
  the brief plus the answer, and say the phase's partial work is already in the working tree.
- **Stop here** — end the run. The `**Status:**` markers and the phase commits record what is
  done; running `/build` on the plan again resumes at the first phase not marked `Done`.

## What does not change

- No subagent pushes. The push question in Phase 4 still applies.
- The quality review runs once, in the main session, after the last phase. Important findings
  follow [review autonomy](review-autonomy.md), so they still stop unless the user saved the
  preference.
