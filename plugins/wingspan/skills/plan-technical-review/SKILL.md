---
name: plan-technical-review
description: Conducts a comprehensive technical review of the plan, ensuring it meets requirements, follows best practices, and is ready for implementation.
---

# Plan technical review

Run the following agents in parallel to conduct a comprehensive technical review of the proposed plan:

- @code-simplicity-review-agent: Review the plan for simplicity and clarity. Ensure the implementation is as straightforward as possible while still meeting all requirements.
- @vgv-review-agent: Review the plan for adherence to Very Good Engineering practices. Ensure the implementation follows our established patterns and conventions.
- @plan-splitting-agent: Assess plan scope and recommend splitting into multiple PRs if the plan is too large for a single reviewable PR.

After all agents complete, if the plan-splitting-agent recommends a split:

1. Present the proposal to the developer via **AskUserQuestion** with options:
   - **Apply this split**: generate separate plan files
   - **Keep as single PR**: proceed without splitting
2. If approved, generate separate plan files:
   - The **skill** (not the agent) generates the files
   - Naming: `docs/plan/YYYY-MM-DD-<type>-<original-slug>-part-N-plan.md`
   - Each file is a standalone plan following the **same template and detail level** as the original plan
   - Each file includes all sections `/build` expects: title, type, acceptance criteria, tasks, file references. Reference `plugins/wingspan/skills/plan/implementation-detail-levels/` for template structure.
   - Each file includes a `## Dependencies` section noting which prior PR(s) must merge first
   - Add a note at the top of the original plan file: ``> **Note:** This plan has been split into parts. See the `-part-N` files in this directory.``

If the plan-splitting-agent reports no split needed: include the scope summary in the review output, no further action.
