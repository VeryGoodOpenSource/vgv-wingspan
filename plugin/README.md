![VGV Wingspan, AI-assisted engineering workflows: a blue pixel texture beside the name, with the VGV logo in the corner](https://raw.githubusercontent.com/VeryGoodOpenSource/vgv-wingspan/main/assets/readme-header.png)

# VGV Wingspan

🦋 AI-assisted workflows that follow [Very Good Ventures][vgv_link] best practices and standards.

Developed with 💙 by [Very Good Ventures][vgv_link] 🦄

## Installation

### From the Marketplace

One-line install from your terminal:

```bash
claude plugin marketplace add VeryGoodOpenSource/very-good-claude-code-marketplace && claude plugin install vgv-wingspan
```

Or inside an active Claude Code session, run these as **two separate commands** (the second only after the first completes):

1. Add the marketplace:

   ```text
   /plugin marketplace add VeryGoodOpenSource/very-good-claude-code-marketplace
   ```

2. Install the plugin:

   ```text
   /plugin install vgv-wingspan
   ```

## Getting Started

Wingspan follows a four-phase workflow: **brainstorm**, **plan**, **build**, and **review**. Each phase produces artifacts that feed into the next, so you can clear context between steps without losing work. You can invoke skills explicitly with slash commands or let them activate automatically from natural language — just describe what you need and the right skill will trigger.

### 1. `/brainstorm`

Start here. Describe the problem or idea — the bigger and more open-ended, the more value brainstorm adds:

```text
/brainstorm how should we add authentication to this app?
```

Providing context up front produces much better results than invoking `/brainstorm` on its own. This opens a collaborative dialogue to explore requirements, constraints, and approaches. The output is saved to `docs/brainstorm/` so the next phase can pick it up. To track it on GitHub instead, pick **Publish as issue** at the end, then run `/plan` with the issue.

### 2. `/plan`

Once you're happy with the brainstorm, turn it into an actionable implementation plan:

```text
/plan add email/password and OAuth login using the auth approach from our brainstorm
```

This reviews your codebase, references the brainstorm, runs a mandatory quality pass on the draft, and produces a phased, step-by-step plan saved to `docs/plan/`. Large plans are split into phases so `/build` can execute one phase per context window.

Started from a GitHub issue (`/plan #123`), the plan goes back to that issue instead: a plan comment, plus one sub-issue per phase, each blocked by the one before.

### 3. `/build`

Execute the plan — write code, write tests, run quality review, and open a PR:

```text
/build docs/plan/add-authentication.md
```

A local plan with two or more phases ships as stacked PRs, one per phase, each targeting the previous phase's branch. It uses [`gh stack`](https://github.com/github/gh-stack) when installed, and plain `git` with `gh` or `glab` otherwise.

Given a planned issue (`/build #123`), it builds the first open, unblocked phase and opens a PR that closes it.

### 4. `/review`

Runs specialized agents in parallel — VGV standards, architecture, test quality, and simplicity. Findings land in one consolidated report with stable `FINDING-NN` ids, and the chat summary mirrors it so you can act on any finding by number. Catches issues before they reach PR.

As simple as this:

```text
/review
```

### Running without a human: agent mode

To run Wingspan unattended, for example under an orchestrator, add `--agent-mode` or say "use Wingspan in agent mode":

```text
/build docs/plan/add-authentication.md --agent-mode
```

Each skill runs every step as usual, but takes the recommended option instead of asking. Every decision lands in `docs/agent-decisions/decisions.md` with its question, context, options, reasons, and how much it matters. Agent mode never pushes, publishes, or deletes on its own unless you allow it in the request. At the end, review the log: accept each decision or pick another, and the agent reworks what changed, moves the decisions worth keeping to your PR or docs, and deletes the log.

## Better Together: Working With The Very Good AI Flutter Plugin

Wingspan and the [Very Good AI Flutter Plugin](https://github.com/VeryGoodOpenSource/vgv-ai-flutter-plugin) are designed as complementary layers of VGV's AI-assisted engineering stack. The Flutter Plugin embeds battle-tested best practices — architecture patterns, accessibility, testing, performance, and security — directly into Claude Code, so AI-generated code follows VGV's production-quality standards from the first line.

Wingspan operates at a higher level, orchestrating agentic workflows across the full software development lifecycle: planning, code review, brainstorming, and cross-tool coordination. Together, they create a system where Wingspan handles the what and when of engineering work while the Flutter Plugin ensures the how meets enterprise-grade standards — meaning teams don't just move faster, they move faster in the right direction.

On a Flutter project with the Flutter Plugin installed, `/review` and `/build` also run its
`flutter-reviewer` and merge its findings into the same report.

### Tips

- **Clear context between phases.** At the end of each phase, Wingspan offers a "Clear context and [next step]" option. Use it — a fresh context window produces better results.
- **You can skip phases.** Have a simple bug fix? Jump straight to `/build` with a description. Already know exactly what you want? Start at `/plan`.
- **Iterate within a phase.** Use `/refine-approach` to tighten a brainstorm or plan before moving on.

## Skills Reference

| Skill | Command | Description |
|-------|---------|-------------|
| [**Brainstorm**](skills/brainstorm/SKILL.md) | `/brainstorm <feature or idea>` | Explore requirements and approaches through collaborative dialogue |
| [**Refine Approach**](skills/refine-approach/SKILL.md) | `/refine-approach` | Review and refine brainstorms or plans before proceeding |
| [**Plan**](skills/plan/SKILL.md) | `/plan <feature, bug fix, improvement, or issue>` | Transform brainstorm output into a reviewed, phased implementation plan |
| [**Plan Technical Review**](skills/plan-technical-review/SKILL.md) | `/plan-technical-review <plan path>` | Review an externally-authored plan — plans from `/plan` are already reviewed during creation |
| [**Build**](skills/build/SKILL.md) | `/build <plan file path or issue>` | Execute a plan — write code and tests, run quality review, ship a PR |
| [**Review**](skills/review/SKILL.md) | `/review [path]` | Run quality review agents on demand — assess code quality and identify issues |
| [**Hotfix**](skills/hotfix/SKILL.md) | `/hotfix <bug description>` | Apply a minimal, targeted fix for emergency bugs — enforces review and testing without brainstorm or planning |
| [**Create**](skills/create/SKILL.md) | `/create <what to create>` | Scaffold a new project by routing to the right companion plugin |
| [**Create PR**](skills/create-pr/SKILL.md) | `/create-pr` | Validate (formatter, linter, tests, and CI checks), stage, commit, push, and open a pull request on the project's Git hosting platform — aborts on any failure |
| [**Rebase**](skills/rebase/SKILL.md) | `/rebase` | Rebase the current feature branch onto the base branch to stay up-to-date |
| [**Debrief**](skills/debrief/SKILL.md) | `/debrief <incident or context>` | Produce a structured post-incident analysis — timeline, root cause, and actionable follow-ups |

## Agents

Wingspan ships subagents that Claude Code dispatches as isolated, specialized reviewers. Unlike skills, agents are **not** invoked as slash commands — the workflow skills dispatch them automatically, or you can ask Claude to run one by name (e.g. "review my changes with the vgv-review-agent").

The review agents and the user flow analysis agent write to shared [writing rules](skills/shared/references/elements-of-style.md), based on Strunk's _Elements of Style_. The skill that dispatches an agent passes it the rules.

| Agent | Description |
| ----- | ----------- |
| [**VGV Review**](agents/codebase-review/vgv-review-agent.md) | Reviews code against Very Good Ventures engineering standards — architecture, state management conventions, testing quality, and code simplicity |
| [**Code Simplicity Review**](agents/codebase-review/code-simplicity-review-agent.md) | Final review pass to ensure code is as simple and minimal as possible — identifies YAGNI violations and simplification opportunities |
| [**Codebase Review**](agents/codebase-review/codebase-review-agent.md) | Conducts a thorough review of the codebase — structure, conventions, and consistent pattern usage |
| [**Architecture Review**](agents/quality-review/architecture-review-agent.md) | Validates project architecture post-implementation — layer separation, dependency direction, and package structure |
| [**Test Quality Review**](agents/quality-review/test-quality-review-agent.md) | Reviews test coverage and quality — verifies every testable unit has proper tests following VGV conventions |
| [**PR Readiness Review**](agents/quality-review/pr-readiness-review-agent.md) | Checks formatting, static analysis, debug artifacts, and commit hygiene before a pull request opens |
| [**Plan Splitting**](agents/analysis/plan-splitting-agent.md) | Analyzes implementation plans for scope and recommends splitting large plans into independently-mergeable PRs |
| [**User Flow Analysis**](agents/analysis/user-flow-analysis-agent.md) | Analyzes specs and feature descriptions for flow completeness, edge cases, and requirement gaps |
| [**Best Practices Research**](agents/research/best-practices-research-agent.md) | Researches best practices for the project's technology stack — VGV conventions first, then official docs and industry standards |
| [**Official Docs Research**](agents/research/official-docs-research-agent.md) | Gathers documentation for frameworks, libraries, or dependencies — official docs, version constraints, and implementation patterns |

### Running review agents headless

The five review agents also work outside the workflow skills: from a fleet, an
orchestrator, or another plugin. Dispatch one by its agent type and put the scope in the
prompt, for example "Review the changes on this branch against main".

| Agent type | Reviews |
| ---------- | ------- |
| `vgv-wingspan:codebase-review:vgv-review-agent` | VGV engineering standards |
| `vgv-wingspan:codebase-review:code-simplicity-review-agent` | YAGNI, premature abstraction, dead code |
| `vgv-wingspan:quality-review:architecture-review-agent` | Layer separation and dependency direction |
| `vgv-wingspan:quality-review:test-quality-review-agent` | Test coverage and test quality |
| `vgv-wingspan:quality-review:pr-readiness-review-agent` | Formatting, analysis, debug artifacts, commit hygiene |

Every reply carries the same findings block, normally first:

```markdown
## Architecture Review Findings
**Verdict**: fail | **Critical**: 1 | **Important**: 0 | **Suggestion**: 0

- severity: Critical
  rule: layer-violation
  title: Route the call through the repository
  location: lib/ui/home.dart:12
  quote: import 'package:api_client/api_client.dart';
  why: Presentation now depends on the data layer.
  fix: Inject the repository into the cubit and call it there.
```

- **Verdict** is `fail` when there is at least one Critical finding. Look for the
  `## … Findings` heading directly followed by the verdict line anywhere in the reply, so a
  one-line intro before the block does not matter. A reply without that pair means the
  review did not finish: treat it as a failure, not a clean review.
- **Quote** is the offending line, copied verbatim, or `none` for something the code lacks.
  A `none` quote comes with a `missing` line naming the absent file or text, such as
  `missing: file test/home_test.dart`. Check either against the code before acting on the
  finding.
- **The full review** follows the block. To get it as a file instead, name a raw report path
  in the prompt; the agent writes the review there and returns only the block.

## Hooks

Wingspan includes a `PreToolUse` hook that detects your project type and recommends companion plugins you haven't installed yet.

| Hook | Trigger | Behavior |
| ---- | ------- | -------- |
| **Recommend Plugins** (`recommend-plugins.sh`) | PreToolUse (`Read`/`Glob`/`Grep`) | Scans detection rules in `hooks/recommendations/`, recommends missing companion plugins once per session; non-blocking |

Detection rules live in `hooks/recommendations/`.

### Prerequisites

- **jq** — used to parse recommendation rules; the hook is skipped gracefully if `jq` is not installed

## Evals

Skill evals ask whether Claude routes to a skill and follows it. [`claude plugin eval`](https://code.claude.com/docs/en/plugin-evals) runs each case with this plugin loaded and again with no plugin at all, so a grader that passes in both arms is measuring the model rather than the skill. Runs authenticate the same way your normal Claude Code sessions do, so they need no API key locally.

The suite lives outside this plugin folder, in `evals/` at the repository root. Run it from there:

```bash
claude plugin eval . --scaffold
```

Run them locally before opening a PR that changes a skill. CI also runs them **after** a merge to `main`, scoped to the skills that changed, as an advisory signal rather than a gate — see [evals/README.md][evals_readme_ci_link].

See [evals/README.md][evals_readme_link] for the case format, the grader reference, prerequisites, and what these evals deliberately do not cover.

## Contributing

See [CONTRIBUTING.md][contributing_link] for how to add or improve skills, test your changes locally, and open a pull request. All contributors are expected to follow the [Code of Conduct][code_of_conduct_link].

[vgv_link]: https://verygood.ventures
[evals_readme_link]: https://github.com/VeryGoodOpenSource/vgv-wingspan/blob/main/evals/README.md
[evals_readme_ci_link]: https://github.com/VeryGoodOpenSource/vgv-wingspan/blob/main/evals/README.md#running-in-ci
[contributing_link]: https://github.com/VeryGoodOpenSource/vgv-wingspan/blob/main/CONTRIBUTING.md
[code_of_conduct_link]: https://github.com/VeryGoodOpenSource/vgv-wingspan/blob/main/CODE_OF_CONDUCT.md
