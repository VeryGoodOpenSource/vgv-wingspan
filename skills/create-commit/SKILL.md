---
name: create-commit
description: Propose and create conventional commit messages for staged changes. Follows Conventional Commits spec and VGV workflow.
argument-hint: "[optional: single-commit | ticket/issue number e.g. VGV-123]"
---

# Create a commit

Produce a clean, conventional commit message for staged changes and commit them.

## Important

- Do not push to remote.
- Create multiple commits one at a time in order.
- **Never stage**: `.env`, `*.key`, `*.pem`, `*secret*`, `*credential*`, `*.p12`, `*.jks`.
- **Infer commit type**: Look for a plan file in `docs/plan/` and extract the type (feat, fix, refactor, etc.) from the plan title or metadata. If no plan is found, infer from the diff.

## When to use

Use this skill when:

- The user asks to commit staged changes.
- The user asks to "create a commit", "commit this", or similar.
- Work on a task is complete and there are staged changes ready to be committed.

## Context

<context>$ARGUMENTS</context>

This may include `single-commit`, a ticket number (e.g. `VGV-123`), a short description, or be empty.

## Step 0: Parse arguments

Check whether the argument contains `single-commit`. Store as `SINGLE_COMMIT` (boolean).

Extract the ticket number or short description from the remaining argument text (if any).

## Step 1: Gather context

Run these commands in parallel:

```bash
git diff --cached
git diff
git log main..HEAD --oneline
git branch --show-current
```

### If there are no staged changes

Check `git diff` and `git status --short` for unstaged modifications, deletions, and untracked files.

**If there are unstaged or untracked changes**, use **AskUserQuestion** to present them grouped by type (modified, deleted, untracked) and ask which to stage:

- **All** — stage everything (`git add -A`)
- **Select** — list each file and ask individually (use AskUserQuestion for each)
- **Cancel** — stop

Stage the confirmed files, then continue to Step 2.

**If there are no changes at all**, inform the user and stop.

## Step 2: Propose commit message(s)

Follow Conventional Commits. Consult `references/conventional-commits.md` for the full spec.

Extract the ticket number from the branch name (e.g. `feat/VGV-59-...` → `VGV-59`) or from the argument passed to the skill.

### If `SINGLE_COMMIT` is true

Always produce a single commit covering all staged changes.

If the diff contains changes that are clearly independent (i.e., each could be reverted without affecting the other), note this and suggest the user consider splitting the work into multiple PRs rather than multiple commits.

### If `SINGLE_COMMIT` is false

Default to a **single commit**. Propose multiple commits only when changes are clearly independent — i.e., each could be reverted without affecting the other:

- **Logically independent concerns** — e.g. a new API method + unrelated bug fix
- **Mixed types with no shared context** — e.g. a `feat` and an unrelated `chore`

Do not split just because multiple files or packages are touched — cohesive changes belong in one commit.

Output the proposed commit(s):

````markdown
## Proposed commit(s)

### Commit 1

```
type(scope): subject line

Optional body explaining the why.

Refs: TICKET-000
```

### Commit 2 (if applicable)

```
type(scope): subject line
```
````

## Step 3: Confirm and commit

Use the **AskUserQuestion** tool to ask:

**Question:** "Do you want me to create this commit?"

**Options:**
1. **Yes** — create the commit(s)
2. **No** — stop
3. **Edit** — ask what to change, show revised message, ask again

Create each commit with HEREDOC to preserve formatting:

```bash
git commit -m "$(cat <<'EOF'
type(scope): subject line

Optional body.

Refs: TICKET-000
EOF
)"
```

After each commit, show `git log --oneline -1`.
