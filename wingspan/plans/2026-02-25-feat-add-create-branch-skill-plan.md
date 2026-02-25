---
title: "feat: add /create-branch skill for workspace setup"
type: feat
date: 2026-02-25
---

## feat: add /create-branch skill for workspace setup

## Overview

Add a `/create-branch` skill that sets up a workspace (regular branch or worktree) before the first artifact is written. Wire it into `/brainstorm` and `/plan` so the branch exists before any file is created.

Related: #34

## Problem Statement / Motivation

Currently, `/brainstorm` and `/plan` write files directly to whatever branch the user is on — often `main`. This means brainstorm docs and plan files end up on the default branch, requiring manual branch management before or after the fact. Automating workspace setup keeps artifacts off `main` and makes the workflow cleaner: brainstorm, plan, and build all happen on a feature branch from the start.

## Proposed Solution

Create a standalone skill at `plugins/wingspan/skills/create-branch/SKILL.md` with this flow:

1. **Detect current branch** — if already on a feature branch, skip silently
2. **Infer branch name** — derive `<type>/<kebab-topic>` from context
3. **Present options** — ask user: regular branch, worktree, or skip
4. **Create workspace** — execute `git checkout -b` or `EnterWorktree`

Then wire `@create-branch` into `/brainstorm` (between step 1.3 and step 2) and `/plan` (between step 4 and step 5) so the branch exists before files are written.

## Technical Considerations

### Feature branch detection

A branch is considered a "default branch" (triggers creation) if it matches: `main`, `master`, or `develop`. Any other branch name is treated as a feature branch and skips creation. Detached HEAD state is treated as "not on a feature branch" — proceed with creation.

### Branch name inference

**Source context by caller:**

- **From `/brainstorm`**: use the raw `$ARGUMENTS` (feature description) passed to the brainstorm skill. The brainstorm doc hasn't been written yet at this point, so the conversation context is the source.
- **From `/plan`**: use the plan title drafted in step 2 (which has the `<type>: <description>` format). If a brainstorm doc exists, its topic can supplement.
- **From direct invocation**: ask the user for a description.

**Type inference**: parse keywords from the feature description — "bug"/"fix" → `fix`, "refactor" → `refactor`, "chore" → `chore`. Default: `feat`.

**Kebab slug**: derive from the description, truncate to keep the full branch name under 60 characters.

### User prompt structure

Present the inferred name and three options via `AskUserQuestion`:

1. **Create branch** — `git checkout -b <name>` (regular branch)
2. **Create worktree** — isolated working directory via `EnterWorktree`
3. **Skip** — stay on current branch, return control to caller

The "Other" option (auto-provided by `AskUserQuestion`) lets users enter a custom branch name.

### Branch name collision

If `git checkout -b` fails because the branch exists, offer:

1. **Switch to existing branch** — `git checkout <name>`
2. **Enter a different name** — prompt for custom name

### Dirty working tree

- **Regular branch**: proceed silently (uncommitted changes carry over)
- **Worktree**: warn the user that uncommitted changes stay in the original tree; ask to confirm

### Already in a worktree

If the session is already in a worktree and the user picks "worktree" again, `EnterWorktree` will fail. The step 1 skip logic handles most cases (worktree branches aren't `main`), but if somehow on a default branch in a worktree, fall back to `git checkout -b`.

## Acceptance Criteria

- [ ] New skill file at `plugins/wingspan/skills/create-branch/SKILL.md`
  - YAML frontmatter with `name: create-branch` and `description`
  - Follows existing skill conventions (numbered steps, `AskUserQuestion` for prompts)
- [ ] Skill detects default branches (`main`, `master`, `develop`) and skips on any other branch
- [ ] Skill infers branch name as `<type>/<kebab-topic>` from context, defaulting to `feat`
- [ ] Skill offers three options: regular branch, worktree, skip
- [ ] Skill handles branch name collision (offer switch or rename)
- [ ] `/brainstorm` SKILL.md updated: calls `@create-branch` between step 1.3 and step 2
  - `plugins/wingspan/skills/brainstorm/SKILL.md`
- [ ] `/plan` SKILL.md updated: calls `@create-branch` between step 4 and step 5
  - `plugins/wingspan/skills/plan/SKILL.md`
- [ ] All modified skills remain under 500 lines
- [ ] If `/brainstorm` already created a branch, `/plan`'s call to `@create-branch` detects and skips

## Implementation Tasks

### Task 1: Create `plugins/wingspan/skills/create-branch/SKILL.md`

Create the new skill file following existing conventions (see `brainstorm/SKILL.md` and `plan/SKILL.md` for patterns).

**Structure:**

```markdown
---
name: create-branch
description: Set up a workspace (branch or worktree) before writing artifacts
---

# Create a working branch

## Step 1: Detect current branch
- Run `git rev-parse --abbrev-ref HEAD`
- If result is NOT `main`, `master`, or `develop` → skip, return to caller
- If result is `HEAD` (detached) → proceed to step 2

## Step 2: Infer branch name
- Extract type and topic from available context
- Build `<type>/<kebab-topic>`, truncate slug to keep total under 60 chars
- Type keywords: "bug"/"fix" → fix, "refactor" → refactor, "chore" → chore, default → feat

## Step 3: Present options to user
- AskUserQuestion with: Create branch / Create worktree / Skip
- Show the inferred name; "Other" allows custom name

## Step 4: Create workspace
- Branch: `git checkout -b <name>`
  - On collision: offer switch or rename
- Worktree: check dirty tree first, warn if needed, then `EnterWorktree`
- Skip: return to caller without changes
```

### Task 2: Update `/brainstorm` SKILL.md

File: `plugins/wingspan/skills/brainstorm/SKILL.md`

Add a new step between step 1.3 (Explore approaches) and step 2 (Capture the design document):

```markdown
### 1.4. Set up workspace

Before writing any files, ensure the session is on a feature branch:

- Call @create-branch to check and optionally create a working branch or worktree.
```

Renumber if needed so the flow remains: 1.3 Explore approaches → 1.4 Set up workspace → 2. Capture the design document.

### Task 3: Update `/plan` SKILL.md

File: `plugins/wingspan/skills/plan/SKILL.md`

Add a new step between step 4 (Select implementation detail template) and step 5 (Issue creation and formatting):

```markdown
### 4.1. Set up workspace

Before writing the plan file, ensure the session is on a feature branch:

- Call @create-branch to check and optionally create a working branch or worktree.
```

Renumber if needed so the flow remains: 4. Select template → 4.1 Set up workspace → 5. Issue creation and formatting.

## Success Metrics

- Running `/brainstorm` on `main` prompts for branch creation before writing the brainstorm doc
- Running `/plan` after `/brainstorm` (already on feature branch) skips branch creation silently
- Running `/plan` standalone on `main` prompts for branch creation before writing the plan file
- User can skip branch creation and continue on `main` if they choose

## Dependencies & Risks

- **EnterWorktree behavior**: the `EnterWorktree` tool changes the session working directory. Skills that create directories before writing files (both `/brainstorm` and `/plan` do this) should work transparently.
- **Line count risk**: adding steps to `/brainstorm` (182 lines) and `/plan` (253 lines) must stay under 500 lines. The additions are small (~5-8 lines each), well within budget.
- **No `/build` integration**: out of scope per #34. The assumption is `/build` runs after `/plan` has set up the branch. A follow-up could add a safety check to `/build`.

## References & Research

- Existing skill patterns: `plugins/wingspan/skills/brainstorm/SKILL.md`, `plugins/wingspan/skills/plan/SKILL.md`
- `EnterWorktree` tool: creates worktree in `.claude/worktrees/`, requires not already in a worktree
- Claude Code `AskUserQuestion` tool: supports options with labels/descriptions, "Other" auto-provided
- Related issue: #34
