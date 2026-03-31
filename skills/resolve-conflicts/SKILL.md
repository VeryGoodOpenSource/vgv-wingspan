---
name: resolve-conflicts
user-invocable: true
description: Resolve merge conflicts during rebase or merge operations. Use when user says "resolve conflicts", "fix conflicts", "help with merge conflict", or "rebase conflict".
argument-hint: conflicted file path(s) or context
---

# Resolve merge conflicts

Analyze and resolve merge conflicts by understanding the intent behind each side, then applying the correct resolution — automatically for trivial cases, collaboratively for ambiguous ones.

## Context

<context>$ARGUMENTS</context>

## Phase 0 — Assess conflict state

Run:

```bash
git status --porcelain
```

Parse the output for conflict markers (`UU`, `AA`, `DD`, `AU`, `UA`, `DU`, `UD`).

**If no conflicts are detected:**

1. If context was provided, check whether the user is asking about a specific file — it may already be resolved.
2. Tell the user: "No merge conflicts detected. If you're mid-rebase, run `git rebase --continue` to proceed."
3. Stop.

**If conflicts are detected:**

1. List all conflicted files with their conflict type.
2. Report the total count: "Found **N** conflicted file(s)."
3. Proceed to Phase 1.

## Phase 1 — Understand each conflict

For each conflicted file, in order:

### Step 1: Read the file

Read the full file to locate all conflict markers (`<<<<<<<`, `=======`, `>>>>>>>`).

### Step 2: Identify conflict regions

For each conflict region in the file, extract:

- **Ours** (current branch / HEAD side)
- **Theirs** (incoming branch / rebase side)
- **Region context** — the surrounding 5-10 lines above and below

### Step 3: Classify the conflict

Assign each conflict region a category:

| Category | Description | Resolution |
|----------|-------------|------------|
| **Trivial** | Import ordering, whitespace, formatting, non-overlapping additions | Auto-resolve |
| **Mechanical** | Both sides renamed the same symbol, moved code, or updated a version | Auto-resolve with verification |
| **Semantic** | Both sides changed logic in the same region with different intent | Requires user input |
| **Structural** | One side deleted or moved code the other side modified | Requires user input |

### Step 4: Gather intent (semantic/structural only)

For conflicts that require understanding intent:

1. Run `git log --oneline -5 -- <file>` to see recent history
2. Use Grep to find usages of changed symbols in the surrounding codebase
3. Identify which change is newer and what each side was trying to accomplish

## Phase 2 — Resolve

Work through each conflicted file, applying resolutions per category.

### Trivial and Mechanical conflicts

Auto-resolve by:

1. Applying the correct resolution (combine non-overlapping additions, pick the canonical formatting, keep both renames if compatible)
2. Removing all conflict markers
3. Briefly note what was resolved and how

### Semantic and Structural conflicts

For each conflict requiring user input, use **AskUserQuestion** — one conflict at a time:

**Question:** "Conflict in `<file>`  (line <N>): <brief description of what each side changed>"

**Options:**

1. **Keep ours** — keep the current branch version
2. **Keep theirs** — keep the incoming version
3. **Keep both** — include both changes (specify order)
4. **Custom resolution** — let me describe what the result should look like

**If the user selects "Custom resolution":** apply the described change, then show the resolved region for confirmation.

### After resolving all regions in a file

1. Remove any remaining conflict markers
2. Verify the file has valid syntax (no orphaned markers, balanced braces/brackets)
3. Stage the file:

```bash
git add <file>
```

## Phase 3 — Validate

After all files are resolved and staged:

### Step 1: Check for remaining conflicts

```bash
git diff --check
```

If conflict markers remain, return to Phase 2 for the affected files.

### Step 2: Run project validation (if available)

Detect and run the project's linter and test runner. If failures occur:

- If the failure is clearly related to the conflict resolution, fix it
- If the failure is pre-existing (unrelated to the resolved files), note it and proceed
- Up to 3 fix attempts per failure — after that, use **AskUserQuestion** to ask the user for guidance

## Phase 4 — Continue

Use **AskUserQuestion** to present next steps:

**Question:** "All conflicts resolved. What next?"

**Options:**

1. **Continue rebase** — run `git rebase --continue`
2. **Commit merge** — finalize the merge commit (for merge conflicts, not rebase)
3. **Review changes first** — show the full diff of resolved files before continuing
4. **Stop here** — leave files staged, user will continue manually

**If the user selects "Review changes first":**

Run `git diff --cached` and present the output. Then re-ask with the remaining options (continue rebase, commit merge, stop here).

## Important

- **One conflict at a time.** Never overwhelm the user with multiple decisions at once.
- **Preserve intent.** The goal is not to pick a side — it is to produce code that satisfies both changes when possible.
- **Be transparent.** Always explain what was auto-resolved and why, so the user can override if needed.
- **Do not modify unrelated code.** Only touch conflict regions and their immediate surroundings.
- **Speed matters.** During a rebase with many commits, minimize unnecessary questions. Auto-resolve everything that is safe to auto-resolve.