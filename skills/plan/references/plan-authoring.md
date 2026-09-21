# Plan Authoring

Think like a product manager — what would make this plan clear and actionable to whoever
picks it up cold?

## Title and filename

Draft a searchable title in Conventional Commits form (`feat: add user authentication`,
`fix: cart total calculation`) and determine the type: enhancement, bug, or refactor.

Convert the title to the filename: prefix today's date, strip the colon after the type,
kebab-case the rest, and append `-plan`.

`feat: add user authentication` → `docs/plan/2026-01-21-feat-add-user-authentication-plan.md`

Keep it descriptive — three to five words after the prefix, so plans stay findable by
context. `2026-01-15-feat-thing-plan.md` is not findable; neither is a name with no date.

## Before choosing a template

- Identify who the change affects — end users, developers, operations — and what expertise
  it demands. That sizing drives the detail level.
- Gather supporting material: error logs, screenshots, design mockups, reproduction steps.
- Name the mock filenames in task lists, so the plan's file paths match what `/build` writes.

## Formatting the plan file

- Heading hierarchy (`##`, `###`) and fenced code blocks with language identifiers.
- Task lists (`- [ ]`) for trackable items; collapsible `<details>` for lengthy content.
- Link related issues and PRs (`#number`), commits (SHA), and code (repository permalinks).
- Carry forward any research prompt or instruction that worked well, so a rerun can reuse it.
- Add an ERD mermaid diagram when the plan introduces or changes data models.

## Before presenting the plan

Confirm every template section is filled, every link resolves, and every success criterion
carries a `verify:` command or `verify: manual <steps>`. A criterion with no `verify:` is the
one thing `/build` cannot act on.
