---
name: plan
description: Turn high-level brainstorming and ideas into well-structured, actionable plans for implementation that follow your own project conventions and patterns.
---

# Create a new implementation plan (or bug fix)

Transform feature descriptions, bug reports, or improvement ideas into well-structured markdown files issues that follow project conventions and best practices. This command provides flexible detail levels to match your needs.

## Feature Description

<feature_description> #$ARGUMENTS </feature_description>

**If the feature description above is empty, ask the user:** "What would you like to plan? Please describe the feature, bug fix, or improvement you have in mind."

Do not proceed until you have a clear feature description from the user.

### 0. Idea Refinement

**Check for brainstorm output first:**

Before asking questions, look for recent brainstorm documents in `docs/brainstorms/` that match this feature:

```bash
ls -la wingspan/brainstorms/*.md 2>/dev/null | head -10
```

**Relevance criteria:** A brainstorm is relevant if:

- The topic (from filename or YAML frontmatter) semantically matches the feature description
- Created within the last 7 days
- If multiple candidates match, use **AskUserQuestion tool** to ask which brainstorm to use.

**If a relevant brainstorm exists:**

1. Read the brainstorm document
2. Announce: "Found brainstorm from [date]: [topic]. Using as context for planning."
3. Extract key decisions, chosen approach, and open questions
4. Use brainstorm decisions as input to the research phase

**If no brainstorm found (or not relevant):** run @ideate-skill to clarify the idea before proceeding.

**If multiple brainstorms found:** Use **AskUserQuestion tool** to ask which brainstorm to use, providing a brief summary of each candidate.

**Skip option**: if the description is already detailed enough, ask the user if they want to skip idea refinement and proceed directly to planning.

### 1. Tasks to complete

#### 1.1 Local research (always runs, and runs in parallel)

<thinking>
First, I need to understand the project's conventions, existing patterns, and any documented learnings. This is fast and local - it informs whether external research is needed.
</thinking>

Run the following **agents locally in parallel** to gather context:

- **flutter-codebase-review-agent**: Conduct a thorough review of the codebase to understand architecture, patterns, and conventions.

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

- **official-docs-research-agent**: Fetches and synthesizes official documentation for relevant frameworks, libraries, and APIs.
- **flutter-best-practices-research-agent**: Researches and synthesizes Flutter and Dart best practices, following first Very Good Engineering practices, then Effective Dart guidelines, and finally other industry standards.

##### 1.1.2. Consolidate research findings

After all research steps complete, consolidate findings:

- Document relevant file paths from repo research (e.g., `app/authentication/forms/authentication_form.dart:42`)
- **Include relevant institutional learnings** from `wingspan/solutions/` (key insights, gotchas to avoid)
- Note external documentation URLs and best practices (if external research was done)
- List related issues or PRs discovered
- Capture CLAUDE.md conventions

**Optional validation:** Briefly summarize findings and ask if anything looks off or missing before proceeding to planning.

### 2. Issue planning and structure

<thinking>
Think like a product manager - what would make this issue clear and actionable? Consider multiple perspectives
</thinking>

**Title & Categorization:**

- [ ] Draft clear, searchable issue title using the conventional commits format (e.g., `feat: Add user authentication`, `fix: Cart total calculation`)
- [ ] Determine issue type: enhancement, bug, refactor
- [ ] Convert title to filename: add today's date prefix, strip prefix colon, kebab-case, add `-plan` suffix
  - Example: `feat: Add User Authentication` → `2026-01-21-feat-add-user-authentication-plan.md`
  - Keep it descriptive (3-5 words after prefix) so plans are findable by context

**Stakeholder Analysis:**

- [ ] Identify who will be affected by this issue (end users, developers, operations)
- [ ] Consider implementation complexity and required expertise

**Content Planning:**

- [ ] Choose appropriate detail level based on issue complexity and audience
- [ ] List all necessary sections for the chosen template
- [ ] Gather supporting materials (error logs, screenshots, design mockups)
- [ ] Prepare code examples or reproduction steps if applicable, name the mock filenames in the lists

### 3. SpecFlow Analysis

After planning the issue structure, run the **specflow-analysis-agent** to analyze the plan and suggest improvements based on SpecFlow principles:

- Task @specflow-analysis-agent(feature_description, research_findings)

**SpecFlow Analyzer Output:**

- [ ] Review SpecFlow analysis results
- [ ] Incorporate any identified gaps or edge cases into the issue
- [ ] Update acceptance criteria based on SpecFlow findings

### 3. Select implementation detail template

#### Minimal

Use for simple bugs, small enhancements, or when the implementation is straightforward and well-understood.

It includes:

- Problem/feature description
- Acceptance criteria
- Essential context 

Use the `implementation-detail-levels/minimal.md` template for this level.

#### Standard

Use for most features and bug fixes that require a moderate level of detail to ensure clarity and successful implementation.

It includes:

- Everything in Minimal, plus:
  - Detailed background and motivation
  - Technical considerations
  - Success metrics
  - Dependencies and risks
  - Basic implementation suggestions

Use the `implementation-detail-levels/standard.md` template for this level.

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

Use the `implementation-detail-levels/extensive.md` template for this level.

### 4. Issue creation and formatting

<thinking>
Apply best practices for clarity and actionability, making the issue easy to scan and understand
</thinking>

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

### 5. Final review

**Pre-submission Checklist:**

- [ ] Title is searchable and descriptive
- [ ] Labels accurately categorize the issue
- [ ] All template sections are complete
- [ ] Links and references are working
- [ ] Acceptance criteria are measurable
- [ ] Add names of files in pseudo code examples and todo lists
- [ ] Add an ERD mermaid diagram if applicable for new model changes

## Output Format

**Filename:** Use the date and kebab-case filename from Step 2 Title & Categorization: `wingspan/plans/YYYY-MM-DD-<type>-<descriptive-name>-plan.md`


Examples:
- ✅ `wingspan/plans/2026-01-15-feat-user-authentication-flow-plan.md`
- ✅ `wingspan/plans/2026-02-03-fix-checkout-race-condition-plan.md`
- ✅ `wingspan/plans/2026-03-10-refactor-api-client-extraction-plan.md`
- ❌ `wingspan/plans/2026-01-15-feat-thing-plan.md` (not descriptive - what "thing"?)
- ❌ `wingspan/plans/2026-01-15-feat-new-feature-plan.md` (too vague - what feature?)
- ❌ `wingspan/plans/2026-01-15-feat: user auth-plan.md` (invalid characters - colon and space)
- ❌ `wingspan/plans/feat-user-auth-plan.md` (missing date prefix)

## Post-Generation Options

After writing the plan file, let the use know where the plan file is ready for review.
