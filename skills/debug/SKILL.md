---
name: debug
user-invocable: true
description: Finds and fixes bugs through structured hypothesis testing and code instrumentation. Use when user says "debug", "debug this", "find the bug", "what's causing this", "troubleshoot", or "why is this broken".
argument-hint: bug description, error message, or reproduction steps
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Debug — structured hypothesis-driven debugging

Find and fix bugs through a structured cycle: hypothesize, instrument, reproduce, analyze, fix, verify. All debug instrumentation is removed at the end, leaving only the fix.

## Bug Description

<bug_description>$ARGUMENTS</bug_description>

**If the bug description above is empty, ask the user**: "What's the bug? Describe the symptoms, paste an error message, or explain how to reproduce it. Include any hypotheses you have about the cause."

DO NOT proceed until you have a bug description.

## Phase 0 — Understand

Summarize the bug in one sentence. Identify:

- **Symptom**: what the user observes (error message, wrong behavior, crash)
- **Suspected area**: which layer or component is likely involved
- **User hypotheses**: any theories the user provided about the cause

If the user did not provide hypotheses, use **AskUserQuestion**: "Do you have any guesses about what might be causing this? Even rough intuitions help narrow the search."

1. **Yes** — let the user describe their hypothesis
2. **No, just investigate** — proceed without user hypotheses

## Phase 1 — Hypothesize

### 1.1. Explore the codebase

Run a focused codebase exploration to understand the area around the bug:

- Task @codebase-review-agent("Locate the code responsible for this behavior. Focus on the symptom described — do not survey the entire codebase. Bug: <bug_description>")

After the agent returns, read the identified files and their immediate context.

### 1.2. Formulate hypotheses

Based on the code exploration and any user hypotheses, formulate **2-5 concrete hypotheses** about what could cause the bug. Each hypothesis must be:

- **Specific**: points to a concrete code path or condition
- **Testable**: can be confirmed or ruled out with debug output
- **Tagged**: assigned an identifier (H1, H2, H3, ...)

Present the hypotheses to the user:

```
## Hypotheses

- **H1**: [description] — test by checking [what to observe]
- **H2**: [description] — test by checking [what to observe]
- **H3**: [description] — test by checking [what to observe]
```

Use **AskUserQuestion**: "Do these hypotheses look right? I'll instrument the code to test them."

1. **Proceed (Recommended)** — instrument and test these hypotheses
2. **Adjust** — modify or add hypotheses before proceeding

### 1.3. Set up workspace

Before writing any files, ensure the session is on a working branch:

- Call @create-branch to check and optionally create a working branch or worktree.

## Phase 2 — Instrument

Add targeted debug instrumentation to test each hypothesis. Follow these rules:

- **Tag every addition** with a comment containing `WINGSPAN-DEBUG` so it can be reliably found and removed later. Use the language's comment syntax (e.g., `// WINGSPAN-DEBUG`, `# WINGSPAN-DEBUG`, `<!-- WINGSPAN-DEBUG -->`).
- **Label output by hypothesis**: each log statement must identify which hypothesis it tests (e.g., `[H1]`, `[H2]`).
- **Log values, not just markers**: capture the actual state (variable values, conditions, return values) that confirms or rules out each hypothesis.
- **Minimize invasiveness**: add logging only — do not change control flow, add dependencies, or modify behavior.
- **Keep it simple**: use the project's existing logging mechanism or standard output. Do not introduce new dependencies.
- **Prefer companion plugin guidance**: if a companion plugin provides debug or logging conventions for the project's stack, follow those over generic defaults.

If the project uses a build or compilation step, run it to confirm the instrumentation compiles. Fix any build failures before proceeding.

After instrumenting, tell the user:

1. Exactly what steps to take to reproduce the bug
2. Where the debug output will appear (console, log file, etc.)
3. What to copy/paste back (or which file to point to)

Use **AskUserQuestion**: "I've added debug instrumentation. Please reproduce the bug and share the output."

1. **Here's the output** — user provides the debug output
2. **Output is in a file** — user provides a path to read
3. **Adjust instrumentation** — the instrumentation needs changes before reproducing

**If "Adjust instrumentation"**: ask what needs to change, update, and re-present instructions.

## Phase 3 — Analyze

Read the debug output. For each hypothesis, determine:

- **Confirmed**: the output shows the suspected condition is true
- **Ruled out**: the output shows the suspected condition is false
- **Inconclusive**: not enough information to decide

### If a hypothesis is confirmed

Summarize the root cause to the user in 2-3 sentences, referencing the specific debug output that confirms it. Proceed to Phase 4.

### If all hypotheses are ruled out

Explain what was learned from ruling them out. Use **AskUserQuestion**:

1. **New hypotheses (Recommended)** — formulate new hypotheses based on what was eliminated, return to Phase 1.2
2. **Add more instrumentation** — keep existing instrumentation and add more, return to Phase 2
3. **Stop** — clean up instrumentation and end (go to Phase 6)

### If inconclusive

Explain what was learned and what remains unclear. Use **AskUserQuestion**:

1. **Refine instrumentation (Recommended)** — adjust logging to get clearer signal, return to Phase 2
2. **New hypotheses** — start fresh with new hypotheses, return to Phase 1.2

## Phase 4 — Fix

### 4.1. Implement the fix

Write the minimal change that addresses the confirmed root cause:

- Change only what is necessary — no drive-by refactors.
- Match surrounding code style.
- If the fix grows beyond the original scope, stop and suggest `/plan` → `/build`.

### 4.2. Remove debug instrumentation

Remove ALL debug instrumentation added in Phase 2. Search for `WINGSPAN-DEBUG` across the codebase and remove every tagged line or block. Verify none remain:

```bash
grep -r "WINGSPAN-DEBUG" .
```

If any remain, remove them. The codebase must contain only the fix — no debug instrumentation.

### 4.3. Validate

Follow the [validation and fix procedure](references/validate-and-fix.md).

## Phase 5 — Verify

Use **AskUserQuestion**: "I've implemented the fix and removed all debug instrumentation. Please reproduce the original bug to confirm it's resolved."

1. **Fixed** — the bug is resolved
2. **Still broken** — describe what happened
3. **New issue introduced** — describe the new problem

**If "Fixed"**: proceed to Phase 7.

**If "Still broken"**: read the user's description. Use **AskUserQuestion**:

1. **Adjust the fix** — root cause was right but fix was incomplete, revise it and return to Phase 4.1
2. **Re-investigate** — root cause hypothesis may be wrong, return to Phase 1 with new information
3. **Stop** — revert all changes and end

**If "New issue introduced"**: fix the regression, re-validate, and ask again.

## Phase 6 — Cleanup Only

Reached when the user stops debugging without a fix.

Remove ALL debug instrumentation. Search for `WINGSPAN-DEBUG` across the codebase:

```bash
grep -r "WINGSPAN-DEBUG" .
```

Remove every match. Confirm to the user that all debug instrumentation has been removed and the codebase is clean.

## Phase 7 — Complete

### Final validation

Run the project's formatter, linter, and test runner one last time. Fix any failures.

### Handoff

Use **AskUserQuestion**: "Bug fixed and verified! What would you like to do next?"

1. **Commit the fix (Recommended)** — create a commit with the fix
2. **Add a regression test first** — write a test that reproduces the original bug, then commit
3. **Done** — end the session

**If "Commit the fix"**: create a single commit:

```text
fix: <concise description of what was fixed>

Root cause: <1-2 sentence explanation>
```

**If "Add a regression test first"**: write a test that fails without the fix and passes with it. Run validation, then create the commit.

## Gotchas

- The `WINGSPAN-DEBUG` tag is the single source of truth for cleanup. Every debug addition must include it — no exceptions.
- If the bug is non-deterministic (race condition, flaky test), instrumentation may need multiple reproduction attempts. Ask the user to reproduce several times if needed.
- If more than 3 hypothesis-test cycles pass without progress, suggest a different approach: `/brainstorm` for deeper analysis or pairing with a teammate.
- Debug instrumentation must never be committed. Phase 4.2 and Phase 6 exist specifically to prevent this.
- If the user's reproduction environment differs from the development environment (production, staging, specific device), note that instrumentation must be compatible with that environment.

## Evaluation queries

### Should trigger
1. "Debug this crash — the app dies when I tap the submit button."
2. "What's causing the test failure in the auth module?"
3. "Help me find the bug — users report stale data after refresh."
4. "Troubleshoot why the API returns 500 on this specific payload."
5. "Why is this broken? It worked yesterday before the deploy."

### Should NOT trigger
1. "Add a dark mode toggle to the settings screen."
2. "Review this PR before I merge it."
3. "Write unit tests for the checkout flow."
4. "Refactor the data layer to use the repository pattern."
5. "Create a plan for the new onboarding feature."

### Edge cases
1. "This test is flaky — passes locally, fails in CI." (debugging-adjacent; should trigger)
2. "The build is broken." (may be a config issue, not a code bug; should trigger)
3. "Performance is slow on the dashboard page." (performance investigation, not a bug; should not trigger — suggest `/brainstorm` instead)

## Important

- This skill is interactive. It requires the user to reproduce bugs and report results between phases.
- Keep debug instrumentation minimal and tagged. Every addition gets `WINGSPAN-DEBUG`.
- The goal is to narrow down the root cause systematically, not to guess-and-check.
- Remove all debug instrumentation before finishing — the only lasting change should be the fix itself.
