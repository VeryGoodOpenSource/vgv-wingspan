# VGV Wingspan

Wingspan is a collection of AI-assisted engineering tools — skills, agents, and hooks — released as a Claude Code plugin.

## Philosophy

Apply VGV's best practices and standards for scalable software to AI-assisted workflows. Each step of the development cycle should make subsequent steps clearer and closer to the user's intent. Build the right thing, build the thing right.

## Tech-Agnostic by Design

Wingspan handles the software development lifecycle — brainstorming, planning, building, and quality review. It does not enforce or assume any specific programming language, framework, or toolchain.

Technology-specific concerns (linting, formatting, scaffolding, framework conventions) belong in companion plugins. Wingspan's recommendation system detects project types and suggests the appropriate companion plugin automatically.

## Workflow

The plugin supports three sequential phases:

1. **`/brainstorm`** — Explore requirements and approaches through collaborative dialogue. Produces a brainstorm document.
2. **`/plan`** — Transform brainstorm output into an actionable implementation plan. Includes codebase review, optional external research, and flow analysis.
3. **`/build`** — Execute implementation plans: write code and tests, run quality review, and ship a pull request.

Standalone Skills:

- **`/review`** — Run quality review agents on demand, independent of the build workflow.

- **`/debrief`** — Produce a structured, blameless debrief document after an incident, failed release, or significant bug.

Each phase persists its output to `docs/` so the next phase can discover it from a cold start.

**Fast path:** **`/hotfix`** — Streamlined workflow for emergency fixes. Skips brainstorm and planning but enforces review and testing. Use when speed matters but quality is still non-negotiable.

**Clear context handoff:** User-invocable skills (`user-invocable: true`) that have a forward transition (e.g., brainstorm → plan) must present **"Clear context and [next step]"** as the first handoff option. When selected, display the `/clear` command followed by the next skill's invocation, then stop. This gives the model a fresh context window without losing work. Skills invoked by other skills must not offer this — they return control to the caller instead.

Supporting skills:

- `/create` (project creation — routes to companion plugins)
- `/create-pr` (generate a PR title and description from branch commits and optionally open it on GitHub or GitLab)
- `/plan-technical-review` (validate plans)
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

## Hooks

Wingspan uses Claude Code hooks to automate behavior at tool-call boundaries. Hooks are defined in `hooks/hooks.json`.

### Companion Plugin Recommendations

A `PreToolUse` hook runs on every `Read`, `Glob`, or `Grep` call. It detects the project type and recommends companion plugins the user hasn't installed yet.

**How it works:**

1. `hooks/recommend-plugins.sh` fires on the first matched tool call and scans every JSON file in `hooks/recommendations/`. Each file declares a detection rule and the plugin to recommend.
2. Every file whose detection rule matches — and whose plugin isn't already installed — is collected. All matching recommendations are emitted together in a single `additionalContext` message.
3. A marker file (`/tmp/wingspan-recommend-plugins-<hash>`) is written only when at least one recommendation is emitted, suppressing repeats for the rest of the session. If no plugins are missing, no marker is written and the script re-evaluates on the next tool call — so a newly added recommendation file can still fire later in the same session.

**Recommendation file format** (`hooks/recommendations/<plugin-name>.json`):

```json
{
  "plugin": "plugin-name",
  "detect": { "file": "Gemfile", "pattern": "^\\s*gem\\s+['\"]rails['\"]" },
  "marketplace": "OrgName/repo-name",
  "description": "What the plugin provides."
}
```

| Field             | Purpose                                                        |
|-------------------|----------------------------------------------------------------|
| `plugin`          | Plugin name as registered in the marketplace                   |
| `detect.file`     | Exact file path whose presence signals the project type        |
| `detect.files`    | Shell glob — greps inside every matching file for `pattern`    |
| `detect.pattern`  | Regex grep pattern to confirm the match                        |
| `marketplace`     | GitHub `owner/repo` for the marketplace registry               |
| `description`     | One-line summary shown in the recommendation                   |

**Adding a new recommendation:** Drop a JSON file in `hooks/recommendations/` following the format above. No code changes required. All matching files are evaluated.

## Key Conventions

- **State management:** Enforce consistent usage of the project's chosen pattern. Flag deviations for review.
- **YAGNI:** Prefer the simplest solution that meets current requirements. Remove hypothetical features.
- **Architecture:** Respect the project's established layer boundaries and dependency direction. Flag violations for review.
- **Testing:** Non-negotiable. Every testable unit gets tests.

## Guidance

- Validate that new content does not conflict with [Very Good Engineering](https://engineering.verygood.ventures).
- Be concise but clear. Use active voice. Omit needless words.
- Technology-specific rules (linting, formatting, scaffolding) belong in companion plugins, not in Wingspan.
