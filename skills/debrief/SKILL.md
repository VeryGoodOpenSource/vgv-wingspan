---
name: debrief
user-invocable: true
description: Produces a structured post-incident analysis — timeline, root cause, and actionable follow-ups — while context is fresh.
when_to_use: Use when user says "debrief", "post-mortem", "incident review", or "root cause analysis".
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

Run these in parallel:

- **Git history**: `git log` on affected files (last 2 weeks or user-specified range), `git log --all --oneline` for related commits, `gh pr view` for referenced PRs
- **CI/CD evidence**: `gh run list` for recent failures, `gh run view <id>` for referenced runs. Skip if no CI context — do not block on missing data.
- **Affected file analysis**: Check test coverage (Glob for test files), recent change frequency (`git log --oneline <file>`). Note files lacking tests or with high churn.

### 3. Analyze root cause

Synthesize the evidence to identify the **root cause** (specific change, gap, or condition — trace to commits or code paths) and **contributing factors** (missing tests, no monitoring, unclear ownership, insufficient review).

**Blameless framing:** Focus on systems and processes, not individuals. Ask "what made this possible?" not "who caused this?"

### 4. Draft action items

Generate concrete, assignable follow-ups. Each must be specific (not "improve testing"), linked to code where possible, and categorized:

| Type | Purpose | Examples |
|------|---------|----------|
| **Prevent** | Would have stopped this incident | Add validation, add test |
| **Detect** | Would have caught it sooner | Add monitoring, add CI check |
| **Respond** | Would have made recovery faster | Add runbook, add feature flag |

Action items are recorded in the document only — they become separate tickets.

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
2. **Generate issue previews**: format action items as ready-to-copy GitHub issue drafts
3. **Done**: debrief complete

**If the user selects "Review and refine"** → apply the @refine-approach skill to the document. When refinement is complete, present these options again (without the refine option).

**If the user selects "Generate issue previews"** → read the action items from the written debrief document, then:

1. **Check for issue templates**: look for `.github/ISSUE_TEMPLATE/` in the project root. Read every `.yaml` or `.yml` file found there (skip `config.yml`).

2. **If templates exist**: render one preview block per action item using the most appropriate template. Map each item to a template based on its content (e.g., a missing test or validation gap → bug report; a new monitoring check → feature request; a dependency update or runbook → chore). Populate every required field defined in the template. Include a `Template:` line naming the chosen template file.

3. **If no templates exist**: fall back to the generic format:

```text
---
Title: <specific, actionable title>
Label: prevent | detect | respond
Body:
  ## Context
  Debrief: docs/debriefs/YYYY-MM-DD-<topic>-debrief.md
  Root cause: <one-line summary from debrief>

  ## What happened
  <relevant excerpt from the debrief timeline or root cause section>

  ## What to do
  <the action item, specific and linked to code/files where possible>
---
```

Render all previews in a single fenced block so the user can copy them. Do not call `gh`, `glab`, or any external CLI — output is display only.

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
