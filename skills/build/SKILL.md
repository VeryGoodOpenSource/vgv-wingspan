---
name: build
user-invocable: true
description: Executes an implementation plan — writes code and tests, runs quality review, and ships a pull request. Use when the user says "build this", "implement the plan", "start coding", "execute the plan", or "ship it".
effort: high
argument-hint: plan file path
allowed-tools: Bash(rm -rf docs/reviews/)
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Execute an implementation plan

Take a plan from `docs/plan/` and turn it into shipped code: implement features, write tests, and validate quality. This is the execution phase. The plan was already reviewed and approved — follow it rather than redesigning it.

## Build Progress

Copy this checklist and track your progress:

```markdown
Build Progress:
- [ ] Phase 0: Load plan and confirm scope (or resume a phased build)
- [ ] Phase 1: Read context for the current implementation phase
- [ ] Phase 2: Loop implementation phases (implement → validate → commit or hand off → checkpoint → clear)
- [ ] Phase 3: Run review agents (5 in parallel), consolidate into one report
- [ ] Phase 4: Drive to green, cleanup, and ship
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

**After loading the plan:** parse title, type, the `success-criteria` block, tasks, file paths, and the `## Implementation Phases` section if present.

**Commit autonomy:** settle it now, before any code is written, per [commit autonomy](references/commit-autonomy.md). The choice holds for the whole run.

**Resuming a phased build:** if the plan has an `## Implementation Phases` section with at least one phase already marked `**Status:** Done`, this is a resumed build. Announce "Resuming at Phase N: [name]" — the first phase whose status is not `Done` — and go straight to Phase 1 for that phase. Skip the scope-confirmation question below.

**Otherwise**, summarize scope to the user, then use **AskUserQuestion** to confirm:

- **Start building (Recommended)**: proceed with implementation
- **Review the plan first**: open the plan file for review
- **Adjust scope**: accept user input on what to change

Do not proceed until the user selects "Start building."

## Phase 1 — Setup

**Do not run `codebase-review-agent` here.** The plan was already informed by codebase context from `/brainstorm` and `/plan`.

Instead, use the plan itself as your guide:

1. **Read referenced files**: Read the files for the phase you are about to build (the current phase's **Files touched**, plus their immediate neighbors). For a plan with no `## Implementation Phases` section, read every file listed in the plan's tasks. Reading only the current phase's files keeps context focused so each phase fits in one window.
2. **Extract conventions**: If the plan includes a codebase context or conventions section, use it as your source of truth for patterns and style.
3. **Targeted searches only**: If the plan references a pattern or convention you need a concrete example of, use Grep or Glob to find a single representative example — do not do a broad sweep.

## Phase 2 — Execute

Determine the unit of work:

- **Plan has an `## Implementation Phases` section** → build one phase at a time with the phase loop below. Each phase carries the fields defined in the [implementation phases block](references/implementation-phases.md) — Status, Scope, Files touched, Acceptance criteria, and Validation — and is sized to fit a single context window, so `/build` executes one phase per window.
- **No phases** → treat the whole plan as one phase: implement every task, then run the loop once.

### Phase loop

Pick the current phase — the first whose `**Status:**` is not `Done` (a plan with no phases has one implicit phase: the whole plan). Run these steps for it:

#### Step 1: Implement

Write code following VGV conventions, limited to this phase's **Scope** and **Files touched**. Build layers in dependency order (Data → Domain → Presentation). Use the project's state management tool, naming patterns, linter, and formatter. Respect layer boundaries — presentation never imports data directly.

#### Step 2: Test

Tests are non-negotiable. Write them alongside each implementation unit:

- **State management**: Use VGV testing conventions with the project's testing framework. Cover success, failure, and edge cases. Seed initial states when testing non-initial conditions.
- **UI components**: Follow VGV's UI testing conventions with proper wrappers and providers. Test all rendered states and user interactions. Wait for async state changes before asserting.
- **Repositories/Data**: Unit tests for serialization, API calls, error handling, and edge cases.
- **Utilities**: Pure functions get unit tests.

Every new state management unit, repository, UI component, and data model must have a test file.

#### Step 3: Validate

Run the phase's **Validation** steps, then follow the [validation and fix procedure](references/validate-and-fix.md). Everything must pass before you record the phase.

#### Step 4: Record the phase

Set this phase's `**Status:**` to `Done` in the plan file — this marker lets a build resume the right phase after a context clear (the plan is a local artifact, so it survives `/clear`).

Then handle the phase's changes per the [commit autonomy](references/commit-autonomy.md) chosen in Phase 0.

#### Step 5: Checkpoint

Brief progress update to the user: phase completed, phases remaining.

#### Step 6: Advance

- **More phases remain, auto-commit mode** → use **AskUserQuestion**:
  1. **Clear context and continue (Recommended)**: build the next phase in a fresh window. Follow the [clear context handoff](references/clear-context-handoff.md) with `<NEXT_SKILL>` = `build`, `<DOC_PATH>` = this plan's path, and `<NEXT_ACTION>` = "the next phase". Then **stop**.
  2. **Continue in this context**: loop back and build the next phase now.
  3. **Stop here**: end the session; the plan's `**Status:**` markers record which phases remain.
- **More phases remain, I'll-commit-myself mode** → **stop**. Tell the user the phase is ready to review and commit, then to run `/build` on this plan again to continue with the next phase (it resumes from the `**Status:**` markers).
- **No phases remain** (last phase done, or the plan had none) → proceed to the Surgical-Diff Gate.

### Execution Rules

- Follow the plan's phase and task order. Don't skip ahead.
- Build only the current phase. Do not pull work forward from a later phase.
- Never skip tests. Every testable unit gets a test file.
- Never add features not in the plan (YAGNI).
- Ask the user only when genuinely stuck: ambiguous architecture decision, 3 failed fix attempts, or a missing dependency not mentioned in the plan.
- If a phase or task is unclear, re-read the plan and the relevant codebase context before asking the user.

### Surgical-Diff Gate

Once the final phase is committed, follow the [surgical-diff gate](references/surgical-diff-gate.md) before moving to review: diff the whole branch against its merge-base, remove untraceable churn, delete only self-created orphans, and collect a "Noticed (not changed):" note for pre-existing dead code. Commit any cleanup it produces. Running it here keeps the review phase focused on the diff that belongs, not churn that would be reverted anyway.

## Phase 3 — Quality Review

Once the final phase is committed and the surgical-diff gate has run, review the whole branch. The agents review the full branch diff, so this runs once after the last phase, not per phase.

Dispatch them per [review agent dispatch](references/review-dispatch.md), with `<RAW_DIR>` = `<PWD>/docs/reviews/raw` and these 5 agents:

| Agent | Report name |
| ----- | ----------- |
| **@vgv-review-agent** | `vgv-review` |
| **@architecture-review-agent** | `architecture-review` |
| **@test-quality-review-agent** | `test-quality-review` |
| **@code-simplicity-review-agent** | `code-simplicity-review` |
| **@pr-readiness-review-agent** | `pr-readiness-review` |

### After all reviews complete

Follow the [review consolidation procedure](references/review-consolidation.md): deduplicate the agents' structured findings, order them deterministically, assign stable `FINDING-NN` ids, and write **one** consolidated file to `<PWD>/docs/reviews/review.md` using the [report template](references/review-report-template.md). Print the aligned chat summary (same ids, order, and titles as the file). Then act: auto-fix minor issues, fix Critical findings by id, present Important findings to the user, and note any still-deferred findings in the PR description.

## Phase 4 — Ship

### Drive to green

Resolve the gate set and run the loop per [ship gate](references/ship-gate.md).

### Cleanup

Remove the review reports — their findings have already been addressed or recorded:

```bash
rm -rf docs/reviews/
```

### Commit and push

Handle the outstanding changes — the drive-to-green loop, the surgical-diff gate, and the Phase 3 review fixes — per [commit autonomy](references/commit-autonomy.md), which also gates pushing.

To push, call `/create-pr skip-checks` — it pushes and opens the PR. Validation already ran above. The PR body uses the [PR template](references/pr-template.md).

### Post-Ship

Use **AskUserQuestion** to present options:

- **Done**: end the session

## Gotchas

- If the plan references a package or dependency that does not exist yet, install or create it before writing code that imports it. Do not assume dependencies are already available.
- If tests fail mid-build, fix the failing test before moving to the next task. Do not accumulate broken tests across tasks.
- Generated files (mocks, codegen output) must be regenerated after code changes — stale generated files cause confusing test failures.
- If the plan specifies file paths that conflict with existing files, confirm with the user before overwriting. The codebase may have changed since the plan was written.
- The consolidated report (`docs/reviews/review.md`) and per-agent raw reports (`docs/reviews/raw/`) are deleted after Phase 4. If the build is interrupted, stale reports may remain — delete `docs/reviews/` manually before the next run.
