# Phase Branches

How `/build` puts each phase of a local plan on its own branch, so the phases ship as stacked
pull requests: one per phase, each targeting the previous phase's branch and showing only its
own diff. Publishing the stack follows [stacked pull requests](stacked-prs.md).

## When this applies

A plan from `docs/plan/` whose `## Implementation Phases` section has two or more phases.

It does not apply to a plan with one phase or none, which builds on one branch and ships one
pull request. It does not apply to a build from a GitHub issue either: there each run builds
one phase and ships it once the previous phase has merged, per
[plan on an issue](plan-on-issue.md).

The commands below need git 2.38 or later, for `git rebase --update-refs`.

## Branch names

| Phase | Branch |
| ----- | ------ |
| 1 | The feature branch the build starts on, `<type>/<kebab-topic>` |
| N ≥ 2 | `<feature branch>-phase-N`, cut from phase N−1's branch |

The feature branch is the **root**. From any phase branch, the root is the branch name with a
trailing `-phase-<k>` removed. The phase branches are the root (phase 1) and every
`<root>-phase-<N>`. Compare them by N as a number, so phase 10 sorts after phase 2.

## Leftover files

Two untracked files are never phase work: the plan file, which `/plan` writes and never
commits, and the agent-mode decision log under `docs/agent-decisions/`. Wherever this reference
checks `git status --porcelain --untracked-files=all`, ignore both.

## Before building phase N ≥ 2

Run this at the start of the phase, before Phase 1 (Setup) reads the phase's files, and before
Step 1 of the phase loop. A resumed build runs it too. In an unattended run the main session
runs it before it dispatches the phase's subagent.

1. `git rev-parse --abbrev-ref HEAD` should be phase N's branch (an earlier run cut it) or
   phase N−1's branch. If it is neither, check out phase N−1's branch. If that branch does not
   exist, stop and ask the user which branch holds the earlier phases.
2. `git status --porcelain --untracked-files=all` should list nothing. Otherwise phase N−1's
   work may not be committed yet, and cutting a branch now would carry it into phase N's pull
   request. Ask the user to commit it on phase N−1's branch first (in the **I'll commit
   myself** mode, that is the normal next step), then stop. The one exception is an unattended
   run whose user chose **Continue with them** before the first dispatch: phase N−1 is marked
   `Done` and committed, so those changes are phase N's partial work and move with HEAD onto
   phase N's branch.
3. If phase N's branch exists, check it out. Otherwise cut it from HEAD:

   ```bash
   git checkout -b <root>-phase-<N>
   ```

The plan file is untracked unless the project commits it, so it follows each checkout and its
`**Status:**` markers stay current. If git tracks it, each phase commit carries its marker, and
every branch inherits the markers below it.

## Landing fixes after the last phase

The surgical-diff gate, the review and the drive-to-green loop run on the top branch, the last
phase's, and its diff against the base covers the whole stack. A fix belongs to the phase whose
code it changes, so that phase's pull request shows the fix next to the code. Make each fix on
the branch that owns it, rather than on the top branch and moving it afterwards. This applies
only in the auto-commit and unattended modes. In the **I'll commit myself** mode, make every
fix on the top branch and, in the summary, name the phase branch each fix belongs on.

Nothing has been pushed yet at this point, so rebasing the phase branches above an owner
rewrites only local commits. That is the one exception to the surgical-diff gate's rule
against rewriting history.

### 1. Find each fix's owner

A fix is one unit of change: one review finding, one churn removal, or the change that turns
one failing gate green. Its code and the tests that cover it share one owner.

- **It changes or removes existing lines.** Blame them on the top branch: `git blame -L
  <start>,<end> HEAD -- <file>`. The owner is the lowest phase branch that contains that commit:
  `git branch --contains <commit>`, kept to the phase branches and compared by phase number,
  with the root as phase 1.
- **It only adds code, such as a missing test or a guard.** The owner of the code it covers or
  guards, found the same way.
- **It touches code from several phases.** The highest of them, since that branch has all of
  the code.

### 2. Land the fixes, bottom up

Group the fixes by owner. Start from a clean working tree: commit anything outstanding on the
top branch first, per [commit autonomy](commit-autonomy.md). Then, for each owner below the top,
lowest first:

1. `git checkout <phase branch>` and make that phase's fixes, code and tests together.
2. Run the phase's **Validation**, then commit per commit autonomy.
3. `git checkout <top branch>` and `git rebase --update-refs <phase branch>`. That replays every
   phase above it onto the fix and moves their branches with it.

Make the top phase's own fixes on the top branch last, as usual.

A fix next to lines a later phase changed can conflict at the rebase. Then run
`git rebase --abort` and `git branch -f <phase branch> <phase branch>~1` to drop the fix commit
just made there, and make those fixes on the top branch instead. Tell the user which fixes
stayed on the top branch and why.

### 3. Check the rebased branches

Each branch the rebases rewrote, between the lowest owner and the top, now holds code its
phase's Validation has not run against. Check out each one, run its phase's **Validation**, and
return to the top branch. A failure stops the run: ask the user, or in agent mode stop with a
blocked status. The ship gate runs on the top branch as usual, after the last fix.

## Shipping the stack

Pushing still waits for the one push question in [commit autonomy](commit-autonomy.md), which
covers the whole stack. Then follow [stacked pull requests](stacked-prs.md) with:

- `<BASE_BRANCH>`: the base branch the [surgical-diff gate](surgical-diff-gate.md) resolved.
- `<BRANCHES>`: the phase branches, phase 1 first.
- Per phase, a title `<type>: <phase name>`, with the name in imperative mood, lowercase after
  the colon, no trailing period, max 72 characters. The body is the [PR template](pr-template.md)
  filled for that phase: its Summary from the phase's Scope, its Test plan from the phase's
  Validation and Acceptance criteria.
- **No install offer** in an unattended run or in agent mode.

A stack pushed by an earlier run and rebased since needs a `--force-with-lease` push. In agent
mode, that is a force operation: do it only when the request allows force pushes, and otherwise
keep the work local and report it.

In the post-ship summary, list the pull requests bottom to top and tell the user how to keep
the stack consistent after a fix or a squash merge, per the same reference.
