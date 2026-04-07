---
name: build
user-invocable: true
description: Executes an implementation plan — writes code and tests, runs quality review, and ships a pull request. Use when user says "build this", "implement the plan", "start coding", "execute the plan", or "ship it".
effort: high
argument-hint: plan file path
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
- [ ] Phase 2: Implement and test each task
- [ ] Phase 3: Run review agents (5 in parallel)
- [ ] Phase 4: Final validation, cleanup, and ship
```

## Plan Input

<plan_path>$ARGUMENTS</plan_path>

## Available Plans

```!
ls -1 docs/plan/*.md 2>/dev/null || echo "(no plans found)"
```

## Phase 0 — Load Plan

**If the plan path above is empty:**

1. Check the available plans listed above.

Then:

1. **If exactly one plan exists:** Read the plan, announce "Found plan: [title]. Using this for implementation.", and proceed with it. No need to ask the user.
2. **If multiple plans exist:** Use **AskUserQuestion** to ask which plan to execute, listing each plan filename with a brief summary from the first heading.
3. **If no plans exist:** Tell the user: "No plans found in `docs/plan/`. Run `/plan` first to create an implementation plan."

Do not proceed without a plan.

**If the plan path is provided:**

1. Read the plan file
2. If the file doesn't exist, tell the user and suggest running `/plan`

**After loading the plan:**

1. Parse the plan and extract:
   - Title and type (feat, fix, refactor, etc.)
   - Acceptance criteria
   - Implementation tasks/phases
   - File paths referenced
2. Summarize the scope to the user: number of tasks, files to create/modify, estimated complexity
3. Use **AskUserQuestion** to confirm:
   - **Start building (Recommended)**: proceed with implementation
   - **Review the plan first**: open the plan file for the user to review
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

Write code following VGV conventions:

- **Layer order**: Data → Domain → Presentation. Build dependencies before dependents.
- **State management**: Use the project's chosen state management tool, following VGV conventions.
- **Style**: Follow VGV naming and style conventions. Detect the project's linter and formatter.
- **File naming**: Follow the project's existing patterns.
- **Imports**: Respect layer boundaries. Presentation never imports data directly.

### Step 2: Test

Tests are non-negotiable. Write them alongside each implementation unit:

- **State management**: Use VGV testing conventions with the project's testing framework. Cover success, failure, and edge cases. Seed initial states when testing non-initial conditions.
- **UI components**: Follow VGV's UI testing conventions with proper wrappers and providers. Test all rendered states and user interactions. Wait for async state changes before asserting.
- **Repositories/Data**: Unit tests for serialization, API calls, error handling, and edge cases.
- **Utilities**: Pure functions get unit tests.

Every new state management unit, repository, UI component, and data model must have a test file.

### Step 3: Validate

After implementing each task, in order:

Run static analysis — detect and use the project's linter/analyzer.

Run tests — detect and use the project's test runner.

If failures occur:
- Fix the issue and re-run
- Up to 3 attempts per failure
- After 3 failed attempts, use **AskUserQuestion** to ask the user for guidance with context on what failed and what you tried

Fix all lint warnings before proceeding.

### Step 4: Checkpoint

After each logical unit of work:

1. Brief progress update to the user: what was completed, what's next.

### Execution Rules

- Follow the plan's task order. Don't skip ahead.
- Never skip tests. Every testable unit gets a test file.
- Never add features not in the plan (YAGNI).
- Ask the user only when genuinely stuck: ambiguous architecture decision, 3 failed fix attempts, or a missing dependency not mentioned in the plan.
- If a task in the plan is unclear, re-read the plan and the relevant codebase context before asking the user.

## Phase 3 — Quality Review

After all implementation tasks are complete, run 5 review agents **in parallel**.

### Agent instructions

Each agent prompt must include the [review agent instructions](references/review-agent-instructions.md).

The 5 agents and their report filenames:

| Agent | Report file |
| ----- | ----------- |
| **@vgv-review-agent** | `docs/reviews/vgv-review.md` |
| **@code-simplicity-review-agent** | `docs/reviews/code-simplicity-review.md` |
| **@test-quality-review-agent** | `docs/reviews/test-quality-review.md` |
| **@architecture-review-agent** | `docs/reviews/architecture-review.md` |
| **@pr-readiness-review-agent** | `docs/reviews/pr-readiness-review.md` |

### After all reviews complete

1. **Consolidate findings** from all summaries into three categories:
   - **Critical** (must fix before merge): Bugs, missing tests, layer violations, broken analysis
   - **Important** (should fix): Convention deviations, test gaps, naming issues
   - **Suggestions** (note for PR): Style improvements, minor simplifications

2. **Auto-fix minor issues**: formatting (run the project's formatter), lint warnings. Stage and commit fixes.

3. **Fix critical issues**: Read the specific report file (e.g., `docs/reviews/architecture-review.md`) for full details on each critical finding. Address each one, re-run validation (project's linter and test runner), and commit. Only read reports that contain critical issues — do not load all 5 reports into context.

4. **Present important issues** to the user via **AskUserQuestion**:
   - **Fix all**: address every important issue (read relevant report files for details)
   - **Review the list first**: show the full list for the user to decide
   - **Skip to shipping**: note them in the PR description instead

5. **Record suggestions** for inclusion in the PR description.

## Phase 4 — Ship

### Final Validation

Run the full suite one last time — detect and use the project's formatter, linter, and test runner.

If anything fails, fix it before proceeding.

### Cleanup

Remove the review reports — their findings have already been addressed or recorded:

```bash
rm -rf docs/reviews/
```

### Open PR

Call the **create-pr** skill with `skip-checks` (validation already ran above):

```bash
/create-pr skip-checks
```

### Commit

Stage all implementation and fix changes. Write a commit message:

```text
<type>: <concise description of what was built>

Implements <plan title or summary>.
```

Where `<type>` matches the plan's type (`feat`, `fix`, `refactor`, etc.).

### Pull Request

Push the branch and create a PR using `gh pr create`:

- **Title**: `<type>: <concise description>` (under 70 characters)
- **Body**: Use the [PR template](references/pr-template.md)

### Post-Ship

Use **AskUserQuestion** to present options:

- **Done**: end the session

## Gotchas

- If the plan references a package or dependency that does not exist yet, install or create it before writing code that imports it. Do not assume dependencies are already available.
- If tests fail mid-build, fix the failing test before moving to the next task. Do not accumulate broken tests across tasks.
- Generated files (mocks, codegen output) must be regenerated after code changes — stale generated files cause confusing test failures.
- If the plan specifies file paths that conflict with existing files, confirm with the user before overwriting. The codebase may have changed since the plan was written.
- Review agent reports are written to `docs/reviews/` and deleted after Phase 4. If the build is interrupted, stale reports may remain — delete them manually before the next run.

## Important

- This skill writes code. It is the execution phase, not the planning phase.
- Follow the plan. The plan was reviewed and approved. Don't redesign during implementation.
- Ship quality, not quantity. Every line represents VGV's engineering reputation.
- When in doubt, read the plan again before asking the user.
