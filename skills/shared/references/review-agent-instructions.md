# Review Agent Instructions

These instructions are passed to every quality-review agent. Substitute `<RAW_DIR>`
with the absolute path given in the calling skill (e.g. `<PWD>/docs/code-review/raw`).

Each agent produces two outputs:

1. **A detailed report on disk** (for deep reference), and
2. **A structured findings list returned to the caller** (the single source the caller
   uses to number, consolidate, and render both the file and the chat summary).

## 1 — Write the detailed report

Write your full report to `<RAW_DIR>/<name>.md` (create the directory if needed).
This is an absolute path — use it exactly as given, do not convert to relative.
Use your normal Output Format. This file is for the user to drill into; it is not
read back into the caller's context, so be as thorough as you like here.

## 2 — Return a structured findings list

Return ONLY the block below to the caller. Do **not** return the full report text.

One list item per finding. Order your own findings by severity (Critical, then
Important, then Suggestion). Keep `title`, `why`, and `fix` to a single line each so
the caller can render them verbatim without re-reading the report.

```markdown
## <Agent Name> Findings
**Report**: `<RAW_DIR>/<name>.md`
**Critical**: <count> | **Important**: <count> | **Suggestion**: <count>

- severity: Critical
  rule: <short kebab-case slug for the check that fired, e.g. "missing-disposal">
  title: <short imperative title, e.g. "Dispose the stream subscription">
  location: <file:line, or file, or "-" if not file-specific>
  why: <one line — the concrete impact>
  fix: <one line — the concrete action to take>
- severity: Important
  rule: ...
  title: ...
  location: ...
  why: ...
  fix: ...
```

If you found nothing, return the header with all counts at `0` and no list items.

### Rules

- **Every finding must have a `location`.** Prefer `file:line`. This lets the caller
  deduplicate findings that overlap with other agents and keeps IDs stable.
- **`rule` names the check, not the instance.** Use a short, reusable kebab-case slug
  (`missing-null-check`, `deprecated-model-id`, `layer-violation`) — reuse the same slug
  every time the same check fires so the caller can namespace it and let users suppress a
  whole class. Do not put a file path or line in the rule.
- **Titles are the finding's identity.** Write a distinct, specific title per finding —
  the caller uses it verbatim in both the file and the chat summary.
- **No IDs.** The caller assigns the stable `FINDING-NN` id after collecting every
  agent's list. Do not invent your own ids.
- **`why` and `fix` are mandatory and one line each.** A finding with no fix is noise.
- Do not apply fixes. You review and report; the caller decides what to act on.
