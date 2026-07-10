# Clear Context Handoff

When a "Clear context and [next step]" option is selected, output the following block (substituting the actual skill and document path) and then **stop**:

```md
To continue with a fresh context, run:

/clear

Then start <NEXT_ACTION> with:

/<NEXT_SKILL> <DOC_PATH>
```

Where:
- `<NEXT_ACTION>` — the verb for the next phase (e.g., "planning", "building")
- `<NEXT_SKILL>` — the skill to invoke (e.g., `plan`, `build`)
- `<DOC_PATH>` — the full path to the document produced in the current phase

**On GitHub Copilot CLI**, `/clear` and `/<skill-name>` work the same, except
`/plan` and `/review` are reserved by built-in commands. When the next skill is
one of those, replace the second command with a plain-language first message
instead: `Use the vgv-wingspan <NEXT_SKILL> skill: <DOC_PATH>`.
