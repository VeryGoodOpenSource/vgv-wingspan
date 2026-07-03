---
name: plan
user-invocable: true
description: Turns high-level brainstorming and ideas into well-structured, actionable implementation plans.
when_to_use: Use when user says "plan this", "create a plan", "how should we implement", or "write an implementation plan".
effort: high
argument-hint: feature, bug fix, or improvement to plan
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Create a new implementation plan (or bug fix)

Transform feature descriptions, bug reports, or improvement ideas into well-structured markdown files that follow VGV conventions and best practices. This command provides flexible detail levels to match your needs.

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

##### 1.1.1 Research decision

Based on the findings from `0. Idea Refinement` and `1.1 Local research`, decide whether external research is needed:

| Signal | Decision |
|--------|----------|
| High-risk topic (security, payments, external APIs, personal data) | Always research — cost of missing something is too high |
| Strong local context (good patterns, CLAUDE.md guidance, clear user intent) | Skip external research |
| Uncertainty or unfamiliar territory (no codebase examples, new technology) | Research |

Announce the decision briefly and proceed. User can redirect if needed.

###### 1.1.1.1 Conditional external research

Only run this step if `1.1.1 Research decision` determines that external research is needed.

Run these agents in parallel to gather external information:

- **@official-docs-research-agent**: Fetches and synthesizes official documentation for relevant frameworks, libraries, and APIs.
- **@best-practices-research-agent**: Researches and synthesizes best practices for the project's technology stack, following VGV conventions first, then official documentation, and finally industry standards.

##### 1.1.2. Consolidate research findings

After all research steps complete, consolidate findings:

- Document relevant file paths from repo research (e.g., `src/authentication/forms/authentication_form:42`)
- **Include relevant institutional learnings** from project documentation (key insights, gotchas to avoid)
- Note external documentation URLs and best practices (if external research was done)
- List related issues or PRs discovered
- Capture CLAUDE.md conventions

**Optional validation:** Briefly summarize findings and ask if anything looks off or missing before proceeding to planning.

### 2. Issue planning and structure

Think like a product manager — what would make this issue clear and actionable?

**Title & Categorization:**

- [ ] Draft clear, searchable issue title using the conventional commits format (e.g., `feat: add user authentication`, `fix: cart total calculation`)
- [ ] Determine issue type: enhancement, bug, refactor
- [ ] Convert title to filename: add today's date prefix, strip prefix colon, kebab-case, add `-plan` suffix
  - Example: `feat: add user authentication` → `2026-01-21-feat-add-user-authentication-plan.md`
  - Keep it descriptive (3-5 words after prefix) so plans are findable by context

**Stakeholder Analysis:**

- [ ] Identify who will be affected by this issue (end users, developers, operations)
- [ ] Consider implementation complexity and required expertise

**Content Planning:**

- [ ] Choose appropriate detail level based on issue complexity and audience
- [ ] List all necessary sections for the chosen template
- [ ] Gather supporting materials (error logs, screenshots, design mockups)
- [ ] Prepare code examples or reproduction steps if applicable, name the mock filenames in the lists

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

`verify:` commands reflect the project's own toolchain. If the project has a companion verification skill available, its gates are the canonical `verify:` commands.

### 5. Select implementation detail template

**Default to Standard.** Use a different level only when the task clearly warrants it.

| Level | When to use | Template |
|-------|-------------|----------|
| **Minimal** | Simple bugs, small enhancements, straightforward implementation | [minimal](references/minimal.md) |
| **Standard** (default) | Most features and bug fixes needing moderate detail | [standard](references/standard.md) |
| **Extensive** | Major features, architectural changes, significant risk or uncertainty | [extensive](references/extensive.md) |

### 5.1. Set up workspace

Before writing the plan file, ensure the session is not on the base branch:

- Run `git rev-parse --abbrev-ref HEAD`. If the current branch is a base branch (`main`, `master`, or `develop`), use **AskUserQuestion** to offer creating a feature branch — `git checkout -b <type>/<kebab-topic>`, name under 60 characters — before writing. If already on a feature branch, continue without prompting.

### 6. Issue creation and formatting

**Formatting checklist:**

- [ ] Clear heading hierarchy (##, ###) and fenced code blocks with language identifiers
- [ ] Task lists (`- [ ]`) for trackable items; collapsible `<details>` for lengthy content
- [ ] Link related issues/PRs (`#number`), commits (SHA), and code (GitHub permalinks)
- [ ] Include prompts or instructions that worked well during research
- [ ] Emphasize comprehensive testing given rapid AI-assisted implementation

### 7. Final review

**Pre-submission Checklist:**

- [ ] Title is searchable and descriptive
- [ ] Labels accurately categorize the issue
- [ ] All template sections are complete
- [ ] Links and references are working
- [ ] Success criteria each carry a `verify:` command (or `verify: manual <steps>`)
- [ ] Add names of files in pseudo code examples and todo lists
- [ ] Add an ERD mermaid diagram if applicable for new model changes

## Output Format

**Filename:** Use the date and kebab-case filename from Step 2 Title & Categorization: `docs/plan/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Examples:

- ✅ `docs/plan/2026-01-15-feat-user-authentication-flow-plan.md`
- ❌ `docs/plan/2026-01-15-feat-thing-plan.md` (not descriptive)
- ❌ `docs/plan/feat-user-auth-plan.md` (missing date prefix)

## Post-Generation Options

After writing the plan file, use the **AskUserQuestion tool** and present the following options:

**Options:**

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Start building**: execute this plan with `/build`
3. **Open the plan file in my code editor**: open the plan file for review
4. **Run `/plan-technical-review` on this plan**: run the technical review skill to validate the plan
5. **Review and refine**: improve the plan through self-review

**If the user selects "Clear context and build"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/build` with the actual plan file path. Then stop.

**For other selections:**

- **Start building** → Call the `/build` skill with the plan file path
- **Open plan in editor** → Run `open docs/plan/<plan_filename>.md` to open the file in the user's default editor
- **`/plan-technical-review`** → Call the `/plan-technical-review` skill with the plan file path
- **Review and refine** → Load `/refine-approach` skill.
- **Other** (automatically provided) → Accept free text for rework or specific changes

## Important

NEVER CODE at this stage. Only focus on producing a plan.
