---
name: brainstorming
description: This skill should be used before implementing features, building components, or making changes. It guides exploring user intent, approaches, and design decisions before planning. Triggers on "let's brainstorm", "help me think through", "what should we build", "explore approaches", ambiguous feature requests, or when the user's request has multiple valid interpretations that need clarification.
---

# Brainstorming

This skill provides detailed process knowledge for effective brainstorming sessions that clarify **WHAT** to build before diving into **HOW** to build it.

## When to use this skill

Brainstorming is valuable when:
- Requirements are unclear or ambiguous
- Multiple approaches could solve the problem
- Trade-offs need to be explored with the user
- The user hasn't fully articulated what they want
- The feature scope needs refinement

Brainstorming can be skipped when:
- Requirements are explicit and detailed
- The user knows exactly what they want
- The task is a straightforward bug fix or well-defined change

## The process

### 0. Assess requirement clarity

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

If requirements are clear, suggest: "Your requirements seem clear. Consider proceeding directly to planning or implementation."

### 1. Understanding the idea

- Ask questions **one at a time** to understand the user's intent and refine the idea. Avoid overwhelming with too many questions.
- Check out the current project state first (files, docs, recent commits)
- Focus on understanding: purpose, constraints, success criteria

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

**Exit Condition:** Continue until the idea is clear OR user says "proceed" or "let's move on"

### 2. Exploring approaches

- Propose 2-3 different approaches with trade-offs
- Present options conversationally with your recommendation and reasoning
- Lead with your recommended option and explain why

**Guidelines:**
- **YAGNI ruthlessly.** If an approach adds complexity for a hypothetical future need, call it out and lean toward the simpler option. The question is always: "Do we need this now, or are we guessing?"
- **Prefer boring patterns.** If the codebase already solves a similar problem, default to that pattern. Consistency beats cleverness.
- **Right-size the architecture.** Not every feature needs its own package. Not every screen needs a new bloc. Match the solution to the actual complexity.

**Structure for Each Approach:**

```markdown
**[Approach Name]** ← [Is it recommended? Yes/No]

[2–3 sentence description of what this looks like in practice]

- Pros: [what's good]
- Cons: [what's not]
- Best when: [the circumstances where this wins]
```

### 3. Present the design document

Once an approach is chosen, present the design document in **short sections (200–300 words each)**. 

After each section, check: *"Does this match what you had in mind?"*

Sections to cover (skip what isn't relevant):

- **What we're building** — plain-language description anyone on the team can read
- **User experience** — key screens, flows, interactions, platform considerations
- **Package & layer structure** — where this lives in the monorepo, what's new vs. modified
- **State management** — blocs/cubits, events, states, key flows
- **Data layer** — models, repositories, API clients, local storage
- **Edge cases & error handling** — empty states, failures, loading, permissions
- **Testing approach** — what to test at which layer, any golden tests needed
- **Open questions** — things that still need answers before implementation

### 4. Capture a design document

- Write the validated design document to `wingspan/brainstorms/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md`
- Use @ elements-of-style-optimized skill to ensure clear, concise writing
- Include diagrams if helpful

**Design document structure**

```markdown
---
date: YYYY-MM-DD
topic: <kebab-case-topic>
---

# <Topic Title>

## What We're Building
[Concise description—1-2 paragraphs max]

## Why This Approach
[Brief explanation of approaches considered and why this one was chosen]

## Key Decisions
- [Decision 1]: [Rationale]
- [Decision 2]: [Rationale]

## Open Questions
- [Any unresolved questions for the planning phase]
```

## Key Principles

- **One question at a time** - Don't overwhelm with multiple questions
- **Multiple choice preferred** - Easier to answer than open-ended when possible
- **YAGNI ruthlessly** - Remove unnecessary features from all designs
- **Explore alternatives** - Always propose 2-3 approaches before settling
- **Incremental validation** - Present design in sections, validate each
- **Be flexible** - Go back and clarify when something doesn't make sense