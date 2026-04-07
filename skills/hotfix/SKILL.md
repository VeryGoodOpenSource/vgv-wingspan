---
name: hotfix
user-invocable: true
description: Applies a minimal, targeted fix for emergency bugs — enforces review and testing without brainstorm or planning phases.
effort: high
argument-hint: bug description, issue link, or error message
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Hotfix — emergency fix workflow

Apply a minimal, targeted fix fast. No brainstorm document, no plan document — but tests and review are still non-negotiable.

## Bug Description

<bug_description>$ARGUMENTS</bug_description>

**If the bug description above is empty, ask the user**: "What's the bug? Paste a description, issue link, or error message."

DO NOT proceed until you have a bug description.

## Phase 0 — Triage

Summarize the bug in one sentence. Identify:

- **Symptom**: what the user sees or what is broken
- **Suspected area**: which layer or component is likely involved (based on the description alone — do not read code yet)

## Phase 1 — Locate

Run a focused codebase exploration to find the problem area:

- Task @codebase-review-agent("Locate the code responsible for this bug. Focus narrowly on the symptom described — do not survey the entire codebase. Bug: <bug_description>")

After the agent returns:

1. Read the identified files and their immediate neighbors to understand the context.
2. Identify the root cause (or the most likely candidate).
3. Summarize the root cause to the user in 2-3 sentences.

If the root cause is unclear after exploration, use **AskUserQuestion** to ask the user for additional context before proceeding.

## Phase 2 — Branch

Set up a hotfix branch. Unlike normal feature branches, hotfix branches use the `hotfix/` prefix.

Run:

```bash
git rev-parse --abbrev-ref HEAD
```

**If already on a `hotfix/` branch:** skip silently.

**Otherwise:** infer a branch name in the format `hotfix/<kebab-slug>` where the slug is derived from the bug description (max 60 characters total). Use **AskUserQuestion** to confirm:

1. **Create branch (Recommended)** — `git checkout -b hotfix/<slug>`
2. **Skip** — stay on the current branch

## Phase 3 — Fix

### Blast Radius Check

Before writing any code, outline the planned change:

- Which files will be modified
- Which layers are touched
- Estimated lines changed

**If the fix touches more than 5 files, spans multiple layers, or requires new abstractions:** warn the user:

> This fix has a large blast radius (<N> files across <layers>). Consider switching to the full `/plan` → `/build` workflow for a more structured approach.

Use **AskUserQuestion** with options:

1. **Proceed with hotfix** — continue, accepting the risk
2. **Switch to /plan** — abort hotfix, start planning

**If the fix is contained (≤5 files, single layer or tightly coupled area):** proceed directly.

### Step 1: Implement

Write the minimal change that addresses the root cause:

- **Minimal diff**: change only what is necessary. No drive-by refactors, no "while I'm here" improvements.
- **Scope guard**: if you find yourself touching code unrelated to the bug, stop and flag it to the user as scope creep.
- **Leave TODOs for follow-up**: if you notice related issues, tech debt, or improvements that are out of scope for this hotfix, add `// TODO(hotfix): <description>` comments in the code so they can be addressed later in a proper `/plan` → `/build` cycle.
- **Follow existing patterns**: match the style and conventions of the surrounding code.

### Step 2: Test

Tests are non-negotiable, even for hotfixes:

- Add or update tests that **reproduce the bug** (the test should fail without the fix).
- Cover the fix path and any closely related edge cases.
- Do not write tests for unrelated code.

### Step 3: Validate

Run static analysis — detect and use the project's linter/analyzer.

Run tests — detect and use the project's test runner.

If failures occur:
- Fix the issue and re-run
- Up to 3 attempts per failure
- After 3 failed attempts, use **AskUserQuestion** to ask the user for guidance with context on what failed and what you tried

Fix all lint warnings before proceeding.

### Execution Rules

- Never skip tests. Every fix gets a regression test.
- Never add features not related to the bug (YAGNI).
- If the fix grows beyond the original scope, stop and flag it.
- **Acceptable tradeoffs**: a hotfix may intentionally introduce a lesser issue (e.g., fixing a P0 while accepting a P2 side effect). When this happens, document the tradeoff clearly with a `// TODO(hotfix): <description of known limitation and its severity>` comment in the code and note it in the PR description. The goal is to stop the bleeding, not achieve perfection.
- Ask the user only when genuinely stuck: ambiguous root cause, 3 failed fix attempts, or a missing dependency.

## Phase 4 — Review

Run review agents **in parallel** to validate the fix. Use a reduced set — speed matters, but quality is non-negotiable.

### Agent instructions

Each agent prompt must include the [review agent instructions](references/review-agent-instructions.md).

The 2 agents and their report filenames:

| Agent | Report file |
|-------|------------|
| **@vgv-review-agent** | `docs/hotfix-review/vgv-review.md` |
| **@test-quality-review-agent** | `docs/hotfix-review/test-quality-review.md` |

### After reviews complete

1. **Critical findings** → Read the specific report file (e.g., `docs/hotfix-review/vgv-review.md`) for full details on each critical finding. Fix immediately, re-run validation, and commit. Only read reports that contain critical issues — do not load both reports into context unnecessarily.

2. **Important findings** → use **AskUserQuestion**:
   - **Fix all**: address every important issue (read relevant report files for details)
   - **Skip to shipping**: note them in the PR description

3. **Suggestions** → record for PR description.

### Cleanup

Remove review reports after findings are addressed:

```bash
rm -rf docs/hotfix-review/
```

## Phase 5 — Ship

### Final Validation

Run the project's formatter, linter, and test runner one last time. Fix any failures before proceeding.

### Commit

Create a single, cherry-pick-friendly commit:

- Stage only the files related to the fix (no unrelated changes).
- Write a commit message in this format:

```text
fix: <concise description of what was fixed>

<Root cause explanation in 1-2 sentences>

Bug: <original bug description or issue link, truncated if long>
```

### Pull Request

Push the branch and create a PR using `gh pr create`:

- **Title**: `fix: <concise description>` (under 70 characters)
- **Body**: Use the [PR template](references/pr-template.md)

### Post-Ship

Use **AskUserQuestion** to present options:

1. **Done**: end the session

## Gotchas

- If the bug is in a shared dependency or utility, the fix may affect callers you did not expect. Grep for all usages before changing shared code.
- If the fix requires a migration (database, config, schema), this is likely too large for a hotfix. Recommend switching to `/plan` → `/build`.
- Hotfix branches use the `hotfix/` prefix, not `fix/`. Other skills use `fix/` — do not mix them.
- If `docs/hotfix-review/` already exists from a previous interrupted hotfix, delete it before running Phase 4 to avoid stale reports contaminating the review.
- The blast radius check (Phase 3) uses a threshold of 5 files. A fix that touches exactly 5 files is within threshold; 6 triggers the warning.

## Important

- This skill is for emergency fixes. It trades planning depth for speed, but never trades away quality.
- No brainstorm or plan documents are generated.
- Tests and review are non-negotiable — fast doesn't mean sloppy.
- Keep the diff minimal. A hotfix that grows into a feature rewrite belongs in `/plan` → `/build`.
- The commit must be cherry-pick-friendly: one commit, one concern, no unrelated changes.
