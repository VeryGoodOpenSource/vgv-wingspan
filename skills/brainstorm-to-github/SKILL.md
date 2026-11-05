---
name: brainstorm-to-github
user-invocable: true
description: Explores requirements and approaches through collaborative dialogue, then publishes the result as a GitHub issue instead of a repository file.
when_to_use: Use when user says "brainstorm as a github issue", "brainstorm into an issue", "open an issue for this idea", or wants the brainstorm tracked on GitHub rather than committed to the repo.
argument-hint: feature or idea to explore
allowed-tools: Bash(gh *)
compatibility: Designed for Claude Code (or similar products with agent support and the GitHub CLI)
---

# Brainstorm into a GitHub issue

Run the same collaborative exploration as `/brainstorm`, then capture the design document as a GitHub issue rather than a file in `docs/brainstorm/`.

Use this when the brainstorm should be shareable, assignable, or trackable before any branch exists. When the brainstorm belongs with the code, use `/brainstorm` instead.

## Feature description

<feature description>$ARGUMENTS</feature description>

## Steps checklist

- [ ] Step 0: Preflight — confirm GitHub is reachable
- [ ] Step 1: Explore (delegated to `/brainstorm`)
- [ ] Step 2: Publish the issue
- [ ] Step 3: Handoff

## Step 0: Preflight

Run in parallel:

```bash
gh auth status
gh repo view --json nameWithOwner
```

Both must succeed. Store the repository as `REPO` (`owner/name`).

If either fails — `gh` missing, not authenticated, or the remote is not GitHub — report which one failed and use **AskUserQuestion**:

**Question:** "GitHub is not reachable from here. How would you like to proceed?"

**Options:**
1. **Brainstorm to a file instead (Recommended)** — apply the @brainstorm skill unchanged, which writes to `docs/brainstorm/`. Then stop.
2. **Stop and fix** — output the failing command so the user can install or authenticate `gh`, then stop.

Do not continue past this step without a working `gh`.

## Step 1: Explore

Apply the @brainstorm skill for the exploration phase, with these overrides:

| Step in `/brainstorm` | Override |
|-----------------------|----------|
| 0. Assess scope and workspace | Unchanged |
| 0.1. Assess clarity of requirements | Unchanged |
| 1.1. Lightweight project research | Unchanged |
| 1.2. Collaborative conversation | Unchanged |
| 1.3. Explore approaches | Unchanged |
| 1.4. Set up workspace | **Skip** — nothing is written to the working tree, so no feature branch is needed |
| 2. Capture the design document | **Replaced** by Step 2 below |
| 3. Handoff | **Replaced** by Step 3 below |

Write nothing to `docs/brainstorm/`.

## Step 2: Publish the issue

Build the document from the [brainstorm template](references/template.md), then follow the [GitHub issue reference](references/github-issue.md) to confirm and create it.

Store the resulting issue URL as `ISSUE_URL`.

## Step 3: Handoff

Use **AskUserQuestion tool** to consider next steps:

**Question**: "Brainstorm complete! What would you like to do next?"

**Options:**
1. **Clear context and plan (Recommended)**: clear context for a fresh start, then plan
2. **Continue with planning**: run the `/plan` skill with `ISSUE_URL` to create a detailed implementation plan
3. **Review and refine approach:** improve the issue using structured review
4. **Done for now**: brainstorm complete. To start planning later: `/plan <ISSUE_URL>`

**If the user selects "Clear context and plan"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/plan` with `ISSUE_URL` as the document path. Then stop.

**If the user selects "Review and refine approach"** → apply the @refine-approach skill to a local copy of the issue body, then push the result back:

```bash
gh issue edit <ISSUE_URL> --body-file <path>
```

When `refine-approach` is complete, present these options:

1. **Clear context and plan (Recommended)**: clear context for a fresh start, then plan
2. **Move to planning**: run the `/plan` skill with `ISSUE_URL`
3. **Done for now**: ideation complete. To start planning later: `/plan <ISSUE_URL>`

## Output Summary

When complete, display:

```md
Brainstorm complete!

Issue: <ISSUE_URL>

Key decisions:
- [Decision 1]
- [Decision 2]
```

## Important Guidelines

**DO NOT CODE!** Just explore and document decisions.
