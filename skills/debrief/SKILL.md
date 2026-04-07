---
name: debrief
user-invocable: true
description: Produces a structured post-incident analysis — timeline, root cause, and actionable follow-ups — while context is fresh. Use when user says "debrief", "post-mortem", "incident review", or "root cause analysis".
argument-hint: incident description, PR/commit refs, or error context
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Post-incident debrief

Produce a structured, blameless debrief document after an incident, failed release, or significant bug. Capture what happened, why, and what to change — while the context is still fresh.

**Use this when** a production incident, failed release, flaky deploy, or significant bug warrants more than just a fix — when the team needs to understand *why* it happened and prevent recurrence.

## Incident Context

<incident_context>$ARGUMENTS</incident_context>

**If the incident context above is empty, ask the user**: "What incident would you like to debrief? Describe what happened, link to relevant PRs/commits, or paste error logs."

DO NOT proceed until you have a description from the user.

## Execution Flow

### 1. Gather initial information

Use the **AskUserQuestion tool** to fill in gaps one question at a time. Adapt based on what the user already provided — skip questions whose answers are already clear from the incident context.

**Key questions to resolve:**

| Topic | Example Questions |
|-------|-------------------|
| What happened | What was the user-visible impact? What broke? |
| When | When did it start? When was it detected? When was it resolved? |
| Where | What platform, environment, or service? (e.g., prod vs staging, iOS vs Android, specific API) |
| Severity | How many users/systems were affected? Was data lost? |
| Detection | How was it discovered? Alert, user report, or manual observation? |
| Resolution | What was the fix? Is it deployed? Is it a temporary workaround? |
| References | Relevant PRs, commits, CI runs, error logs, or monitoring links? |

**Exit condition:** Continue until you have enough context to reconstruct a timeline, OR the user says "that's all I have" or "proceed."

The skill must work with partial information. Not every debrief has full CI logs or a complete timeline. Note gaps explicitly in the document rather than blocking on them.

### 2. Gather evidence from the codebase

Based on the incident context, automatically collect evidence. Run these in parallel where possible:

#### 2.1 Git history

Search for commits and changes related to the incident:

- Identify affected files from the incident description
- Run `git log` on those files to find recent changes (last 2 weeks or a user-specified time range)
- Run `git log --all --oneline` with relevant date ranges to find related commits
- If PR numbers are provided, use `gh pr view <number>` to gather PR details and review comments

#### 2.2 CI/CD evidence

If the user provided CI run references or if recent failures are findable:

- Use `gh run list` to find recent failed CI runs (if applicable)
- Use `gh run view <id>` for specific runs the user referenced
- Skip this step if no CI context is available — do not block on missing CI data

#### 2.3 Affected file analysis

For each file identified as part of the incident:

- Check test coverage: are there test files for the affected code? Use Glob to search for corresponding test files.
- Check recent change frequency: `git log --oneline <file>` to see how often it changed recently
- Note any files that lack tests or have high churn

### 3. Analyze root cause

Synthesize the gathered evidence to identify:

1. **Root cause**: The specific change, gap, or condition that caused the incident. Trace to specific commits or code paths where possible.
2. **Contributing factors**: Conditions that made the incident more likely, harder to detect, or slower to resolve. Examples:
   - Missing test coverage for the affected path
   - No monitoring or alerting on the failure mode
   - Unclear ownership of the affected component
   - Missing validation or error handling
   - Insufficient review of the change that introduced the issue

**Blameless framing:** Focus on systems and processes, not individuals. Use "the change" not "developer X's change." Ask "what made this possible?" not "who caused this?"

### 4. Draft action items

Generate concrete, assignable follow-ups. Each action item must be:

- **Specific**: "Add integration test for payment webhook retry logic" not "improve testing"
- **Linked to code where possible**: Reference specific files, functions, or paths that need changes
- **Categorized by type**:
  - **Prevent**: Changes that would have prevented this incident (e.g., add validation, add test)
  - **Detect**: Changes that would have caught it sooner (e.g., add monitoring, add CI check)
  - **Respond**: Changes that would have made recovery faster (e.g., add runbook, add feature flag)

Action items are recorded in the document only. They become separate tickets — the debrief skill does not make code changes.

### 5. Set up workspace

Before writing the debrief file, ensure the session is on a feature branch:

- Call @create-branch to check and optionally create a working branch or worktree.

### 6. Write the debrief document

Write the document to `docs/debriefs/YYYY-MM-DD-<kebab-case-topic>-debrief.md`.

Ensure `docs/debriefs/` directory exists before writing.

**Document structure:**

Use the [debrief template](references/template.md) as the document structure. Adapt it to fit the available information — omit sections with no relevant data rather than filling them with "N/A." Add sections if the incident warrants it (e.g., a "Customer Communication" section for user-facing incidents).

### 7. Handoff

Use the **AskUserQuestion tool** to present next steps:

**Question**: "Debrief complete! What would you like to do next?"

**Options:**

1. **Review and refine**: improve the document using structured review
2. **Create action item tickets**: draft GitHub issues from the action items (not implemented yet — note this)
3. **Done**: debrief complete

**If the user selects "Review and refine"** → apply the @refine-approach skill to the document. When refinement is complete, present these options again (without the refine option).

## Output Summary

When complete, display:

```md
Debrief complete!

Document: docs/debriefs/YYYY-MM-DD-<kebab-case-topic>-debrief.md

Severity: <severity>
Root cause: [one-line summary]
Action items: <N> prevent, <N> detect, <N> respond
```

## Key Principles

- **Blameless** — Focus on systems and processes, never individuals
- **Evidence-based** — Link findings to commits, PRs, code paths, and logs
- **Actionable** — Every action item is specific and assignable
- **Honest about gaps** — Mark unknowns explicitly rather than guessing
- **Tech-agnostic** — No language or framework assumptions in the skill itself

## Important

**DO NOT make code changes.** This skill produces a document only. Action items become separate tickets.
