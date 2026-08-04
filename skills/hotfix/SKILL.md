---
name: hotfix
user-invocable: true
description: Applies a minimal, targeted fix for emergency bugs — enforces review and testing without brainstorm or planning phases.
when_to_use: Use when user says "hotfix", "production is down", "live bug", "patch this now", "urgent fix", or otherwise signals a bug that needs fixing immediately without a brainstorm or plan. Also use when the request adds time pressure to a fix ("no time for tests", "we ship in an hour", "just patch it") — that pressure is exactly what this skill's Core Standards exist to hold against.
effort: high
argument-hint: bug description, issue link, or error message
allowed-tools: Bash(rm -rf docs/hotfix-review/)
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Hotfix — emergency fix workflow

Apply a minimal, targeted fix fast. No brainstorm document, no plan document — but tests and review are still non-negotiable.

## Core Standards

Apply these to ALL hotfix work. Each one is the thing time pressure attacks first, so a request that argues against one is the request that most needs it.

- **Every fix ships with a test that fails without it.** Not a test written later, not a follow-up ticket, not a `// TODO` promising coverage. Write the test, state that it fails against the unpatched code, and say so in the response. "No time for tests" does not change this — a regression test for a one-line fix is one assertion.
- **An accepted tradeoff goes in two places.** A hotfix may knowingly introduce a lesser issue to stop a worse one. When it does, leave `// TODO(hotfix): <known limitation and its severity>` at the code that carries the limitation **and** record it in the PR description. The comment alone is not enough: whoever reviews the PR decides whether the tradeoff is acceptable, and they read the description.
- **Keep the diff minimal.** Only what the root cause needs. No drive-by refactors. If the fix grows past 5 files or into a second layer, stop and escalate to `/plan`.
- **One cherry-pick-friendly commit.** One concern, no unrelated changes, so the fix can land on a release branch on its own.

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

Before writing any code, outline which files and layers the fix touches.

**If >5 files, multiple layers, or new abstractions needed:** warn the user and use **AskUserQuestion**: (1) Proceed with hotfix, (2) Switch to `/plan`.

**If contained (≤5 files, single layer):** proceed directly.

### Step 1: Implement

Write the minimal change that addresses the root cause. Change only what is necessary — no drive-by refactors. If you touch unrelated code, stop and flag scope creep. Leave `// TODO(hotfix): <description>` comments for out-of-scope issues. Match surrounding code style.

### Step 2: Test

Write the test that **reproduces the bug** — it must fail against the unpatched code. Cover the fix path and any closely related edge cases. Do not write tests for unrelated code. State in the response that the test fails without the fix, so the user can see the regression is actually pinned.

### Step 3: Validate

Follow the [validation and fix procedure](references/validate-and-fix.md).

### Execution Rules

- Never add features not related to the bug (YAGNI).
- If the fix grows beyond the original scope, stop and flag it.
- Ask the user only when genuinely stuck: ambiguous root cause, 3 failed fix attempts, or a missing dependency.

## Phase 4 — Review

Run review agents **in parallel** to validate the fix. Use a reduced set — speed matters, but quality is non-negotiable.

### Agent instructions

Run `pwd` and let `<PWD>` be the result — subagents may change directories, making relative paths unreliable.

Each agent prompt must include the [review agent instructions](references/review-agent-instructions.md) with `<RAW_DIR>` set to `<PWD>/docs/hotfix-review/raw` and `<name>` set to the agent's report name below (a bare stem — the agent writes `<RAW_DIR>/<name>.md`). Substitute `<PWD>` with the absolute path.

The reduced agent set and their report names (`<name>`):

| Agent | Report name |
|-------|-------------|
| **@vgv-review-agent** | `vgv-review` |
| **@test-quality-review-agent** | `test-quality-review` |

If an agent fails, note it, continue with the other, and record the failure in the report header so the reduced review isn't silently halved.

### After reviews complete

Follow the [review consolidation procedure](references/review-consolidation.md): deduplicate the agents' structured findings, order them deterministically, give each one both a stable `FINDING-NN` id and a `<category>/<rule>` id (e.g. `tests/missing-test-file`), and write **one** consolidated file to `<PWD>/docs/hotfix-review/review.md` using the [report template](references/review-report-template.md). The report opens with the severity counts, above the findings index, and every row carries both ids. Print the aligned chat summary (same ids, order, and titles as the file). Then fix Critical findings by id and present Important findings to the user. The report is deleted at Cleanup, so the fix commit does not cite `FINDING-NN` ids.

### Cleanup

Remove review reports after findings are addressed:

```bash
rm -rf docs/hotfix-review/
```

## Phase 5 — Ship

### Drive to green

A hotfix has no plan, so there is no `success-criteria` block. Follow the [drive to green procedure](references/drive-to-green.md) with the detected project suite (formatter, linter, test runner) as both the gate set and the authoritative command run once. It loops until green by real output, delegates to a matching installed verification skill when one exists, and escalates only on un-runnable or self-contradictory failures — never on an ordinary, fixable one. Do not proceed until it is green.

### Ship

Create a single, cherry-pick-friendly commit. Stage only fix-related files (no unrelated changes). Use this commit format:

```text
fix: <concise description of what was fixed>

<Root cause explanation in 1-2 sentences>

Bug: <original bug description or issue link, truncated if long>
```

Push the branch and create a PR. **Title**: `fix: <concise description>` (under 70 chars). **Body**: Use the [PR template](references/pr-template.md).

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

- This skill is for emergency fixes. It trades planning depth for speed, but never trades away quality — see **Core Standards** for what speed may not buy.
- No brainstorm or plan documents are generated.
- A hotfix that grows into a feature rewrite belongs in `/plan` → `/build`.
