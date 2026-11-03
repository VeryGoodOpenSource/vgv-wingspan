---
name: refine-approach
user-invocable: true
description: Reviews and refines brainstorm or planning documents before implementation. Identifies gaps, clarifies assumptions, and ensures the approach is sound.
when_to_use: Use when a brainstorm or planning document already exists and the user wants it tightened before it is acted on — gaps named, assumptions surfaced, vague wording pinned down. Triggers on "refine this", "review my approach", "is this ready", "what is missing from this", "poke holes in this".
argument-hint: path to document to refine
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Refine Approach

Improve brainstorm and/or planning documents through structured review.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

## Step 1. Get the document that needs review

**Document path:** `$ARGUMENTS`

**If `$ARGUMENTS` is non-empty**, treat it as the document path and proceed to `Step 2. Assess`.

**If `$ARGUMENTS` is empty**, ask the user which document to review. Check `docs/brainstorm/` and `docs/plan/` for recent documents to suggest.

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

**If the user selects "Clear context and plan"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/plan` with the actual brainstorm doc path. Then stop.

**If the user selects "Clear context and build"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/build` with the actual plan file path. Then stop.

**When invoked by another skill** (e.g., from `/brainstorm` or `/plan`), only offer "Refine again" and "Review complete", then return control to the caller.

### Iteration guidance

After 2 refinement passes, recommend completion—diminishing returns are likely. But if the user wants to continue, allow it.

## What NOT to Do

- Do not rewrite the entire document
- Do not add new sections or requirements the user didn't discuss
- Do not over-engineer or add complexity
- Do not create separate review files or add metadata sections

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
