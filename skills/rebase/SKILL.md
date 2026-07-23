---
name: rebase
user-invocable: true
disable-model-invocation: true
description: Rebases the current feature branch onto the base branch (main/master/develop).
when_to_use: Use when user says "rebase", "sync branch", or "update branch".
allowed-tools: Bash(*/scripts/detect-base-branch.sh) Bash(git fetch *) Bash(git rebase *) Bash(git stash *)
effort: low
compatibility: Designed for Claude Code (or similar products with git access)
---

# Rebase onto base branch

Rebase the current feature branch onto the latest base branch to keep it up-to-date and prevent merge conflicts from accumulating.

<!-- portability:destructive-guard -->
<!-- portability:ask-fallback -->

> **Cross-harness guards.** This skill rewrites branch history and may require a force-push. `disable-model-invocation: true` blocks description-activation on Claude Code, but other hosts ignore that field — if activated by description rather than an explicit user instruction to rebase, stop and confirm in plain text first. The uncommitted-changes gate below uses `AskUserQuestion`; on a host without it, ask in plain numbered text and never rewrite history or force-push without an explicit user go-ahead. See [interaction fallbacks](references/interaction-fallbacks.md).

## Step 1: Validate preconditions

Run these checks in order. If any fail, inform the user and stop.

### Detect current branch and base branch

```bash
git rev-parse --abbrev-ref HEAD
```

If the result is `main`, `master`, or `develop` — inform the user they're already on the base branch and stop.

Detect the base branch:

```bash
${CLAUDE_SKILL_DIR}/scripts/detect-base-branch.sh
```

If the script exits with an error, inform the user no base branch was found and stop.

> **Fallback** — if `${CLAUDE_SKILL_DIR}` is not substituted (the command still contains the literal text), run `scripts/detect-base-branch.sh` from this skill's own directory instead. If script execution is unavailable, detect the base branch inline: use the first of `main`, `master`, `develop` that resolves via `git rev-parse --verify <branch>` or `git rev-parse --verify origin/<branch>`; if none exist, stop.

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

### On success

Report how many commits ahead of the base branch:

```bash
git rev-list --count origin/<base-branch>..HEAD
```

### On conflict

Abort the rebase:

```bash
git rebase --abort
```

If changes were stashed in Step 1, restore them with `git stash pop`.

Inform the user that the rebase had conflicts and suggest resolving manually:

> Automatic rebase failed due to conflicts. To resolve manually, run: `git rebase origin/<base-branch>`

## Gotchas

- If the branch has already been pushed to a remote, rebasing rewrites history. The user will need to force-push (`git push --force-with-lease`) after a successful rebase — warn them.
- `git stash pop` can itself cause conflicts if stashed changes overlap with rebased commits. If stash pop fails, inform the user and suggest `git stash show` to review the stashed changes.
- Detached HEAD state (`HEAD` instead of a branch name) means the user is not on any branch. Inform them and stop — do not attempt to rebase.
- If the base branch does not exist locally but does on the remote, `git fetch` in Step 2 will create the remote tracking ref. The rebase uses `origin/<base-branch>`, not the local branch.

## Important

- This skill only manages git state. Do not modify project files.
- If changes were stashed, always restore them — even if the rebase fails.
