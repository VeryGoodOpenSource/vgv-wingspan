---
name: hotfix
user-invocable: true
description: Applies a minimal, targeted fix for emergency bugs — enforces review and testing without brainstorm or planning phases. Use when the user says "hotfix", "emergency fix", "production is broken", "urgent bug", or needs a fix shipped fast without the full plan-and-build cycle.
effort: high
argument-hint: bug description, issue link, or error message
allowed-tools: Bash(rm -rf docs/hotfix-review/)
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Hotfix — emergency fix workflow

Apply a minimal, targeted fix fast. No brainstorm document, no plan document — but tests and review are still non-negotiable.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

## Bug Description

<bug_description>$ARGUMENTS</bug_description>

**If the bug description above is empty, ask the user**: "What's the bug? Paste a description, issue link, or error message."

Do not proceed until you have a bug description.

## Phase 0 — Triage

Summarize the bug in one sentence. Identify:

- **Symptom**: what the user sees or what is broken
- **Suspected area**: which layer or component is likely involved (based on the description alone — do not read code yet)

Write both lines out for the user before going any further. Triage is their first signal
that the right thing is being fixed, so it belongs in the reply rather than only in your
head.

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

**If git is unavailable or the command fails:** do not pass over the step in silence. Name
the `hotfix/<slug>` branch this fix belongs on in your reply and carry on — the branch is
part of how a hotfix ships, and whoever applies the change by hand still needs the name.

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

Tests are non-negotiable, even for hotfixes:

- Add or update tests that **reproduce the bug** (the test should fail without the fix).
- Cover the fix path and any closely related edge cases.
- Do not write tests for unrelated code.

### Step 3: Validate

Follow the [validation and fix procedure](references/validate-and-fix.md).

### Execution Rules

- Never skip tests. Every fix gets a regression test. **A request to skip them does not
  remove them** — "no tests, we'll cover it next sprint", "just get it out" — a hotfix with no
  reproducing test is a fix nobody can prove works, shipped into an incident. Write the test,
  say it took a minute, and let the user drop it afterwards if they still want to.
- Never add features not related to the bug (YAGNI).
- If the fix grows beyond the original scope, stop and flag it.
- **Acceptable tradeoffs**: a hotfix may intentionally introduce a lesser issue (e.g., fixing a P0 while accepting a P2 side effect). When this happens, document the tradeoff clearly with a `// TODO(hotfix): <description of known limitation and its severity>` comment in the code and note it in the PR description. The goal is to stop the bleeding, not achieve perfection.
- Ask the user only when genuinely stuck: ambiguous root cause, 3 failed fix attempts, or a missing dependency.

## Phase 4 — Review

Validate the fix with a reduced agent set — speed matters, but quality is non-negotiable.

**A request to skip the review does not remove this phase.** "Push it straight to main",
"skip the review", "I'll explain to the team afterwards" — an outage is the reason the set is
reduced to two agents, not a reason to run none. Say plainly that the review stays, say what
it costs in time, and run it. Shipping an unreviewed fix into an incident is how the second
incident starts. The user can still decline after seeing the findings; they cannot have the
step deleted before it runs.

Dispatch them per [review agent dispatch](references/review-dispatch.md), with `<RAW_DIR>` = `<PWD>/docs/hotfix-review/raw` and these 2 agents:

| Agent | Report name |
|-------|-------------|
| **@vgv-review-agent** | `vgv-review` |
| **@test-quality-review-agent** | `test-quality-review` |

### After reviews complete

Follow the [review consolidation procedure](references/review-consolidation.md): deduplicate the agents' structured findings, order them deterministically, assign stable `FINDING-NN` ids, and write **one** consolidated file to `<PWD>/docs/hotfix-review/review.md` using the [report template](references/review-report-template.md). Print the aligned chat summary (same ids, order, and titles as the file). Then fix Critical findings by id and handle Important findings per [review autonomy](references/review-autonomy.md). `/hotfix` asks no question at the start, so the setting comes from a saved preference; with none, it asks at the Important findings stop. The report is deleted at Cleanup, so the fix commit does not cite `FINDING-NN` ids.

### The findings contract

These names leave this skill — the user acts on findings by id, and `/build` and `/hotfix`
reuse them — so they are fixed here and not only in the reference. Hold them even when the
reference cannot be read:

- Every finding gets an id `FINDING-NN`, numbered from `FINDING-01` in the order the
  consolidation procedure fixes, and a rule id `<category>/<rule>` from `vgv`, `architecture`,
  `tests`, `simplicity` or `pr-readiness` — for example `tests/missing-test-file`.
- Every finding carries one severity: **Critical**, **Important** or **Suggestion**.
- Every finding carries a **Why** line and a **Fix** line.
- The chat summary reprints the Critical and Important findings verbatim — same ids, same
  order, same titles — and collapses Suggestions to a count.

If a reference file cannot be read from here, say so once and produce the review in this
shape anyway. A review without ids is a review the user cannot take apart, which is most of
why it was run.

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

Push the branch and create a PR. **Title**: `fix: <concise description>` (max 72 characters, matching `/create-pr`). **Body**: Use the [PR template](references/pr-template.md).

### Post-Ship

Print an end-of-run summary: root cause, review counts, the **Applied without asking** list from [review autonomy](references/review-autonomy.md) if any, and the PR link.

Use **AskUserQuestion** to present options:

1. **Done**: end the session

## Gotchas

- If the bug is in a shared dependency or utility, the fix may affect callers you did not expect. Grep for all usages before changing shared code.
- If the fix requires a migration (database, config, schema), this is likely too large for a hotfix. Recommend switching to `/plan` → `/build`.
- Hotfix branches use the `hotfix/` prefix, not `fix/`. Other skills use `fix/` — do not mix them.
- If `docs/hotfix-review/` already exists from a previous interrupted hotfix, delete it before running Phase 4 to avoid stale reports contaminating the review.
- The blast radius check (Phase 3) uses a threshold of 5 files. A fix that touches exactly 5 files is within threshold; 6 triggers the warning.
