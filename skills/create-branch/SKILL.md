---
name: create-branch
user-invocable: true
description: Sets up a workspace branch or worktree before writing artifacts. Use when user says "create a branch", "set up workspace", "start a feature branch", or "new branch".
argument-hint: feature name or context
effort: low
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Create a working branch

Set up a feature branch or worktree before the first artifact is written. Called by `/brainstorm` and `/plan` to keep files off the default branch.

## Context

<context>$ARGUMENTS</context>

This may be a feature description, brainstorm topic, plan title, or empty (when called by another skill, the conversation context provides the description).

## Step 1: Detect current branch

Run:

```bash
git rev-parse --abbrev-ref HEAD
```

**If the result is NOT `main`, `master`, or `develop`:** the session is already on a feature branch. Skip silently — return control to the caller without any output.

**If the result is `main`, `master`, or `develop` (or `HEAD` for detached state):** proceed to Step 2.

## Step 2: Infer branch name

Build a branch name in the format `<type>/<kebab-topic>`.

### Type

Default to `feat/`. Use `fix/`, `refactor/`, or `chore/` when the context makes the type obvious.

### Topic

Derive a kebab-case slug from the feature description or conversation context:

1. Extract the core topic (strip filler words like "add", "implement", "create" from the start if they don't add meaning, but keep them if they clarify the branch purpose)
2. Convert to kebab-case
3. Truncate the slug so the full branch name (`<type>/<slug>`) stays under 60 characters
4. Strip any trailing hyphens after truncation

## Step 3: Present options

Use the **AskUserQuestion** tool to confirm the branch name and workspace type:

**Question:** "Set up workspace? Proposed branch: `<type>/<kebab-topic>`"

**Options:**

1. **Create branch (Recommended)** — `git checkout -b <name>` (changes carry over to the new branch)
2. **Create worktree** — isolated working directory via `EnterWorktree`
3. **Skip** — stay on the current branch

The "Other" option (auto-provided) lets users enter a custom branch name. If a custom name is provided, use it as-is for `git checkout -b`.

**If the user selects "Skip":** return control to the caller without changes.

## Step 4: Create workspace

### Regular branch

Run:

```bash
git checkout -b <branch-name>
```

### Worktree

Before creating, check for uncommitted changes:

```bash
git status --porcelain
```

**If the output is non-empty**, use **AskUserQuestion** to warn:

**Question:** "You have uncommitted changes that will stay in your original working tree. The worktree starts from a clean checkout. Continue?"

**Options:**

1. **Continue with worktree (Recommended)** — proceed
2. **Use a regular branch instead** — fall back to `git checkout -b`
3. **Cancel** — return to caller without changes

**If proceeding with worktree**, call the `EnterWorktree` tool with the branch name.

**If `EnterWorktree` fails** (e.g., already in a worktree), fall back to `git checkout -b` and inform the user.

## Important

- This skill is designed to be fast and non-disruptive. When skipping, produce no output.
- Do not modify files. This skill only manages git state.
