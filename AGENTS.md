# VGV Wingspan

Wingspan is a collection of AI-assisted engineering tools — skills, agents, and hooks — for the software development lifecycle.

## Philosophy

Apply VGV's best practices and standards for scalable software to AI-assisted workflows. Each step of the development cycle should make subsequent steps clearer and closer to the user's intent. Build the right thing, build the thing right.

## Tech-Agnostic by Design

Wingspan handles the software development lifecycle — brainstorming, planning, building, and quality review. It does not enforce or assume any specific programming language, framework, or toolchain.

Technology-specific concerns (linting, formatting, scaffolding, framework conventions) belong in companion plugins. In Claude Code, Wingspan's recommendation hook detects project types and suggests the appropriate companion plugin automatically.

## Workflow

> The `/name` forms below are the canonical skill names. Invocation syntax varies by harness — Claude Code uses `/name`; other harnesses may differ.

The plugin supports three sequential phases:

1. **`/brainstorm`** — Explore requirements and approaches through collaborative dialogue. Produces a brainstorm document.
2. **`/plan`** — Transform brainstorm output into an actionable implementation plan. Includes codebase review, optional external research, flow analysis, and a mandatory quality review of the draft. Splits large plans into phases so `/build` executes one phase per context window.
3. **`/build`** — Execute implementation plans: implement one phase per context window (implement → validate → commit → checkpoint → clear), run quality review, and ship a pull request. Committing and pushing follow the user's chosen autonomy — per-phase auto-commits or full manual control — decided up front or from a saved preference.

Standalone Skills:

- **`/review`** — Run quality review agents on demand, independent of the build workflow.

- **`/debrief`** — Produce a structured, blameless debrief document after an incident, failed release, or significant bug.

Each phase persists its output to `docs/` so the next phase can discover it from a cold start.

**Fast path:** **`/hotfix`** — Streamlined workflow for emergency fixes. Skips brainstorm and planning but enforces review and testing. Use when speed matters but quality is still non-negotiable.

**Clear context handoff:** User-invocable skills (`user-invocable: true`) that have a forward transition (e.g., brainstorm → plan) must present **"Clear context and [next step]"** as the first handoff option. When selected, clear the context, then present the next skill's invocation, then stop. This gives the model a fresh context window without losing work. Skills invoked by other skills must not offer this — they return control to the caller instead.

Supporting skills:

- `/create` (project creation — routes to companion plugins)
- `/create-pr` (generate a PR title and description from branch commits and optionally open it on GitHub or GitLab)
- `/plan-technical-review` (review externally-authored plans; `/plan` reviews the plans it creates inline)
- `/refine-approach` (iterative document improvement)
- `/rebase` (sync feature branch with base branch)

Quality-review agents:

- `vgv-review-agent`
- `architecture-review-agent`
- `test-quality-review-agent`
- `code-simplicity-review-agent`
- `pr-readiness-review-agent`

Each agent writes a detailed report to a `raw/` subdirectory and returns a structured
findings list. The calling skill deduplicates and orders those findings, assigns stable
`FINDING-NN` ids (plus a stable `<category>/<rule>` id per finding for acting on a whole
class), and renders one consolidated report plus a matching chat summary (see
`skills/shared/references/review-consolidation.md`).

## Output Directories

- `docs/brainstorm/` — Brainstorm documents from `/brainstorm`
- `docs/plan/` — Implementation plans from `/plan`
- `docs/reviews/` — Consolidated `review.md` + per-agent `raw/` from `/build` (ephemeral, cleaned up by build)
- `docs/hotfix-review/` — Consolidated `review.md` + per-agent `raw/` from `/hotfix` (ephemeral, cleaned up by hotfix)
- `docs/code-review/` — One `<slug>/` directory per run (`review.md` + per-agent `raw/`) from `/review` (standalone, user-managed)
- `docs/debriefs/` — Debrief documents from `/debrief`

## Key Conventions

- **State management:** Enforce consistent usage of the project's chosen pattern. Flag deviations for review.
- **YAGNI:** Prefer the simplest solution that meets current requirements. Remove hypothetical features.
- **Architecture:** Respect the project's established layer boundaries and dependency direction. Flag violations for review.
- **Testing:** Non-negotiable. Every testable unit gets tests.

## Guidance

- Validate that new content does not conflict with [Very Good Engineering](https://engineering.verygood.ventures).
- Be concise but clear. Use active voice. Omit needless words.
- Technology-specific rules (linting, formatting, scaffolding) belong in companion plugins, not in Wingspan.
