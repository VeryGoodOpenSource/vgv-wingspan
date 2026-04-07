# Wingspan

AI-assisted workflows that follow Very Good Ventures best practices and standards.

![wingspan logo by very good ventures in blue](./assets/wingspan-logo.jpeg)

## Installation

### From the Marketplace

Inside Claude Code:

```bash
/plugin marketplace add VeryGoodOpenSource/wingspan
/plugin install wingspan@wingspan-marketplace
```

## Getting Started

Wingspan follows a three-phase workflow: **brainstorm**, **plan**, **build**. Each phase produces artifacts that feed into the next, so you can clear context between steps without losing work. You can invoke skills explicitly with slash commands or let them activate automatically from natural language — just describe what you need and the right skill will trigger.

### 1. Brainstorm

Start here. Describe the problem or idea — the bigger and more open-ended, the more value brainstorm adds:

```text
/brainstorm how should we add authentication to this app?
```

Providing context up front produces much better results than invoking `/brainstorm` on its own. This opens a collaborative dialogue to explore requirements, constraints, and approaches. The output is saved to `docs/brainstorm/` so the next phase can pick it up.

### 2. Plan

Once you're happy with the brainstorm, turn it into an actionable implementation plan:

```text
/plan add email/password and OAuth login using the auth approach from our brainstorm
```

This reviews your codebase, references the brainstorm, and produces a step-by-step plan saved to `docs/plan/`.

### 3. Build

Execute the plan — write code, write tests, run quality review, and open a PR:

```text
/build docs/plan/add-authentication.md
```

### Tips

- **Clear context between phases.** At the end of each phase, Wingspan offers a "Clear context and [next step]" option. Use it — a fresh context window produces better results.
- **You can skip phases.** Have a simple bug fix? Jump straight to `/build` with a description. Already know exactly what you want? Start at `/plan`.
- **Iterate within a phase.** Use `/refine-approach` to tighten a brainstorm or plan before moving on.

## Skills Reference

| Skill | Command | Description |
|-------|---------|-------------|
| **Brainstorm** | `/brainstorm <feature or idea>` | Explore requirements and approaches through collaborative dialogue |
| **Refine Approach** | `/refine-approach` | Review and refine brainstorms or plans before proceeding |
| **Plan** | `/plan <feature, bug fix, or improvement>` | Transform brainstorm output into a structured implementation plan |
| **Plan Technical Review** | `/plan-technical-review` | Validate that a plan meets requirements and follows best practices |
| **Build** | `/build <plan file path>` | Execute a plan — write code and tests, run quality review, ship a PR |
| **Review** | `/review [path]` | Run quality review agents on demand — assess code quality and identify issues |
| **Hotfix** | `/hotfix <bug description>` | Apply a minimal, targeted fix for emergency bugs — enforces review and testing without brainstorm or planning |
| **Create Branch** | `/create-branch` | Set up a workspace (branch or worktree) before writing artifacts |
| **Create** | `/create <what to create>` | Scaffold a new project by routing to the right companion plugin |
| **Create Commit** | `/create-commit` | Stage and commit changes using conventional commit messages |
| **Create PR** | `/create-pr` | Validate (formatter, linter, tests, and CI checks), stage, commit, push, and open a pull request on the project's Git hosting platform — aborts on any failure |
| **Rebase** | `/rebase` | Rebase the current feature branch onto the base branch to stay up-to-date |
| **Debrief** | `/debrief <incident or context>` | Produce a structured post-incident analysis — timeline, root cause, and actionable follow-ups |
