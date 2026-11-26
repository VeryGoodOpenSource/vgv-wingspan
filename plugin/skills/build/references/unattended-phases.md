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

Run `git status --porcelain --untracked-files=all` and ignore the plan file's own line. The
plan is not partial work: `/plan` writes it and never commits it, and `--untracked-files=all`
lists it by its path rather than as an untracked `docs/` folder. If anything else is listed,
a phase commit would sweep those changes in, so use **AskUserQuestion** before dispatching:

1. **Continue with them** — they are partial work from an interrupted phase; the next
   subagent builds on them, and its brief says so.
2. **Stop here** — the user sorts them out first, then runs `/build` again.

## The brief

Dispatch the phase with the `Agent` tool (a general-purpose subagent). Run it in the
foreground (`run_in_background: false`) and wait for its result in this turn: permissions in
`allowed-tools` last only for the turn that invoked `/build`. Before each dispatch, note the
phase's `**Status:**` and `git rev-parse HEAD`. Substitute the placeholders:

```text
You are building one phase of an implementation plan, as one step of an unattended build.
Build Phase <N>: <PHASE_NAME> of the plan at <PLAN_PATH>, and nothing else. Do not invoke
/build or any other skill that runs the whole plan.
<PARTIAL_WORK>

1. Read the plan, then this phase's Files touched and their immediate neighbors. Treat the
   plan's conventions or codebase context section as the source of truth for patterns.
2. Implement only this phase's Scope. Write tests for every testable unit; never skip them.
3. Run this phase's Validation, then the project's linter and tests. Fix each failure and
   re-run, up to 3 attempts per failure.
4. When everything passes, set this phase's `**Status:**` to `Done` in the plan file, then
   stage this phase's changes and commit them with this message. Do not push. Stage the plan
   file only if git already tracks it (`git ls-files <PLAN_PATH>` prints it), so its Done
   marker lands in this commit; never add an untracked or ignored plan. If the commit fails,
   set the Status back to what it was and report blocked on validation.

   <TYPE>: <PHASE_NAME>

   <one-line summary of what the phase delivered>

5. You cannot ask the user anything. If a failure survives 3 attempts, or the phase needs a
   decision the plan and the codebase do not answer, stop. Do not mark the phase Done and do
   not commit. Report it instead.
6. If a command is denied permission, stop at once and report blocked on permission. Do not
   retry it, and do not work around it with a different command.

End your reply with exactly one of these blocks:

STATUS: done
COMMIT: <short hash>
SUMMARY: <one line on what the phase delivered>

STATUS: blocked
REASON: validation | decision | permission
DETAIL: <what failed, what is undecided, or the command that was denied>
TRIED: <what you tried>
OPTIONS: <the choices you see, one per line>
```

`<TYPE>` is the plan's type (`feat`, `fix`, `refactor`, …), the same commit format as
auto-commit. `<PARTIAL_WORK>` is empty, unless the user chose **Continue with them** before
the first dispatch, or this is a re-dispatch over a phase's unfinished work. Then it reads:
"The working tree already holds uncommitted work toward this phase: <the paths>. Build on it
rather than starting over."

## When a phase reports done

Confirm it before moving on:

1. The plan shows the phase's `**Status:** Done`.
2. `git rev-parse --short HEAD` matches the `COMMIT` it returned, so the commit is this
   phase's and not the previous one's.
3. `git status --porcelain --untracked-files=all`, ignoring the plan file, lists nothing, so
   the phase left nothing behind for the next commit.

If any of these fails, handle the phase as an [unexpected reply](#when-a-phase-returns-something-else).
Otherwise print the checkpoint and dispatch the next phase without asking:

```text
Phase <N>/<TOTAL> done: <PHASE_NAME> — <SUMMARY> (<COMMIT>). Next: Phase <N+1>: <NAME>.
```

## When a phase reports blocked

Use **AskUserQuestion**. Put `REASON`, `DETAIL` and `TRIED` in the question, offer the
subagent's `OPTIONS` (at most three), and add **Stop here** as the last option. For
`permission`, the question names the denied command, so the user can allow it before
answering.

- **An answer** — pass it back to the same subagent with `SendMessage`, so it keeps its
  context, then handle its reply like any other. If the subagent cannot be continued, dispatch
  a new one with the brief plus the answer, with `<PARTIAL_WORK>` naming what
  `git status --porcelain --untracked-files=all` lists.
- **Stop here** — end the run. The `**Status:**` markers and the phase commits record what is
  done; running `/build` on the plan again resumes at the first phase not marked `Done`.

## When a phase returns something else

A reply can end in neither block: the subagent was cut off, or the dispatch failed (for
example `Agent terminated early due to an API error`). Treat that, and a `done` that fails the
checks above, as unknown, never as done or blocked:

1. Stop the automatic run. Do not dispatch anything yet.
2. Show the user what came back: the tail of the reply, or the error.
3. Run `git status --porcelain --untracked-files=all` and `git log -1 --oneline`, and show what
   the phase left: uncommitted changes, a commit, or nothing.
4. If the plan marks the phase `Done` but `HEAD` is still the commit noted before the
   dispatch, set its `**Status:**` back to the one noted. A `Done` with no commit would make
   a resume skip the phase.
5. Use **AskUserQuestion**:
   1. **Dispatch the phase again** — a new subagent, with `<PARTIAL_WORK>` naming any
      uncommitted changes.
   2. **Stop here** — end the run; `/build` resumes from the `**Status:**` markers.

## What does not change

- No subagent pushes. The push question in Phase 4 still applies.
- The quality review runs once, in the main session, after the last phase. Important findings
  follow review autonomy (`${CLAUDE_PLUGIN_ROOT}/shared/references/review-autonomy.md`), so they still stop unless the user saved the
  preference.
