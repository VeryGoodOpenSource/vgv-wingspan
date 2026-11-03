---
name: plan
user-invocable: true
description: Turns high-level brainstorming and ideas into well-structured, actionable implementation plans. Use when the user says "plan this", "create a plan", "how should we implement", or "write an implementation plan".
effort: high
argument-hint: feature, bug fix, or improvement to plan
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Create a new implementation plan (or bug fix)

Transform feature descriptions, bug reports, or improvement ideas into well-structured markdown files that follow VGV conventions and best practices, at a detail level matched to the work.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

**Never write code at this stage.** The output is a plan.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

## Feature Description

<feature_description>$ARGUMENTS</feature_description>

### 0. Idea Refinement

Check for brainstorm output first — before asking the user anything.

```bash
ls docs/brainstorm/
```

A brainstorm is relevant if created within the last 7 days and its topic semantically matches the feature description (if provided).

| Brainstorms found | Feature description provided? | Action |
|-------------------|------------------------------|--------|
| One relevant | Yes | Read it, announce "Found brainstorm from [date]: [topic]", extract key decisions, proceed |
| One relevant | No | **AskUserQuestion**: "Plan this brainstorm?" — (Recommended) use it, or describe something different |
| Multiple relevant | Either | **AskUserQuestion**: list candidates, ask which to use |
| None / not relevant | No | Ask: "What would you like to plan?" |
| None / not relevant | Yes | Run /brainstorm to clarify the idea first |

Do not proceed until you have a clear feature description — from arguments, a brainstorm, or the user.

**Skip option**: if the description is already detailed enough, ask the user if they want to skip idea refinement and proceed directly to planning.

### 1. Tasks to complete

#### 1.1 Local research (always runs, and runs in parallel)

**Do not re-run `codebase-review-agent` here.** Codebase context was already captured in the brainstorm from `/brainstorm`.

Instead, extract what's needed from the brainstorm and run targeted searches:

1. **From the brainstorm doc**: Extract the architecture patterns, conventions, and relevant file paths already identified.
2. **Targeted codebase search**: Use Glob and Grep to search only the areas this plan will touch — the specific packages, layers, or features mentioned in the feature description and brainstorm.
   - Example: If planning a new repository, search for existing repository patterns in the relevant package.
   - Example: If planning a new state management unit, search for existing implementations in the same feature area.
3. **Read referenced files**: Read any specific files called out in the brainstorm as relevant context.

#### 1.1.1 Research decision

Based on the findings from `0. Idea Refinement` and `1.1 Local research`, decide whether external research is needed:

| Signal | Decision |
|--------|----------|
| High-risk topic (security, payments, external APIs, personal data) | Always research — cost of missing something is too high |
| Strong local context (good patterns, CLAUDE.md guidance, clear user intent) | Skip external research |
| Uncertainty or unfamiliar territory (no codebase examples, new technology) | Research |

Announce the decision briefly and proceed. User can redirect if needed.

#### 1.1.2 Conditional external research

Only run this step if `1.1.1 Research decision` determines that external research is needed.

Run these agents in parallel to gather external information:

- **@official-docs-research-agent**: Fetches and synthesizes official documentation for relevant frameworks, libraries, and APIs.
- **@best-practices-research-agent**: Researches and synthesizes best practices for the project's technology stack, following VGV conventions first, then official documentation, and finally industry standards.

#### 1.1.3 Consolidate research findings

After all research steps complete, consolidate findings:

- Document relevant file paths from repo research (e.g., `src/authentication/forms/authentication_form:42`)
- **Include relevant institutional learnings** from project documentation (key insights, gotchas to avoid)
- Note external documentation URLs and best practices (if external research was done)
- List related issues or PRs discovered
- Capture CLAUDE.md conventions

**Optional validation:** Briefly summarize findings and ask if anything looks off or missing before proceeding to planning.

### 2. Title, filename, and structure

Draft the plan's title, derive its filename, and gather supporting material per
[plan authoring](references/plan-authoring.md).

### 3. User Flow Analysis

After planning the issue structure, run the **user-flow-analysis-agent** to analyze the plan for flow completeness and gap identification:

- Task @user-flow-analysis-agent(feature_description, research_findings)

**Flow Analysis Output:**

- [ ] Review flow analysis results
- [ ] Incorporate any identified gaps or edge cases into the issue
- [ ] Update success criteria based on flow analysis findings

### 4. Success Criteria Gate

Before selecting a template, derive the plan's success criteria and make each one machine-checkable. This block is the contract `/build` consumes, so it must be precise.

**For each criterion, apply one rule — can a command prove this without human judgment?**

- **Yes** → attach `verify: <command>` (exit code 0 = pass).
- **No, but a human can check it** → attach `verify: manual <numbered steps>`.
- **Neither (vacuous or unmeasurable, e.g. "make it work", "code is clean")** → reject it and rewrite it into a concrete, provable criterion.

Surface every rejected or rewritten criterion to the user with **AskUserQuestion** before writing the plan file — do not silently change the spec they approved.

These criteria populate the `success-criteria` block defined in [success-criteria.md](references/success-criteria.md); fill it in when you write the plan file in Step 6. That reference shows the block's shape and the `verify:` convention.

`/build` reads the block back, so its shape holds even when the reference cannot be read from
here. The plan carries a `## Success Criteria` section, and every criterion names what proves
it after `verify:` — a shell command whose exit 0 is the pass, or `verify: manual` followed by
numbered human steps. A criterion with nothing to run against it — "make it work", "the
feature is done" — is not a criterion; rewrite it as something a command or a numbered
procedure can settle.

`verify:` commands reflect the project's own toolchain. If the project has a companion verification skill available, its gates are the canonical `verify:` commands.

### 5. Select implementation detail template

**Default to Standard.** Use a different level only when the task clearly warrants it.

| Level | When to use | Template |
|-------|-------------|----------|
| **Minimal** | Simple bugs, small enhancements, straightforward implementation | [minimal](references/minimal.md) |
| **Standard** (default) | Most features and bug fixes needing moderate detail | [standard](references/standard.md) |
| **Extensive** | Major features, architectural changes, significant risk or uncertainty | [extensive](references/extensive.md) |

Whatever the level, a plan that carries more than one phase embeds the
[Implementation Phases block](references/implementation-phases.md) verbatim: `## Implementation Phases`,
one `### Phase N:` each, and the `**Status:**`, `**Scope:**`, `**Files touched:**`,
`**Acceptance criteria:**` and `**Validation:**` fields. `/build` parses those names to execute one
phase per context window — renaming them to anything of your own, however clear, breaks execution.

#### The success-criteria contract

`/build` reads this block back, so its shape is fixed here as well as in the reference. Every
plan carries a `## Success Criteria` section holding:

```success-criteria
GOAL: <one sentence describing the intended end state>

SUCCESS CRITERIA:
- <observable criterion> | verify: <shell command; exit 0 = pass>
- <observable criterion> | verify: manual <numbered human steps>

NON-GOALS:
- <explicitly out of scope>

VERIFICATION COMMAND: <the non-manual verify commands joined into one runnable command; exit 0 = all green>
```

Every criterion names what proves it after `verify:`. A criterion with nothing to run against
it — "make it work", "the feature is done" — is not a criterion; rewrite it as something a
command or a numbered human procedure can settle. Write the block in this shape even when the
reference file cannot be read from here.


### 5.1. Set up workspace

Run the [feature branch check](references/feature-branch.md) before writing anything to disk.

### 6. Write and review the plan file

Write the file, then check it against the formatting and pre-submission rules in
[plan authoring](references/plan-authoring.md).

## Output Format

**Filename:** `docs/plan/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`, derived in Step 2 —
e.g. `docs/plan/2026-01-15-feat-user-authentication-flow-plan.md`.

## Plan Review

After writing the plan file and before presenting options, run a mandatory quality pass on it. This replaces the separate `/plan-technical-review` step — plans created here are reviewed here.

- **Minimal template** → skip this section. The overhead is not worth it for a small plan.
- **Standard or Extensive template** → follow the [plan review procedure](references/plan-review.md) with `<PLAN_PATH>` set to the plan file. It runs the simplicity, VGV, and scope-splitting agents in parallel, applies their findings to the plan inline, and — if the plan is too large for one PR — offers to restructure the work into phases or split it into part-N files.

Return here once the review completes, then present the options below.

## Post-Generation Options

After the review completes, use the **AskUserQuestion tool** and present the following options:

**Options:**

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Start building**: execute this plan with `/build`
3. **Open the plan file in my code editor**: open the plan file for review
4. **Review and refine**: improve the plan through self-review

**If the user selects "Clear context and build"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/build` with the actual plan file path. Then stop.

**For other selections:**

- **Start building** → Call the `/build` skill with the plan file path
- **Open plan in editor** → Run `open docs/plan/<plan_filename>.md` to open the file in the user's default editor
- **Review and refine** → Load `/refine-approach` skill.
- **Other** (automatically provided) → Accept free text for rework or specific changes


## The handoff block

The handoff is the user's only instruction for picking the work up in a fresh session, so its
shape is fixed here as well as in the reference. Print exactly this and then **stop**,
substituting the next skill and the real document path:

```md
To continue with a fresh context, run:

/clear

Then start <NEXT_ACTION> with:

/<NEXT_SKILL> <DOC_PATH>
```

Print it even when the document cannot be read from here, and even when the reference file
cannot be read — a cleared context is a new session, and the skill that picks it up validates
the path. Withholding the block because a check failed strands the user mid-handoff.
