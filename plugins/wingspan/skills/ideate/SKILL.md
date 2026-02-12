---
name: ideate
description: Explore requirements and approaches through collaborative dialogue before planning implementation
---

# Ideate and brainstorm a feature or improvement

**Process knowledge**: load the @brainstorming skill for detailed question techniques, approach exploration patterns, YAGNI principles, and requirement clarity assessment.

## Feature description

<feature description>$ARGUMENTS</feature description>

**If the feature description above is empty, ask the user**: "What feature would you like to ideate? Describe the idea, problem or feature you are thinking about."

DO NOT proceed until you have a description from the user.

## Execution flow

### 0. Assess clarity of requirements

Evaluate if brainstorming is needed based on the feature description. 

**Signals that indicate clarity in requirements:**
- User provided specific acceptance criteria
- User referenced existing patterns to follow
- User described exact behavior expected
- Scope is constrained and well-defined

**If requirements are clear:** Use **AskUserQuestion tool** to let the user know: "Your requirements seem clear. Consider proceeding directly to planning or implementation."

### 1. Understand the idea

#### 1.1. Collaborative conversation

Use the **AskUserQuestion tool** to ask questions one at a time. Follow the guidelines in the @brainstorming skill for question techniques, and validate assumptions explicitly.

**Exit condition:** Continue until the idea is clear OR user says "proceed".

#### 1.2. Explore approaches

Propose **2-3 concrete approaches** based on research and conversation.

For each approach, provide:
- Brief description (2-3 sentences)
- Pros and cons
- When it's best suited

Lead with your recommendation and explain why. Apply YAGNI—prefer simpler solutions.

Use **AskUserQuestion tool** to ask which approach the user prefers.

### 2. Capture the design document

Write a brainstorm document to `wingspan/brainstorms/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md`.

**Document structure:** See the `brainstorming` skill for the template format. Key sections: What We're Building, Why This Approach, Key Decisions, Open Questions.

Ensure `wingspan/brainstorms/` directory exists before writing.

### 3. Handoff

Use **AskUserQuestion tool** to consider next steps:

**Question**: "Ideation complete! What would you like to do next?"

**Options:**
1. **Review and refine approach:** Improve the document using structured review
2. **Done for now**

**If the user selects "Review and refine approach"** then load apply the @refine-approach skill to the document in question.

When `refine-approach` is complete, return to this step to ask about next steps again.

## Output Summary

When complete, display:

```
Brainstorm complete!

Document: wingspan/brainstorms/YYYY-MM-DD-<kebab-case-topic>-brainstorm-doc.md

Key decisions:
- [Decision 1]
- [Decision 2]
```

## Important Guidelines

**DO NOT CODE!** Just explore and document decisions.