---
name: build
description: Execute an implementation plan — write code and tests and run quality review, and ship a pull request following VGV conventions.
---

# Execute an implementation plan

Take a plan from `wingspan/plans/` and turn it into shipped code: implement features, write tests, and validate quality.

## Plan Input

<plan_path> #$ARGUMENTS </plan_path>

## Phase 0 — Load Plan

**If the plan path above is empty:**

1. List available plans:

```bash
ls -la wingspan/plans/*.md 2>/dev/null | head -20
```

Then:

1. If plans exist, use **AskUserQuestion** to ask which plan to execute, listing each plan filename with a brief summary from the first heading.
2. If no plans exist, tell the user: "No plans found in `wingspan/plans/`. Run `/plan` first to create an implementation plan."

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
   - **Start building**: proceed with implementation
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

- **Layer order**: Data -> Domain -> Presentation. Build dependencies before dependents.
- **State management**: Bloc/Cubit. Cubit for simple state, Bloc when events add clarity.
- **Style**: `const` constructors, `final` variables, named parameters for 3+ params, trailing commas.
- **Naming**: Descriptive. Bloc events end with verbs (`Requested`, `Submitted`). States describe conditions (`Initial`, `Loading`, `Failure`).
- **File naming**: Follow the project's existing patterns. Match snake_case convention.
- **Imports**: Respect layer boundaries. Presentation never imports data directly.

### Step 2: Test

Tests are non-negotiable. Write them alongside each implementation unit:

- **Bloc/Cubit**: `blocTest` from `bloc_test`, mocks from `mocktail`. Cover success, failure, and edge cases. Seed initial states when testing non-initial conditions.
- **Widgets**: `pumpWidget` with proper ancestors (`MaterialApp`, `BlocProvider`, etc.). Test all rendered states. Use `tester.tap`, `tester.enterText` for interactions. Call `pump()` after state changes.
- **Repositories/Data**: Unit tests for serialization (`fromJson`/`toJson`), API calls, error handling, and edge cases.
- **Utilities**: Pure functions get unit tests.

Every new Bloc, Cubit, repository, widget, and data model must have a test file.

### Step 3: Validate

After implementing each task, in order:

Run static analysis:

```bash
dart analyze --fatal-infos
# or for Flutter projects:
flutter analyze
```

Run tests:

```bash
dart test
# or for Flutter projects:
flutter test
```

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

After all implementation tasks are complete, run 5 review agents **in parallel**:

- **@vgv-review-agent** — VGV standards, conventions, and patterns
- **@code-simplicity-review-agent** — YAGNI audit and simplification opportunities
- **@test-quality-review-agent** — Test coverage and quality
- **@architecture-review-agent** — Layer separation and Bloc/Cubit correctness
- **@pr-readiness-review-agent** — Formatting, analysis, debug artifacts, commit hygiene

After all reviews complete:

1. **Consolidate findings** into three categories:
   - **Critical** (must fix before merge): Bugs, missing tests, layer violations, broken analysis
   - **Important** (should fix): Convention deviations, test gaps, naming issues
   - **Suggestions** (note for PR): Style improvements, minor simplifications

2. **Auto-fix minor issues**: formatting (`dart format`), missing `const`, lint warnings. Stage and commit fixes.

3. **Fix critical issues**: Address each critical finding, re-run validation (`dart analyze`, `dart test`), and commit.

4. **Present important issues** to the user via **AskUserQuestion**:
   - **Fix all**: address every important issue
   - **Review the list first**: show the full list for the user to decide
   - **Skip to shipping**: note them in the PR description instead

5. **Record suggestions** for inclusion in the PR description.

## Phase 4 — Ship

### Final Validation

Run the full suite one last time:

```bash
dart format --set-exit-if-changed .
dart analyze --fatal-infos
dart test
# or flutter equivalents
```

If anything fails, fix it before proceeding.

### Post-Ship

Use **AskUserQuestion** to present options:

- **Done**: end the session

## Important

- This skill writes code. It is the execution phase, not the planning phase.
- Follow the plan. The plan was reviewed and approved. Don't redesign during implementation.
- Ship quality, not quantity. Every line represents VGV's engineering reputation.
- When in doubt, read the plan again before asking the user.
