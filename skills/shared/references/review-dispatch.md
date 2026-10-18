# Review Agent Dispatch

How a skill launches its quality-review agents. The calling skill supplies the absolute
raw-reports directory (`<RAW_DIR>`), the table of agents with their report names, and what is
under review.

## Resolve the paths

Run `pwd` and let `<PWD>` be the result — subagents may change directories, so a relative
path is unreliable. Substitute `<PWD>` into `<RAW_DIR>` before dispatching; never pass a
relative path to an agent.

## Resolve the scope

A review agent starts with none of this conversation — no plan, no bug report, no diff, no
file read so far — so its prompt is all it knows about the change. Resolve the scope once,
here, so every agent reviews the same change instead of each working it out again:

- **A branch** — the base branch the calling skill names, the merge-base
  (`git merge-base HEAD <base-branch>`), and the changed files: `git diff --name-only <merge-base>`
  plus untracked files (`git ls-files --others --exclude-standard`). Uncommitted work is part
  of the change.
- **Specific paths** — the paths under review.
- **The whole project** — no constraint.

## Dispatch

Run every agent in the skill's table **in parallel**, in a single message. Each agent prompt
carries:

1. **The subject** — a sentence or two on what changed and why, as the calling skill states
   it: a plan's path and the goal from its `success-criteria` block, or a bug and its root
   cause. An agent that knows the intent can tell planned behavior from scope creep. A review
   of existing code may have no subject; say so.
2. **The scope** — from the step above. For a branch, give the base branch, the merge-base
   SHA, and the changed-file list.
3. **The [review agent instructions](review-agent-instructions.md)**, with `<RAW_DIR>` set to
   the resolved absolute directory and `<name>` set to that agent's report name from the
   table (a bare stem — the agent writes `<RAW_DIR>/<name>.md`).

## Handle failures

An agent failure is non-fatal. Note it, continue with the rest, and record the failure in
both the report header and the chat summary so the user knows the review is incomplete —
a silently halved review reads as a clean one.
