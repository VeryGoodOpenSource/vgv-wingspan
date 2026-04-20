---
name: rebase
user-invocable: true
disable-model-invocation: true
description: Rebases the current feature branch onto the base branch (main/master/develop). Use when user says "rebase", "sync branch", or "update branch".
effort: low
compatibility: Designed for Claude Code (or similar products with git access)
---

# Rebase onto base branch

Rebase the current feature branch onto the latest base branch to keep it up-to-date and prevent merge conflicts from accumulating.

## Step 1: Validate preconditions

Run these checks in order. If any fail, inform the user and stop.

### Detect current branch and base branch

```bash
git rev-parse --abbrev-ref HEAD
```

If the result is `main`, `master`, or `develop` — inform the user they're already on the base branch and stop.

Detect the base branch:

```!
bash scripts/detect-base-branch.sh
```

If the script exits with an error, inform the user no base branch was found and stop.

### Check for uncommitted changes

```bash
git status --porcelain
```

If there are uncommitted changes, use **AskUserQuestion**:

**Question:** "You have uncommitted changes. Rebase requires a clean working tree. What would you like to do?"

**Options:**

1. **Stash and rebase (Recommended)** — `git stash` before rebasing, `git stash pop` after
2. **Cancel** — stop without changes

## Step 2: Fetch and check

```bash
git fetch origin <base-branch> --quiet
```

Compare the merge base with the remote base:

```bash
git merge-base HEAD origin/<base-branch>
git rev-parse origin/<base-branch>
```

If they match, the branch is already up-to-date. Inform the user and stop.

## Step 3: Rebase

```bash
git rebase origin/<base-branch>
```

### Clean rebase (no conflicts)

Report success briefly:

- How many commits were replayed (`git rev-list --count origin/<base-branch>..HEAD`)
- The branch is now up to date with `origin/<base-branch>`
- If the branch was previously pushed, mention that a force-push (`git push --force-with-lease`) will be needed to update the remote — but do NOT push automatically

If changes were stashed in Step 1, restore them with `git stash pop`. If stash pop fails due to conflicts, inform the user and suggest `git stash show` to review the stashed changes.

## Step 4: Handling conflicts

When `git rebase` stops with conflicts:

### 4a. Identify conflicted files

```bash
git diff --name-only --diff-filter=U
```

### 4b. Resolve each conflicted file

Read the full file content and locate conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`). For each conflict chunk, decide:

**Auto-resolve** (the right answer is clear):

- Both sides added imports or list items — combine both sets, deduplicate, maintain sort order
- Generated files (`.g.dart`, `.freezed.dart`, `.gen.dart`, lock files) — take the current branch version; note that regeneration is needed after rebase completes
- Formatting / whitespace-only diffs — accept either side
- One side added new code, the other didn't touch that region — take the addition
- One side modified code the other side deleted — prefer the modification, but mention it in the summary so the user can verify the deletion wasn't intentional

**Stop and ask the user** (the right answer requires judgment):

- Both sides changed the same function or logic block differently
- Business logic where correctness depends on product intent
- Anything you aren't confident about

When in doubt, ask. Losing someone's work is far worse than pausing to check.

After resolving all conflicts in a file, write the clean version and stage it:

```bash
git add <resolved-file>
```

### 4c. Continue the rebase

```bash
git rebase --continue
```

Multi-commit rebases may produce conflicts at multiple steps. Repeat 4a-4c for each.

### 4d. After all conflicts are resolved, report

- Every conflict that was resolved, with a one-line explanation of what you chose
- Any files flagged for regeneration
- Suggest running the project's build/test/format/analyze commands to verify correctness
- If the branch was previously pushed, mention that a force-push (`git push --force-with-lease`) will be needed — but do NOT push automatically

If changes were stashed in Step 1, restore them with `git stash pop`. If `stash pop` fails due to conflicts, inform the user and suggest `git stash show` to review the stashed changes.

## Step 5: Recovery

If the rebase enters a bad state or a conflict is too ambiguous to resolve safely:

```bash
git rebase --abort
```

This restores the branch to its exact pre-rebase state — nothing is lost. Explain what went wrong so the user can decide how to proceed.

If changes were stashed in Step 1, restore them with `git stash pop`.

## Gotchas

- Detached HEAD state (`HEAD` instead of a branch name) means the user is not on any branch. Inform them and stop — do not attempt to rebase.
- If the base branch does not exist locally but does on the remote, `git fetch` in Step 2 will create the remote tracking ref. The rebase uses `origin/<base-branch>`, not the local branch.

## Rules

- Never force-push unless the user explicitly asks.
- Never squash, reorder, or edit commits during the rebase — just replay them.
- Never proceed on a dirty working tree without the user's consent.
- Prefer keeping both sides' changes when combining — err on the side of inclusion.
- After resolving conflicts, always recommend running build, test, format, and analyze to verify.
- This skill only manages git state. Do not modify project files outside of conflict resolution.
- If changes were stashed, always restore them — even if the rebase fails.
