---
name: refine-approach
user-invocable: true
description: Reviews and refines brainstorm or planning documents before implementation. Identifies gaps, clarifies assumptions, and ensures the approach is sound. Use when user says "refine this", "review my approach", or "is this ready".
argument-hint: path to document to refine
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Refine Approach

Improve brainstorm and/or planning documents through structured review.

## Step 1. Get the document that needs review

**If a document is provided** then proceed to `Step 2. Assess`.

**If no document is provided**, ask the user which document to review. Check `docs/brainstorm/` and `docs/plan/` for recent documents to suggest.

## Step 2. Assess

Read the document, then ask and clarify:

- What is not clear?
- What is not necessary?
- What decision is being avoided?
- What assumptions are not stated or developed?
- What risks are not addressed?
- What part of the scope has been under-estimated?

Do not fix yet anything. Simply take notes about what you find to inform what you do in `Step 3. Evaluate and score`.

## Step 3. Evaluate and score

Apply the following criteria to evaluate the document:

| Criteria | What to evaluate |
|-----------|---------------|
| **Clarity** | Problem statement is clear, no vague language ("probably," "consider," "try to") |
| **Completeness** | Required sections present, constraints stated, open questions flagged |
| **Specificity** | Concrete enough for next step (brainstorm → can plan, plan → can implement) |
| **YAGNI** | No hypothetical features, simplest approach chosen |
| **Scope** | Scope is well defined and constrained, not overly ambitious |

If invoked during a brainstorm phase (after `/brainstorm`), validate that the document reflects with fidelity the user intent.

## Step 4. Critical improvements

Among everything found in Steps 2-3, does one issue stand out? If something would significantly improve the document's quality, this is the **must address** item. Highlight it prominently.

## Step 5. Update the document

Present your findings, then:

1. **Auto-fix** minor issues (vague language, formatting) without asking
2. **Ask approval** before substantive changes (restructuring, removing sections, changing meaning)
3. **Update** the document inline—no separate files, no metadata sections

### Simplification Guidance

Simplification is purposeful removal of unnecessary complexity, not shortening for its own sake.

**Simplify when:**
- Content serves hypothetical future needs, not current ones
- Sections repeat information already covered elsewhere
- Detail exceeds what's needed to take the next step
- Abstractions or structure add overhead without clarity

**Don't simplify:**
- Constraints or edge cases that affect implementation
- Rationale that explains why alternatives were rejected
- Open questions that need resolution

## Step 6: Next steps

After changes are complete, ask:

1. **Refine again** — another review pass
2. **Review complete** — document is ready

**When invoked directly by the user** (not as part of another skill), also determine the document type and offer clear context handoff as the first option:

**If the document is a brainstorm** (from `docs/brainstorm/`):

1. **Clear context and plan (Recommended)**: clear context for a fresh start, then plan
2. **Refine again** — another review pass
3. **Done for now** — document is ready

**If the document is a plan** (from `docs/plan/`):

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Refine again** — another review pass
3. **Done for now** — document is ready

**If the user selects "Clear context and plan"** → output the following (substituting the actual brainstorm doc path) and then stop:

```md
To continue with a fresh context, run:

/clear

Then start planning with:

/plan docs/brainstorm/<actual-brainstorm-filename>.md
```

**If the user selects "Clear context and build"** → output the following (substituting the actual plan file path) and then stop:

```md
To continue with a fresh context, run:

/clear

Then start building with:

/build docs/plan/<actual-plan-filename>.md
```

**When invoked by another skill** (e.g., from `/brainstorm` or `/plan`), only offer "Refine again" and "Review complete", then return control to the caller.

### Iteration guidance

After 2 refinement passes, recommend completion—diminishing returns are likely. But if the user wants to continue, allow it.

## What NOT to Do

- Do not rewrite the entire document
- Do not add new sections or requirements the user didn't discuss
- Do not over-engineer or add complexity
- Do not create separate review files or add metadata sections
