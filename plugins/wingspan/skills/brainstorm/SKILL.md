---
name: brainstorm
description: Explore requirements and approaches through collaborative dialogue before planning implementation
---

# Brainstorm a feature or improvement

Clarify **WHAT** to build before diving into **HOW** to build it. Explore user intent, approaches, and design decisions through collaborative dialogue.

## Feature description

<feature description>$ARGUMENTS</feature description>

**If the feature description above is empty, ask the user**: "What feature would you like to brainstorm? Describe the idea, problem or feature you are thinking about."

DO NOT proceed until you have a description from the user.

## Execution flow

### 0. Assess clarity of requirements

Before diving into questions, assess whether brainstorming is needed.

**Signals that requirements are clear:**

- User provided specific acceptance criteria
- User referenced existing patterns to follow
- User described exact behavior expected
- Scope is constrained and well-defined

**Signals that brainstorming is needed:**

- User used vague terms ("make it better", "add something like")
- Multiple reasonable interpretations exist
- Trade-offs haven't been discussed
- User seems unsure about the approach

**If requirements are clear:** Use **AskUserQuestion tool** to let the user know: "Your requirements seem clear. Consider proceeding directly to planning or implementation."

### 1. Understand the idea

#### 1.1. Lightweight project research

Run a quick project review to understand existing patterns:

- Task @codebase-review-agent("Understand existing patterns related to: <feature_description>")

Focus on: similar features, established patterns, CLAUDE.md guidance.

#### 1.2. Collaborative conversation

Use the **AskUserQuestion tool** to ask questions one at a time.

**Question Techniques:**

1. **Prefer multiple choice when natural options exist**
   - Good: "Should the notification be: (a) email only, (b) in-app only, or (c) both?"
   - Avoid: "How should users be notified?"

2. **Start broad, then narrow**
   - First: What is the core purpose?
   - Then: Who are the users?
   - Finally: What constraints exist?

3. **Validate assumptions explicitly**
   - "I'm assuming users will be logged in. Is that correct?"

4. **Ask about success criteria early**
   - "How will you know this feature is working well?"

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

Before writing any files, ensure the session is on a feature branch:

- Call @create-branch to check and optionally create a working branch or worktree.

### 2. Capture the design document

Write a brainstorm document to `docs/brainstorm/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md`.

Ensure `docs/brainstorm/` directory exists before writing.

**Document structure:**

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## What We're Building
[Concise description -- 1-2 paragraphs max]

## Why This Approach
[Brief explanation of approaches considered and why this one was chosen]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Any unresolved questions for the planning phase]
```

### 3. Handoff

Use **AskUserQuestion tool** to consider next steps:

**Question**: "Brainstorm complete! What would you like to do next?"

**Options:**
1. **Clear context and plan**: clear context for a fresh start, then plan
2. **Continue with planning**: run the `/plan` skill to create a detailed implementation plan
3. **Review and refine approach:** improve the document using structured review
4. **Done for now**: brainstorm complete. To start planning later: `/plan`

**If the user selects "Clear context and plan"** → output the following and then stop:

```
To continue with a fresh context, run:

/clear

Then start planning with:

/plan
```

**If the user selects "Review and refine approach"** then apply the @refine-approach skill to the document.

When `refine-approach` is complete, present these options:

1. **Clear context and plan**: clear context for a fresh start, then plan
2. **Move to planning**: run the `/plan` skill to create a detailed implementation plan
3. **Done for now**: ideation complete. To start planning later: `/plan`

**If the user selects "Clear context and plan"** → output the same instructions as above and then stop.

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
