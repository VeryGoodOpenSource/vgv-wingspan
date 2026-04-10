---
name: plan-technical-review
user-invocable: true
description: Conducts a comprehensive technical review of an implementation plan, ensuring it meets requirements and follows best practices. Use when user says "review the plan", "is this plan ready", "validate my plan", or "check the plan".
argument-hint: path to plan file
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Plan technical review

Run the following agents in parallel to conduct a comprehensive technical review of the proposed plan:

- @code-simplicity-review-agent: Review the plan for simplicity and clarity. Ensure the implementation is as straightforward as possible while still meeting all requirements.
- @vgv-review-agent: Review the plan for adherence to Very Good Engineering practices and project conventions. Ensure the implementation follows our established patterns and conventions.
- @plan-splitting-agent: Assess plan scope and recommend splitting into multiple PRs if the plan is too large for a single reviewable PR.

After all agents complete, if the plan-splitting-agent recommends a split:

1. Present the proposal to the developer via **AskUserQuestion** with options:
   - **Apply this split**: generate separate plan files
   - **Keep as single PR**: proceed without splitting
2. If approved, generate separate plan files:
   - The **skill** (not the agent) generates the files
   - Naming: `docs/plan/YYYY-MM-DD-<type>-<original-slug>-part-N-plan.md`
   - Each file is a standalone plan following the **same template and detail level** as the original plan
   - Each file includes all sections `/build` expects: title, type, acceptance criteria, tasks, file references. Use [standard template](references/standard.md) by default; use [minimal](references/minimal.md) for simple parts or [extensive](references/extensive.md) for complex parts.
   - Each file includes a `## Dependencies` section noting which prior PR(s) must merge first
   - Add a note at the top of the original plan file: ``> **Note:** This plan has been split into parts. See the `-part-N` files in this directory.``

If the plan-splitting-agent reports no split needed: include the scope summary in the review output, no further action.

## Handoff

**When invoked directly by the user**, use **AskUserQuestion** to present next steps after the review is complete:

**Question**: "Technical review complete! What would you like to do next?"

**Options:**

1. **Clear context and build (Recommended)**: clear context for a fresh start, then build
2. **Start building**: execute the plan with `/build`
3. **Refine the plan**: improve the plan based on review findings
4. **Done for now**: review complete

**If the user selects "Clear context and build"** → output the following (substituting the actual plan file path) and then stop:

```md
To continue with a fresh context, run:

/clear

Then start building with:

/build docs/plan/<actual-plan-filename>.md
```

**When invoked by another skill** (e.g., from `/plan`), return control to the caller after the review completes — do not present handoff options.
