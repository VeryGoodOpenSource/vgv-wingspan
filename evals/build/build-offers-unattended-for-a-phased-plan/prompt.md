---
max_turns: 30
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill]
tags: [build]
description: "That a plan with several phases gets the option to run them all unattended, inside the commit question, before any code is written."
---

Here is the implementation plan we settled on. It is not checked into this repo, so the text below is the authoritative copy — work from it, not from anything on disk.

# Plan: Extend Counter

- **Type:** feat
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: Counter can be reset, decremented, and read as a string.

SUCCESS CRITERIA:
- reset() sets the value back to 0 | verify: npm test
- subtract(n) lowers the value by n | verify: npm test
- toString() returns "Counter(<value>)" | verify: npm test

NON-GOALS:
- No history, no events.

VERIFICATION COMMAND: npm test
```

## Implementation Phases

### Phase 1: Reset

- **Status:** Not started
- **Scope:** Add `reset()` to `Counter` and test it.
- **Files touched:** `src/counter.js`, `test/counter.test.js`
- **Acceptance criteria:** `reset()` returns the value to 0 after any number of `add()` calls.
- **Validation:** `npm test`

### Phase 2: Subtract

- **Status:** Not started
- **Scope:** Add `subtract(amount)` to `Counter` and test it.
- **Files touched:** `src/counter.js`, `test/counter.test.js`
- **Acceptance criteria:** `subtract(2)` after `add(5)` leaves the value at 3.
- **Validation:** `npm test`

### Phase 3: String form

- **Status:** Not started
- **Scope:** Add `toString()` to `Counter` and test it.
- **Files touched:** `src/counter.js`, `test/counter.test.js`
- **Acceptance criteria:** `String(counter)` returns `Counter(3)` when the value is 3.
- **Validation:** `npm test`

Go ahead and build it.
