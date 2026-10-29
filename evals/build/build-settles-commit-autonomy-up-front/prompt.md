---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [build]
description: "That the build opens by settling how commits are handled, and confirms scope, before any code is written."
---

Here is the implementation plan we settled on. It is not checked into this repo, so the text below is the authoritative copy — work from it, not from anything on disk.

# Plan: Add a reset method to Counter

- **Type:** feat
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: Counter can be returned to its starting value without being recreated.

SUCCESS CRITERIA:
- reset() sets the value back to 0 after any number of add() calls | verify: npm test
- The existing add() behavior is unchanged | verify: npm test

NON-GOALS:
- No subtract(), no history, no events.

VERIFICATION COMMAND: npm test
```

## Tasks

1. Add a `reset()` method to the `Counter` class in `src/counter.js` that returns the internal value to 0.
2. Add a test in `test/counter.test.js` that calls `add()` a few times, calls `reset()`, and asserts the value is 0.

Go ahead and build it.
