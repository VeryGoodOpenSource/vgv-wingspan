# Issue Previews

Format the debrief's action items as ready-to-copy issue drafts. Read the action items back
from the written debrief document, not from memory.

Output is display only. Do not call `gh`, `glab`, or any other external CLI — the user files
the issues themselves.

## With project templates

Look for `.github/ISSUE_TEMPLATE/` in the project root and read every `.yaml` or `.yml` file
there, skipping `config.yml`.

Render one preview block per action item using the template that best fits its content — a
missing test or validation gap maps to a bug report, a new monitoring check to a feature
request, a dependency update or runbook to a chore. Populate every field the template marks
required, and include a `Template:` line naming the file you chose.

## Without templates

Fall back to the generic format:

```text
---
Title: <specific, actionable title>
Label: prevent | detect | respond
Body:
  ## Context
  Debrief: docs/debriefs/YYYY-MM-DD-<topic>-debrief.md
  Root cause: <one-line summary from debrief>

  ## What happened
  <relevant excerpt from the debrief timeline or root cause section>

  ## What to do
  <the action item, specific and linked to code/files where possible>
---
```

Render all previews in a single fenced block so the user can copy them in one go.
