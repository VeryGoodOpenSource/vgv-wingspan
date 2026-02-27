# Wingspan

Wingspan is a collection of AI-assisted engineering tools — skills, agents, subagents, and hooks — specialized for Flutter and Dart projects, released as a Claude Code plugin.

## Philosophy

Apply VGV's best practices and standards for scalable Flutter apps to AI-assisted workflows. Each step of the development cycle should make subsequent steps clearer and closer to the user's intent. Build the right thing, build the thing right.

## Workflow

The plugin supports three phases:

1. **`/brainstorm`** — Explore requirements and approaches through collaborative dialogue. Produces a brainstorm document.
2. **`/plan`** — Transform brainstorm output into an actionable implementation plan. Includes codebase review, optional external research, and flow analysis.
3. **`/build`** — Execute implementation plans: write code and tests, run quality review, and ship a pull request.

Supporting skills:

- `/create-branch` (workspace setup)
- `/plan-technical-review` (validate plans)
- `/refine-approach` (iterative document improvement)

Quality-review agents:

- `test-quality-review-agent`
- `architecture-review-agent`

## Output Directories

- `docs/brainstorms/` — Brainstorm documents from `/brainstorm`
- `docs/plans/` — Implementation plans from `/plan`
- `docs/reviews/` — Review reports from `/build`

## Key Conventions

- **State management:** Bloc/Cubit is the VGV standard. Flag other patterns for review.
- **YAGNI:** Prefer the simplest solution that meets current requirements. Remove hypothetical features.
- **Architecture:** Data → Domain → Presentation. No cross-layer imports.
- **Testing:** Non-negotiable. Use `bloc_test`, `mocktail`, and `very_good_analysis`.

## Guidance

- Validate that new content does not conflict with [Very Good Engineering](https://engineering.verygood.ventures).
- Be concise but clear. Use active voice. Omit needless words.
- All code snippets, examples, and use cases must be within the context of Flutter and Dart applications.
