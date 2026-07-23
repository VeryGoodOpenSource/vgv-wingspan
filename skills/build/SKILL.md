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
- [ ] Phase 0: Load plan and confirm scope (or resume a phased build)
- [ ] Phase 1: Read context for the current implementation phase
- [ ] Phase 2: Loop implementation phases (implement → validate → commit or hand off → checkpoint → clear)
- [ ] Phase 3: Run review agents (5 in parallel), consolidate into one report
- [ ] Phase 4: Drive to green, cleanup, and ship
```

## Plan Input

<plan_path>$ARGUMENTS</plan_path>

Treat the plan path above as empty if it is blank or still shows the literal text `$ARGUMENTS` (the host did not substitute it).

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

**Commit autonomy:** decide once how this build commits, and carry the choice through the whole run. Honor a saved preference if one exists (Claude memory or the user's personal settings); otherwise use **AskUserQuestion**:

- **Auto-commit each phase (Recommended)**: commit automatically as each phase completes. Pushing and opening the PR still pause for approval (Phase 4).
- **I'll commit myself**: build one phase, then stop so the user reviews and commits. Nothing is committed or pushed without the user.

Offer to save the choice to Claude memory (a personal preference) so future builds skip this question. Save it as the user's own preference — never write it to the project's CLAUDE.md, since committing this is a per-developer choice, not a repo convention.

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

Then handle the phase's changes per the **commit autonomy** chosen in Phase 0:

- **Auto-commit each phase** → stage and commit the phase now, using the format below.
- **I'll commit myself** → do not commit. Summarize the phase's changed files and leave them staged for the user to review.

Auto-commit message format:

```text
<type>: <phase name>

<one-line summary of what the phase delivered>
```

`<type>` matches the plan's type (`feat`, `fix`, `refactor`, …). One commit per phase keeps the branch history clean and each phase independently reviewable. A single-phase plan produces one implementation commit here.

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

Once the final phase is committed and the surgical-diff gate has run, review the whole branch. Run 5 review agents **in parallel** — they review the full branch diff, so this runs once after the last phase, not per phase.

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

**No subagent mechanism?** Don't skip the reviews — run them as sequential passes in the fixed Step 1 table order (VGV → architecture → tests → simplicity → PR readiness), writing each pass's raw findings to its own `raw/<name>.md` before starting the next, then consolidate the same way. See the [single-agent fallback](references/review-consolidation.md#single-agent-fallback-sequential-passes).

### After all reviews complete

Follow the [review consolidation procedure](references/review-consolidation.md): deduplicate the agents' structured findings, order them deterministically, assign stable `FINDING-NN` ids, and write **one** consolidated file to `<PWD>/docs/reviews/review.md` using the [report template](references/review-report-template.md). Print the aligned chat summary (same ids, order, and titles as the file). Then act: auto-fix minor issues, fix Critical findings by id, present Important findings to the user, and note any still-deferred findings in the PR description.

## Phase 4 — Ship

### Drive to green

The plan's `success-criteria` block is the ship gate. Parse it, then handle these cases before looping:

| Case | Action |
| ---- | ------ |
| Block present with a `VERIFICATION COMMAND` | Gate set = the non-manual `verify:` commands; authoritative command = the `VERIFICATION COMMAND`. |
| Block present, `VERIFICATION COMMAND` missing but non-manual `verify:` lines exist | Synthesize the authoritative command by joining those `verify:` commands with `&&`. |
| Only `verify: manual` criteria, no runnable command | Skip the loop; go straight to the manual-criteria checklist. Never treat an empty runnable set as green. |
| No `success-criteria` block (plan predates it) | Fall back to the detected project suite (formatter, linter, test runner) as the gate, and warn the user the plan has no machine-checkable criteria. Never treat an absent block as green. |

Then follow the [drive to green procedure](references/drive-to-green.md) with that gate set and authoritative command. It loops until every gate is green by real output, delegates to a matching installed verification skill when one exists, runs the authoritative command as the final check, and escalates only on un-runnable or self-contradictory criteria. Do not proceed to cleanup until the authoritative gate is green and any manual criteria are confirmed.

### Cleanup

Remove the review reports — their findings have already been addressed or recorded:

```bash
rm -rf docs/reviews/
```

### Commit

Handle the outstanding changes — the drive-to-green loop, the surgical-diff gate, and the Phase 3 review fixes — per the **commit autonomy** chosen in Phase 0:

- **Auto-commit mode** → the phases are already committed from Phase 2; stage and commit whatever is still outstanding, using the format below. If nothing is outstanding, skip this commit.
- **I'll-commit-myself mode** → do not commit. Summarize everything still uncommitted and leave it staged for the user.

```text
<type>: address review findings

<one-line summary of the fixes>
```

`<type>` matches the plan's type (`feat`, `fix`, `refactor`, etc.). Either way, review findings
are fixed in place during Phase 3 and the report is deleted at Cleanup, so any commit does not
cite `FINDING-NN` ids (there would be no report left to map them to).

### Ship

Whatever commits this build produced are local. Pushing and opening a PR is outward-facing, so gate it on the user's preference — separately from the commit-autonomy choice:

<!-- portability:ask-fallback -->
> **No structured-question tool?** The push/PR decision below uses `AskUserQuestion`. On a host without it, ask in plain numbered text and default to *review locally first* — never push or open a PR without an explicit user go-ahead. `allowed-tools` here is narrow (`Bash(rm -rf docs/reviews/)`); use whatever tools the build needs — it is a Claude Code hint, not a cap. See [interaction fallbacks](references/interaction-fallbacks.md).

- **User has a saved preference to push automatically** (Claude memory or personal settings) → push and open the PR without asking.
- **No such preference** → use **AskUserQuestion** before anything leaves the machine:
  1. **Review locally first (Recommended)**: stop here. The commits stay local; the user pushes and opens the PR when ready. Do not call `/create-pr`.
  2. **Push and open the PR now**: proceed this once.
  3. **Always push automatically**: proceed, and save the preference to Claude memory (the user's own preference, never the project's CLAUDE.md) so future builds skip this prompt.

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

## Important

- This skill writes code. It is the execution phase, not the planning phase.
- Follow the plan. The plan was reviewed and approved. Don't redesign during implementation.
- Ship quality, not quantity. Every line represents VGV's engineering reputation.
- When in doubt, read the plan again before asking the user.
