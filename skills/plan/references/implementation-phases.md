# Implementation Phases block

The single source for the `## Implementation Phases` structure. Templates that support
phased execution embed this block, and `/build` reads it to execute one phase per context
window.

Phases are optional. A small plan stays single-phase and omits this section — `/build` then
treats the whole plan as one phase. Add phases when the work is too large to implement well in
one context window (for example, when the plan-splitting assessment recommends a split and the
developer keeps a single plan).

Rules:

- Size each phase to fit comfortably in one AI context window.
- Order phases so the codebase compiles and its tests pass after every phase.
- Keep each phase self-contained enough to commit on its own.

Embed this block verbatim, one `### Phase N` per phase, filling in the placeholders:

```markdown
## Implementation Phases

### Phase 1: <short name>

- **Status:** Not started
- **Scope:** <1-2 sentences on what this phase delivers>
- **Files touched:** `<path>`, `<path>`
- **Acceptance criteria:** <observable proof this phase is complete>
- **Validation:** `<command; exit 0 = pass>` — or `manual <numbered steps>`

### Phase N: <short name>

- Same fields as above — one block per phase.
```

`**Status:**` starts at `Not started`. `/build` sets it to `Done` after it commits the phase,
so progress survives a context clear: on re-entry `/build` resumes at the first phase whose
status is not `Done`.
