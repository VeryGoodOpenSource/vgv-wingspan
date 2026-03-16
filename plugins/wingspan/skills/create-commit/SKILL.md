---
name: create-commit
description: Propose and create conventional commit messages for staged changes. Follows Conventional Commits spec and VGV workflow.
argument-hint: "[optional: ticket/issue number e.g. VGV-123]"
user-invocable: true
---

# Create a commit

Produce a clean, conventional commit message for staged changes and commit them.

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

### Conventional Commits format

`type(scope)!: short description`

| Type | When to use |
|------|-------------|
| `feat` | New feature visible to the user |
| `fix` | Bug fix |
| `refactor` | Code restructuring, no behavior change |
| `test` | Adding or updating tests only |
| `docs` | Documentation only |
| `chore` | Maintenance tasks (deps, config, tooling) |
| `build` | Build system or external dependencies |
| `ci` | CI/CD pipeline changes |
| `perf` | Performance improvement |
| `revert` | Reverts a previous commit |
| `style` | Formatting — no logic change |

**Scope:** use the feature folder, package name, or layer (`feat(auth)`, `fix(verify_email)`, `chore(deps)`). Omit only when the change is truly global.

**Subject line rules:**
- Imperative mood, present tense: "add", "fix", "remove"
- No capital letter after the colon
- No period at the end
- Max 72 characters
- Use `!` for breaking changes: `feat(auth)!: remove legacy login flow`

**Body (optional but recommended):**
- Blank line between subject and body
- Explain **what** and **why**, not how
- Wrap at 72 characters per line
- Ticket in footer: `Refs: VGV-123` or `Closes: VGV-123`

### Splitting heuristics

Actively look for reasons to split into multiple commits. Propose **multiple commits** when any of the following is true:

- **≥ 5 files changed** — large diffs almost always contain separable concerns
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

## Important

- Create multiple commits one at a time in order.
- Do not push to remote.
