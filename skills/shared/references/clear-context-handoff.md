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

## No slash commands? (cross-harness)

`/clear` and `/<skill>` are Claude Code slash commands. On a host that activates skills
by description rather than typed commands, keep the intent and drop the syntax: tell the
user to **start a fresh session or clear the context**, then to **ask for `<NEXT_ACTION>`
referencing `<DOC_PATH>`** — the next skill activates from that request's description. The
slash form stays as the Claude Code convenience.
