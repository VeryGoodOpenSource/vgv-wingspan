---
name: plan-technical-review
user-invocable: true
description: Reviews an externally-authored implementation plan for quality, VGV conventions, and scope. Plans created by /plan are already reviewed during creation.
when_to_use: Use to review a plan you did not create with /plan — a hand-written plan or one from another tool. Triggers on "review the plan", "is this plan ready", "validate my plan", or "check the plan".
argument-hint: path to plan file
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Plan technical review

Review a plan that was not created by `/plan`. `/plan` runs this same review inline during
creation, so use this skill for externally-authored plans — hand-written, from another tool,
or from a teammate.

> **Every question in this skill goes through the AskUserQuestion tool.** When that tool is
> not available — another harness, or a non-interactive session — put the same question and
> the same options in your reply as a short numbered list, and stop there for the answer.
> Never answer a question on the user's behalf and carry on: a question the user never sees
> is not a question, and a step that waits on one is not optional.

**Plan file:** `$ARGUMENTS` (if empty, ask the user for the plan path or pick the most recent file under `docs/plan/`).

## Review

Follow the [plan review procedure](references/plan-review.md) with `<PLAN_PATH>` set to the
plan file. It runs the simplicity, VGV, and scope-splitting agents in parallel, applies their
findings to the plan inline, and resolves any scope-splitting recommendation.

## Handoff

After the review completes, use **AskUserQuestion** to present next steps:

**Question**: "Technical review complete! What would you like to do next?"

**Options:**

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Start building**: execute the plan with `/build`
3. **Refine the plan**: improve the plan based on review findings
4. **Done for now**: review complete

**If the user selects "Clear context and build"** → Follow the [clear context handoff](references/clear-context-handoff.md) for `/build` with the actual plan file path. Then stop.

**When invoked by another skill**, return control to the caller after the review completes — do not present handoff options.

## Important

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
