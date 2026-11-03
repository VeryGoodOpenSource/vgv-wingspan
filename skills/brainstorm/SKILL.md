---
name: brainstorm
user-invocable: true
description: Explores requirements and approaches through collaborative dialogue before planning implementation.
when_to_use: Use when the user wants to work out what to build before any of it is built — the idea is still loose, the trade-offs are open, or they want approaches weighed rather than code written. Triggers on "brainstorm", "explore idea", "what should we build", "think through this", "let's discuss approaches", and on an idea pitched for discussion with nothing decided yet.
argument-hint: feature or idea to explore
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Brainstorm a feature or improvement

Clarify **WHAT** to build before diving into **HOW** to build it. Explore user intent, approaches, and design decisions through collaborative dialogue.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

## Feature description

<feature description>$ARGUMENTS</feature description>

**If the feature description above is empty, ask the user**: "What feature would you like to brainstorm? Describe the idea, problem or feature you are thinking about."

DO NOT proceed until you have a description from the user.

## Execution flow

### 0. Assess scope and workspace

Determine whether this is a **new project** or a **feature for the current project**.

| Signal | Conclusion |
|--------|------------|
| User says "new app", "new project", "build from scratch"; no relevant code in working directory | New project |
| User references existing code/screens; idea extends current functionality | Feature for current project → skip to Step 0.1 |

**If new project**, use **AskUserQuestion**: "This sounds like a new project. Where would you like to work?"

1. **Create project first (Recommended)** — output instructions to run `/create`, open the new folder, then `/brainstorm <description>` in that workspace. Then stop.
2. **Continue here** — proceed to Step 0.1

### 0.1. Assess clarity of requirements

Assess whether brainstorming is needed.

| Requirements are clear | Brainstorming is needed |
|------------------------|------------------------|
| Specific acceptance criteria provided | Vague terms ("make it better", "add something like") |
| Exact behavior described, scope constrained | Multiple reasonable interpretations, trade-offs undiscussed |

**If clear:** the thinking is already done, so do not re-open it. Record it (Step 2) and go
straight to the Step 3 handoff, offering the same options in the same order — **Clear context
and plan** first and marked as recommended. A brainstorm that arrives settled still leaves by
the handoff; skipping it drops the user somewhere other than `/plan`.

### 1. Understand the idea

#### 1.1. Lightweight project research

Run a quick project review to understand existing patterns:

- Task @codebase-review-agent("Understand existing patterns related to: <feature_description>")

Focus on: similar features, established patterns, CLAUDE.md guidance.

#### 1.2. Collaborative conversation

Use the **AskUserQuestion tool** to ask questions one at a time. The tool automatically provides an "Other" option for free-text input — never add your own catch-all option (e.g., "Something else", "None of the above").

**Question Techniques:** Prefer multiple choice over open-ended. Start broad (purpose, users) then narrow (constraints, edge cases). Validate assumptions explicitly. Ask about success criteria early.

**Purpose and users come before the stack.** When the idea arrives as a pile of technology —
a queue, a cache, a service — the first question is still what the feature has to do and for
whom, not how the pieces wire together. Asking about deployment, storage or transport before
anyone has said what the user should get accepts the stack as settled, which is the one thing
this step exists to reopen.

**Key Topics to Explore:**

| Topic | Example Questions |
|-------|-------------------|
| Purpose | What problem does this solve? What's the motivation? |
| Users | Who uses this? What's their context? |
| Constraints | Any technical limitations? Timeline? Dependencies? |
| Success | How will you measure success? What's the happy path? |
| Edge Cases | What shouldn't happen? Any error states to consider? |
| Existing Patterns | Are there similar features in the codebase to follow? |

**Exit condition:** Continue until the idea is clear OR user says "proceed" or "let's move on."

#### 1.3. Explore approaches

Propose **2-3 concrete approaches** with trade-offs. Lead with your recommendation and explain why.

**Guidelines:**

- **YAGNI ruthlessly.** If an approach adds complexity for a hypothetical future need, call it out and lean toward the simpler option. The question is always: "Do we need this now, or are we guessing?"
- **Prefer boring patterns.** If the codebase already solves a similar problem, default to that pattern. Consistency beats cleverness.
- **Right-size the architecture.** Not every feature needs its own package. Not every screen needs a new state management controller. Match the solution to the actual complexity.

**Structure for Each Approach:**

```markdown
**[Approach Name]** <- [Is it recommended? Yes/No]

[2-3 sentence description of what this looks like in practice]

- Pros: [what's good]
- Cons: [what's not]
- Best when: [the circumstances where this wins]
```

Use **AskUserQuestion tool** to ask which approach the user prefers.

#### 1.4. Set up workspace

Before writing any files, ensure the session is not on the base branch:

- Run `git rev-parse --abbrev-ref HEAD`. If the current branch is a base branch (`main`, `master`, or `develop`), use **AskUserQuestion** to offer creating a feature branch — `git checkout -b <type>/<kebab-topic>`, name under 60 characters — before writing. If already on a feature branch, continue without prompting.
- If git is unavailable or the command fails, skip this step and deliver the document in your reply instead. Never let the question of where the file lives stop the write-up from being produced.
- Ask about a branch only on a branch name the command actually returned. Never infer the current branch from the directory, the prompt, or a guess, and never open with a branching question you cannot ground — a document withheld behind an invented gate is a document the user did not get.

### 2. Capture the design document

Write a brainstorm document to `docs/brainstorm/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md`.

If the user names a path for the document, write it there instead and keep their name.

Ensure `docs/brainstorm/` directory exists before writing.

Use the [brainstorm template](references/template.md) as the document structure, keeping its
section headings as they are written — `## What We're Building`, `## Why This Approach`,
`## Key Decisions`, `## Open Questions`. `/plan` reads the document back by those headings,
and a heading of your own wording, however apt, is one it cannot find.

### 3. Handoff

Use **AskUserQuestion tool** to consider next steps:

**Question**: "Brainstorm complete! What would you like to do next?"

**Options:**
1. **Clear context and plan (Recommended)**: clear context for a fresh start, then plan
2. **Continue with planning**: run the `/plan` skill to create a detailed implementation plan
3. **Review and refine approach:** improve the document using structured review
4. **Done for now**: brainstorm complete. To start planning later: `/plan`

**If the user selects "Clear context and plan"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/plan` with the actual brainstorm doc path. Then stop.

**If the user selects "Review and refine approach"** then apply the @refine-approach skill to the document.

When `refine-approach` is complete, present these options:

1. **Clear context and plan (Recommended)**: clear context for a fresh start, then plan
2. **Move to planning**: run the `/plan` skill to create a detailed implementation plan
3. **Done for now**: ideation complete. To start planning later: `/plan`

**If the user selects "Clear context and plan"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/plan` with the actual brainstorm doc path. Then stop.

## Output Summary

When complete, display:

```md
Brainstorm complete!

Document: docs/brainstorm/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md

Key decisions:
- [Decision 1]
- [Decision 2]
```

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense

## Important Guidelines

**DO NOT CODE!** Just explore and document decisions.

#### The handoff block

The handoff is the user's only instruction for picking the work up in a fresh session, so its
shape is fixed here and not only in the reference. Print exactly this and then **stop**,
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
