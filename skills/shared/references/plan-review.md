# Plan Review

Runs the plan-quality agents against a written plan, applies their findings to the plan
inline, and resolves any scope-splitting recommendation. This is the single procedure shared
by `/plan` (a mandatory step for standard and extensive plans) and `/plan-technical-review`
(the entry point for externally-authored plans).

`<PLAN_PATH>` is the plan file under review.

## 1. Run the review agents in parallel

Pass `<PLAN_PATH>` to each. Run all three concurrently:

- **@code-simplicity-review-agent** — review the plan for simplicity and clarity; the implementation should be as straightforward as possible while still meeting every requirement.
- **@vgv-review-agent** — review the plan for adherence to Very Good Engineering practices and project conventions.
- **@plan-splitting-agent** — assess plan scope and report whether the work is too large for a single reviewable PR.

## 2. Apply findings inline

Fold the simplicity and VGV findings into the plan file directly — tighten scope, close
convention gaps, remove speculative work. Edit `<PLAN_PATH>` in place. The reader should see
the improved plan, not a list of findings to reconcile.

## 3. Resolve the scope assessment

| plan-splitting-agent result | Action |
|-----------------------------|--------|
| No split needed | Keep the plan single-phase. Record the one-line scope summary. Done. |
| Split recommended | Use **AskUserQuestion** to choose how to act (below). |

When a split is recommended, present these options:

1. **Restructure into phases in one plan (Recommended)** — keep a single plan file and add an `## Implementation Phases` section whose phases follow the proposed split boundaries.
2. **Split into separate part-N files** — generate one standalone plan file per proposed PR.
3. **Keep as one plan, no phases** — proceed unchanged; the developer accepts a larger PR.

### Restructure into phases

Add an `## Implementation Phases` section to `<PLAN_PATH>`. Map each proposed split boundary
to one phase, ordered so every phase leaves the codebase compiling with its tests passing.
For each phase, write one `### Phase N: <name>` with these fields, matching the block the plan
template defines:

- **Status:** `Not started`
- **Scope:** 1-2 sentences
- **Files touched:** the paths this phase creates or modifies
- **Acceptance criteria:** observable proof the phase is complete
- **Validation:** a command (exit 0 = pass) or `manual <numbered steps>`

Size each phase to fit comfortably in one AI context window. Do not create additional files.

### Split into separate part-N files

The **skill**, not the agent, writes the files:

- Naming: `docs/plan/YYYY-MM-DD-<type>-<original-slug>-part-N-plan.md`
- Each part is a standalone plan at the same detail level as the original, with every section `/build` expects: title, type, success criteria, tasks, and file references.
- Each part includes a `## Dependencies` section naming the prior part(s) that must merge first.
- Add a note to the top of the original plan: `> **Note:** This plan was split into parts. See the -part-N files in this directory.`

## Caller responsibilities

- **`/plan`** invokes this after writing the draft and before presenting post-generation options. Skip it entirely for the `minimal` template. Do not present handoff options here — return to the plan flow.
- **`/plan-technical-review`** invokes this on a user-supplied plan, then presents its own handoff options.
