# Wingspan

Wingspan is a collection of AI-assisted engineering tools — skills, agents, subagents, and hooks — released as a Claude Code plugin.

## Philosophy

Apply VGV's best practices and standards for scalable software to AI-assisted workflows. Each step of the development cycle should make subsequent steps clearer and closer to the user's intent. Build the right thing, build the thing right.

## Tech-Agnostic by Design

Wingspan handles the software development lifecycle — brainstorming, planning, building, and quality review. It does not enforce or assume any specific programming language, framework, or toolchain.

Technology-specific concerns (linting, formatting, scaffolding, framework conventions) belong in companion plugins. Wingspan's recommendation system detects project types and suggests the appropriate companion plugin automatically.

## Workflow

The plugin supports three phases:

1. **`/brainstorm`** — Explore requirements and approaches through collaborative dialogue. Produces a brainstorm document.
2. **`/plan`** — Transform brainstorm output into an actionable implementation plan. Includes codebase review, optional external research, and flow analysis.
3. **`/build`** — Execute implementation plans: write code and tests, run quality review, and ship a pull request.

Each phase persists its output to `docs/` so the next phase can discover it from a cold start.

**Fast path:** **`/hotfix`** — Streamlined workflow for emergency fixes. Skips brainstorm and planning but enforces review and testing. Use when speed matters but quality is still non-negotiable.

**Clear context handoff:** User-invocable skills (`user-invocable: true`) that have a forward transition (e.g., brainstorm → plan) must present **"Clear context and [next step]"** as the first handoff option. When selected, display the `/clear` command followed by the next skill's invocation, then stop. This gives the model a fresh context window without losing work. Skills invoked by other skills must not offer this — they return control to the caller instead.

Supporting skills:

- `/create-branch` (workspace setup)
- `/plan-technical-review` (validate plans)
- `/refine-approach` (iterative document improvement)

Quality-review agents:

- `test-quality-review-agent`
- `architecture-review-agent`

## Output Directories

- `docs/brainstorm/` — Brainstorm documents from `/brainstorm`
- `docs/plan/` — Implementation plans from `/plan`
- `docs/reviews/` — Review reports from `/build` and `/hotfix`

## Key Conventions

- **State management:** Enforce consistent usage of the project's chosen pattern. Flag deviations for review.
- **YAGNI:** Prefer the simplest solution that meets current requirements. Remove hypothetical features.
- **Architecture:** Respect the project's established layer boundaries and dependency direction. Flag violations for review.
- **Testing:** Non-negotiable. Every testable unit gets tests.

## Guidance

- Validate that new content does not conflict with [Very Good Engineering](https://engineering.verygood.ventures).
- Be concise but clear. Use active voice. Omit needless words.
- Technology-specific rules (linting, formatting, scaffolding) belong in companion plugins, not in Wingspan.
