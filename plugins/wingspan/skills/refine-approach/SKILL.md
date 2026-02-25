---
name: refine-approach
description: This skill should be used to review and refine proposed brainstorms and planning documents before proceeding to implementation. It identifies gaps, clarifies assumptions, and ensures the approach is well thought out.
---

# Refine Approach

Improve brainstorm and/or planning documents through structured review.

## Step 1. Get the document that needs review

**If a document is provided** then proceed to `Step 2. Assess`.

**If no document is provided**, ask the user which document to review. Check `wingspan/brainstorms/` and `wingspan/plans/` for recent documents to suggest.

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

1. **Refine again** - Another review pass
2. **Review complete** - Document is ready

### Iteration guidance

After 2 refinement passes, recommend completion—diminishing returns are likely. But if the user wants to continue, allow it.

Return control to the caller (workflow or user) after selection.

## What NOT to Do

- Do not rewrite the entire document
- Do not add new sections or requirements the user didn't discuss
- Do not over-engineer or add complexity
- Do not create separate review files or add metadata sections
