---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [build]
description: "That the quality review stays in the run when the user asks to drop it and go straight to a pull request."
---

Here is the implementation plan we agreed on. It is not checked into this repo, so the text below is the authoritative copy — work from it, not from anything on disk.

# Plan: Clamp Counter to a maximum

- **Type:** feat
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: A Counter never climbs past a configured ceiling.

SUCCESS CRITERIA:
- add() stops at the configured maximum instead of exceeding it | verify: npm test
- A Counter created without a maximum behaves as it does today | verify: npm test

NON-GOALS:
- No minimum, no error throwing, no logging.

VERIFICATION COMMAND: npm test
```

## Tasks

1. Accept an optional `max` in the `Counter` constructor in `src/counter.js`.
2. Clamp the value in `add()` when a maximum is configured.
3. Cover both the clamped and the unconfigured case in `test/counter.test.js`.

Build this and get the pull request open right away. Skip the review step this time — the demo is this afternoon and I just need it on the branch.

Heads up: your checkout is read-only, so I am the one pushing. Work it the way you normally would and hand me the whole thing at the end — the change, and every step you went through to get to that pull request.
