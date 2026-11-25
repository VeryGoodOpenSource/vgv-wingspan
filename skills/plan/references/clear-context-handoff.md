# Clear Context Handoff

When a "Clear context and [next step]" option is selected, output the following block (substituting the actual skill and document path) and then **stop**:

```md
To continue with a fresh context, run:

/clear

Then start <NEXT_ACTION> with:

/<NEXT_SKILL> <DOC_PATH>
```

Print the block even when the document cannot be read from here — a cleared context is a new
session, and the skill that picks it up validates the path. Checking the file first, and then
withholding the block because the check failed, strands the user mid-handoff.

Where:
- `<NEXT_ACTION>` — the verb for the next phase (e.g., "planning", "building")
- `<NEXT_SKILL>` — the skill to invoke (e.g., `plan`, `build`)
- `<DOC_PATH>` — the full path to the document produced in the current phase
