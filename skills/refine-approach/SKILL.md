---
name: refine-approach
user-invocable: true
description: Reviews brainstorm, planning, and other documents before the next step, in one of two modes. An implementation plan not created by /plan — hand-written, from another tool, or from a teammate — gets a technical review that checks simplicity, VGV conventions, and scope with review agents and applies their findings to the plan. Any other document, or one handed over by /plan, /brainstorm, or /debrief, gets a document critique that finds gaps, unstated assumptions, and unsound reasoning. Use when the user says "review the plan", "is this plan ready", "validate my plan", "check the plan", "refine this", "review my approach", or "is this ready".
argument-hint: path to plan or document to review
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Refine Approach

Review a brainstorm, plan, or other document before the next step, and improve it in place.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.
>
> **Except in agent mode.** When the user turned on agent mode (`--agent-mode`, or "use
> Wingspan in agent mode"), follow [agent mode](references/agent-mode.md) instead: take the
> recommended option, record the decision in the decision log, and keep going.

## Step 1. Get the document that needs review

**Document path:** `$ARGUMENTS`

**If `$ARGUMENTS` is non-empty**, treat it as the document path and proceed to `Step 2. Choose the mode`.

**If `$ARGUMENTS` is empty**, ask the user which document to review. Check `docs/brainstorm/` and `docs/plan/` for recent documents to suggest.

## Step 2. Choose the mode

Pick the mode from the document and from who invoked the skill. Do not ask the user.

| Situation | Mode |
|-----------|------|
| Invoked by another skill (`/plan`, `/brainstorm`, `/debrief`) | **Document critique** |
| Invoked by the user on an implementation plan | **Technical review** |
| Invoked by the user on any other document (brainstorm, debrief, spec) | **Document critique** |

An implementation plan is a file under `docs/plan/`, or a document with a plan's shape: a
type, a proposed solution, and a task list. `/plan` runs the technical review on the plans
it creates, so a plan it hands over gets the critique only.

If the user names a mode — "run the review agents", "just critique the wording" — use that
mode instead.

- **Technical review** → follow `Step 3. Technical review`, then go to `Step 8. Next steps`.
- **Document critique** → skip Step 3 and follow Steps 4 to 7.

## Step 3. Technical review

Follow the [plan review procedure](references/plan-review.md) with `<PLAN_PATH>` set to the
plan file. It runs the simplicity, VGV, and scope-splitting agents in parallel, applies their
findings to the plan inline, and resolves any scope-splitting recommendation.

## Step 4. Assess

Read the document, then ask and clarify:

- What is not clear?
- What is not necessary?
- What decision is being avoided?
- What assumptions are not stated or developed?
- What risks are not addressed?
- What part of the scope has been under-estimated?

Do not fix yet anything. Simply take notes about what you find to inform what you do in `Step 5. Evaluate and score`.

## Step 5. Evaluate and score

Apply the following criteria to evaluate the document:

| Criteria | What to evaluate |
|-----------|---------------|
| **Clarity** | Problem statement is clear, no vague language ("probably," "consider," "try to") |
| **Completeness** | Required sections present, constraints stated, open questions flagged |
| **Specificity** | Concrete enough for next step (brainstorm → can plan, plan → can implement) |
| **YAGNI** | No hypothetical features, simplest approach chosen |
| **Scope** | Scope is well defined and constrained, not overly ambitious |

If invoked during a brainstorm phase (after `/brainstorm`), validate that the document reflects with fidelity the user intent.

## Step 6. Critical improvements

Among everything found in Steps 4-5, does one issue stand out? If something would significantly improve the document's quality, this is the **must address** item. Highlight it prominently, under a heading or label that reads "Must address".

## Step 7. Update the document

Present your findings, then:

1. **Auto-fix** minor issues (vague language, formatting) without asking
2. **Ask approval** before substantive changes (restructuring, removing sections, changing meaning)
3. **Update** the document inline — no separate files, no metadata sections

Refine what is there. Do not rewrite the whole document, and do not add sections or
requirements the user never discussed.

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

## Step 8. Next steps

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
2. **Start building** — execute the plan with `/build`
3. **Refine again** — another review pass
4. **Done for now** — document is ready

**If the user selects "Clear context and plan"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/plan` with the actual brainstorm doc path. Then stop.

**If the user selects "Clear context and build"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/build` with the actual plan file path. Then stop.

**If the user selects "Start building"** → Call the `/build` skill with the plan file path.

**If the user selects "Refine again"** → run a document critique pass (Steps 4 to 7). The
review agents have already run, so a second technical review repeats their findings.

**When invoked by another skill** (e.g., from `/brainstorm` or `/plan`), only offer "Refine again" and "Review complete", then return control to the caller.

### Iteration guidance

After 2 refinement passes, recommend completion—diminishing returns are likely. But if the user wants to continue, allow it.

## The handoff block

The handoff is the user's only instruction for picking the work up in a fresh session, so its
shape is fixed here as well as in the reference. Print exactly this and then **stop**,
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
