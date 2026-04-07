---
name: plan
user-invocable: true
description: Turns high-level brainstorming and ideas into well-structured, actionable implementation plans. Use when user says "plan this", "create a plan", "how should we implement", or "write an implementation plan".
effort: high
argument-hint: feature, bug fix, or improvement to plan
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Create a new implementation plan (or bug fix)

Transform feature descriptions, bug reports, or improvement ideas into well-structured markdown files that follow VGV conventions and best practices. This command provides flexible detail levels to match your needs.

## Feature Description

<feature_description>$ARGUMENTS</feature_description>

### 0. Idea Refinement

**Check for brainstorm output first — before asking the user anything:**

Look for recent brainstorm documents in `docs/brainstorm`:

```bash
ls -la docs/brainstorm/*.md 2>/dev/null | head -10
```

**Relevance criteria:** A brainstorm is relevant if:

- Created within the last 7 days
- If a feature description was provided above, the topic (from filename or YAML frontmatter) semantically matches it

**If exactly one relevant brainstorm exists and a feature description was provided:**

1. Read the brainstorm document
2. Announce: "Found brainstorm from [date]: [topic]. Using as context for planning."
3. Extract key decisions, chosen approach, and open questions
4. Use brainstorm decisions as input to the research phase

**If exactly one relevant brainstorm exists but NO feature description was provided:**

1. Read the brainstorm document
2. Use **AskUserQuestion tool**: "I found a recent brainstorm: **[topic]** from [date]. Would you like to plan this, or describe something different?"
   - **Options:**
     1. **Plan this brainstorm (Recommended)** — use it as context and derive the feature description from it
     2. **Describe something different** — ignore the brainstorm and ask what to plan instead
3. If the user selects "Plan this brainstorm": extract key decisions, chosen approach, and open questions. Derive the feature description from the brainstorm topic.
4. If the user selects "Describe something different": ask "What would you like to plan?" and proceed without the brainstorm.

**If multiple relevant brainstorms exist:** Use **AskUserQuestion tool** to ask which brainstorm to use, providing a brief summary of each candidate. Derive the feature description from the selected brainstorm if none was provided.

**If no brainstorm found (or not relevant) and no feature description was provided:** Ask the user: "What would you like to plan? Please describe the feature, bug fix, or improvement you have in mind."

**If no brainstorm found but a feature description was provided:** run /brainstorm to clarify the idea before proceeding.

Do not proceed until you have a clear feature description — either from the arguments, a brainstorm document, or the user.

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

**High-risk topics: always research.** Security, payments, external APIs, personal data, data privacy. The cost of missing something is too high. This takes precedence over speed signals.

**Strong local context: skip external research.** Codebase has good patterns, CLAUDE.md has guidance, user knows what they want. External research adds little value, so don't do it.

**Uncertainty or unfamiliar territory: research.** User is exploring, codebase has no examples, new technology. External perspective is valuable.

**Announce the decision and proceed.** Brief explanation, then continue. User can redirect if needed.

Examples:

- "Your codebase has solid patterns for this. Proceeding without external research."
- "This involves payment processing, so I'll research current best practices first."

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
- [ ] Update acceptance criteria based on flow analysis findings

### 4. Select implementation detail template

**Default to Standard.** Use a different level only when the task clearly warrants it.

#### Minimal

Use for simple bugs, small enhancements, or when the implementation is straightforward and well-understood.

It includes:

- Problem/feature description
- Acceptance criteria
- Essential context

Use the [minimal template](references/minimal.md) for this level.

#### Standard (default)

Use for most features and bug fixes that require a moderate level of detail to ensure clarity and successful implementation.

It includes:

- Everything in Minimal, plus:
  - Detailed background and motivation
  - Technical considerations
  - Success metrics
  - Dependencies and risks
  - Basic implementation suggestions

Use the [standard template](references/standard.md) for this level.

#### Extensive

Use for major/complex features, architectural changes, or when the implementation involves significant risk or uncertainty.

It includes:

- Everything in Standard, plus:
  - Detailed implementation plan with phases
  - Alternative approaches considered
  - Extensive technical specifications
  - Resource requirements and timeline
  - Future considerations and extensibility
  - Risk mitigation strategies
  - Documentation requirements

Use the [extensive template](references/extensive.md) for this level.

### 4.1. Set up workspace

Before writing the plan file, ensure the session is on a feature branch:

- Call /create-branch to check and optionally create a working branch or worktree.

### 5. Issue creation and formatting

**Content Formatting:**

- [ ] Use clear, descriptive headings with proper hierarchy (##, ###)
- [ ] Include code examples in triple backticks with language syntax highlighting
- [ ] Add screenshots/mockups if UI-related (drag & drop or use image hosting)
- [ ] Use task lists (- [ ]) for trackable items that can be checked off
- [ ] Add collapsible sections for lengthy logs or optional details using `<details>` tags
- [ ] Apply appropriate emoji for visual scanning (🐛 bug, ✨ feature, 📚 docs, ♻️ refactor)

**Cross-Referencing:**

- [ ] Link to related issues/PRs using #number format
- [ ] Reference specific commits with SHA hashes when relevant
- [ ] Link to code using GitHub's permalink feature (press 'y' for permanent link)
- [ ] Mention relevant team members with @username if needed
- [ ] Add links to external resources with descriptive text

**AI-Era Considerations:**

- [ ] Account for accelerated development with AI-assisted engineering
- [ ] Include prompts or instructions that worked well during research
- [ ] Emphasize comprehensive testing given rapid implementation
- [ ] Document any AI-generated code that needs human review

### 6. Final review

**Pre-submission Checklist:**

- [ ] Title is searchable and descriptive
- [ ] Labels accurately categorize the issue
- [ ] All template sections are complete
- [ ] Links and references are working
- [ ] Acceptance criteria are measurable
- [ ] Add names of files in pseudo code examples and todo lists
- [ ] Add an ERD mermaid diagram if applicable for new model changes

## Output Format

**Filename:** Use the date and kebab-case filename from Step 2 Title & Categorization: `docs/plan/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`

Examples:

- ✅ `docs/plan/2026-01-15-feat-user-authentication-flow-plan.md`
- ✅ `docs/plan/2026-02-03-fix-checkout-race-condition-plan.md`
- ✅ `docs/plan/2026-03-10-refactor-api-client-extraction-plan.md`
- ❌ `docs/plan/2026-01-15-feat-thing-plan.md` (not descriptive - what "thing"?)
- ❌ `docs/plan/2026-01-15-feat-new-feature-plan.md` (too vague - what feature?)
- ❌ `docs/plan/2026-01-15-feat: user auth-plan.md` (invalid characters - colon and space)
- ❌ `docs/plan/feat-user-auth-plan.md` (missing date prefix)

## Post-Generation Options

After writing the plan file, use the **AskUserQuestion tool** and present the following options:

**Options:**

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Start building**: execute this plan with `/build`
3. **Open the plan file in my code editor**: open the plan file for review
4. **Run `/plan-technical-review` on this plan**: run the technical review skill to validate the plan
5. **Review and refine**: improve the plan through self-review

Based on selection:

- **Clear context and build** → Output the following (substituting the actual plan file path) and then stop:

  ```md
  To continue with a fresh context, run:

  /clear

  Then start building with:

  /build docs/plan/<actual-plan-filename>.md
  ```

- **Start building** → Call the `/build` skill with the plan file path
- **Open plan in editor** → Run `open docs/plan/<plan_filename>.md` to open the file in the user's default editor
- **`/plan-technical-review`** → Call the `/plan-technical-review` skill with the plan file path
- **Review and refine** → Load `/refine-approach` skill.
- **Other** (automatically provided) → Accept free text for rework or specific changes

## Important

NEVER CODE at this stage. Only focus on producing a plan.
