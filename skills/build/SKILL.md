---
name: build
user-invocable: true
description: Executes an implementation plan — writes code and tests, runs quality review, and ships a pull request.
when_to_use: Use when user says "build this", "implement the plan", "start coding", "execute the plan", or "ship it".
effort: high
argument-hint: plan file path
allowed-tools: Bash(rm -rf docs/reviews/)
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Execute an implementation plan

Take a plan from `docs/plan/` and turn it into shipped code: implement features, write tests, and validate quality.

## Build Progress

Copy this checklist and track your progress:

```markdown
Build Progress:
- [ ] Phase 0: Load plan and confirm scope
- [ ] Phase 1: Read context files
- [ ] Phase 2: Implement, test, and run the surgical-diff gate
- [ ] Phase 3: Run review agents (5 in parallel), consolidate into one report
- [ ] Phase 4: Final validation, cleanup, and ship
```

## Plan Input

<plan_path>$ARGUMENTS</plan_path>

## Phase 0 — Load Plan

```bash
ls docs/plan/
```

| Plan path | Plans in `docs/plan/` | Action |
|-----------|-----------------------|--------|
| Provided | — | Read the file. If missing, suggest running `/plan` |
| Empty | One | Read it, announce "Found plan: [title]", proceed |
| Empty | Multiple | **AskUserQuestion**: list each with summary, ask which to use |
| Empty | None | Tell user to run `/plan` first |

Do not proceed without a plan.

**After loading the plan:** parse title, type, acceptance criteria, tasks, and file paths. Summarize scope to the user, then use **AskUserQuestion** to confirm:

- **Start building (Recommended)**: proceed with implementation
- **Review the plan first**: open the plan file for review
- **Adjust scope**: accept user input on what to change

Do not proceed until the user selects "Start building."

## Phase 1 — Setup

**Do not run `codebase-review-agent` here.** The plan was already informed by codebase context from `/brainstorm` and `/plan`.

Instead, use the plan itself as your guide:

1. **Read referenced files**: Read every file listed in the plan's tasks (files to create or modify) plus their immediate neighbors (e.g., sibling files in the same directory) for implementation context.
2. **Extract conventions**: If the plan includes a codebase context or conventions section, use it as your source of truth for patterns and style.
3. **Targeted searches only**: If the plan references a pattern or convention you need a concrete example of, use Grep or Glob to find a single representative example — do not do a broad sweep.

## Phase 2 — Execute

Work through each task/phase in the plan, in order. For each task:

### Step 1: Implement

Write code following VGV conventions. Build layers in dependency order (Data → Domain → Presentation). Use the project's state management tool, naming patterns, linter, and formatter. Respect layer boundaries — presentation never imports data directly.

### Step 2: Test

Tests are non-negotiable. Write them alongside each implementation unit:

- **State management**: Use VGV testing conventions with the project's testing framework. Cover success, failure, and edge cases. Seed initial states when testing non-initial conditions.
- **UI components**: Follow VGV's UI testing conventions with proper wrappers and providers. Test all rendered states and user interactions. Wait for async state changes before asserting.
- **Repositories/Data**: Unit tests for serialization, API calls, error handling, and edge cases.
- **Utilities**: Pure functions get unit tests.

Every new state management unit, repository, UI component, and data model must have a test file.

### Step 3: Validate

After implementing each task, follow the [validation and fix procedure](references/validate-and-fix.md).

### Step 4: Checkpoint

After each logical unit of work:

1. Brief progress update to the user: what was completed, what's next.

### Execution Rules

- Follow the plan's task order. Don't skip ahead.
- Never skip tests. Every testable unit gets a test file.
- Never add features not in the plan (YAGNI).
- Ask the user only when genuinely stuck: ambiguous architecture decision, 3 failed fix attempts, or a missing dependency not mentioned in the plan.
- If a task in the plan is unclear, re-read the plan and the relevant codebase context before asking the user.

### Surgical-Diff Gate

Once every task is implemented, tested, and validated, follow the [surgical-diff gate](references/surgical-diff-gate.md) before moving to review: diff the whole branch against its merge-base, remove untraceable churn, delete only self-created orphans, and collect a "Noticed (not changed):" note for pre-existing dead code. Running it here keeps the review phase focused on the diff that belongs, not churn that would be reverted anyway.

## Phase 3 — Quality Review

After all implementation tasks are complete, run 5 review agents **in parallel**.

### Agent instructions

Run `pwd` and let `<PWD>` be the result — subagents may change directories, making relative paths unreliable.

Each agent prompt must include the [review agent instructions](references/review-agent-instructions.md) with `<RAW_DIR>` set to `<PWD>/docs/reviews/raw` and `<name>` set to the agent's report name below (a bare stem — the agent writes `<RAW_DIR>/<name>.md`). Substitute `<PWD>` with the absolute path.

The 5 agents and their report names (`<name>`):

| Agent | Report name |
| ----- | ----------- |
| **@vgv-review-agent** | `vgv-review` |
| **@architecture-review-agent** | `architecture-review` |
| **@test-quality-review-agent** | `test-quality-review` |
| **@code-simplicity-review-agent** | `code-simplicity-review` |
| **@pr-readiness-review-agent** | `pr-readiness-review` |

If an agent fails, note it, continue with the rest, and record the failure in the report header.

### After all reviews complete

Follow the [review consolidation procedure](references/review-consolidation.md): deduplicate the agents' structured findings, order them deterministically, assign stable `FINDING-NN` ids, and write **one** consolidated file to `<PWD>/docs/reviews/review.md` using the [report template](references/review-report-template.md). Print the aligned chat summary (same ids, order, and titles as the file). Then act: auto-fix minor issues, fix Critical findings by id, present Important findings to the user, and note any still-deferred findings in the PR description.

## Phase 4 — Ship

### Final Validation

Run the full suite one last time — detect and use the project's formatter, linter, and test runner.

If anything fails, fix it before proceeding.

### Cleanup

Remove the review reports — their findings have already been addressed or recorded:

```bash
rm -rf docs/reviews/
```

### Commit

Stage all implementation and fix changes. Use this commit format:

```text
<type>: <concise description of what was built>

Implements <plan title or summary>.
```

Where `<type>` matches the plan's type (`feat`, `fix`, `refactor`, etc.). Review findings are
fixed in place during Phase 3 and the report is deleted at Cleanup, so the commit does not
cite `FINDING-NN` ids (there would be no report left to map them to).

### Ship

Call `/create-pr skip-checks` to push and open a PR. Validation already ran above. The PR body uses the [PR template](references/pr-template.md).

### Post-Ship

Use **AskUserQuestion** to present options:

- **Done**: end the session

## Gotchas

- If the plan references a package or dependency that does not exist yet, install or create it before writing code that imports it. Do not assume dependencies are already available.
- If tests fail mid-build, fix the failing test before moving to the next task. Do not accumulate broken tests across tasks.
- Generated files (mocks, codegen output) must be regenerated after code changes — stale generated files cause confusing test failures.
- If the plan specifies file paths that conflict with existing files, confirm with the user before overwriting. The codebase may have changed since the plan was written.
- The consolidated report (`docs/reviews/review.md`) and per-agent raw reports (`docs/reviews/raw/`) are deleted after Phase 4. If the build is interrupted, stale reports may remain — delete `docs/reviews/` manually before the next run.

## Important

- This skill writes code. It is the execution phase, not the planning phase.
- Follow the plan. The plan was reviewed and approved. Don't redesign during implementation.
- Ship quality, not quantity. Every line represents VGV's engineering reputation.
- When in doubt, read the plan again before asking the user.
