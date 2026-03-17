---
name: create-commit
description: Propose and create conventional commit messages for staged changes. Follows Conventional Commits spec and VGV workflow.
argument-hint: "[optional: ticket/issue number e.g. VGV-123]"
user-invocable: true
---

# Create a commit

Produce a clean, conventional commit message for staged changes and commit them.

## Important

- Do not push to remote.
- Create multiple commits one at a time in order.
- This skill commits only already-staged changes. If the user asks to stage files, remind them to run `git add <files>` first.

## When to use

Use this skill when:

- The user asks to commit staged changes.
- The user asks to "create a commit", "commit this", or similar.
- Work on a task is complete and there are staged changes ready to be committed.

## Context

<context>$ARGUMENTS</context>

This may be a ticket number (e.g. `VGV-123`), a short description, or empty (the staged diff provides the context).

## Step 1: Gather context

Run these commands in parallel:

```bash
git diff --cached
git diff
git log main..HEAD --oneline
git branch --show-current
```

**If there are no staged changes:** inform the user and stop. Suggest `git add <files>` first.

## Step 2: Propose commit message(s)

Follow Conventional Commits. Consult `references/conventional-commits.md` for the full spec.

### Splitting heuristics

Actively look for reasons to split into multiple commits. Propose **multiple commits** when any of the following is true:

- **Mixed types** — e.g. production code (`feat`/`fix`) mixed with tests (`test`) or config (`chore`/`build`)
- **Multiple packages or layers touched** — e.g. `packages/` changes alongside `lib/` changes
- **Logically independent concerns** — e.g. a new API method + UI update + localization strings

A good split produces commits that could be reverted independently. Prefer more commits over fewer — clean Git history is more valuable than one monolithic commit.

Extract the ticket number from the branch name (e.g. `feat/VGV-59-...` → `VGV-59`) or from the argument passed to the skill.

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
