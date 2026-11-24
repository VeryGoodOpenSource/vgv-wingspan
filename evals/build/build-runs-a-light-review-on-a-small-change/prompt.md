---
max_turns: 40
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
tags: [build]
description: "That a two-file change with no risk signal gets the light review, and that the reviewers hear what Validate and the squash-only merge already cover."
---

Here is the implementation plan we settled on. It is not checked into this repo, so the text below is the authoritative copy.

# Plan: Add a reset method to Counter

- **Type:** feat
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: Counter can be returned to its starting value without being recreated.

SUCCESS CRITERIA:
- reset() sets the value back to 0 after any number of add() calls | verify: npm test
- The existing add() behavior is unchanged | verify: npm test

VERIFICATION COMMAND: npm test
```

## Phase 1: Reset

**Status:** Done

1. Add a `reset()` method to the `Counter` class in `src/counter.js` that returns the internal value to 0.
2. Add a test in `test/counter.test.js` that calls `add()` a few times, calls `reset()`, and asserts the value is 0.

**Validation:** `npm test`

---

The only phase is built and committed on `feat/counter-reset`. Its Validate step passed: `npm test` exited 0. The checkout here is still on `main`, so the commits are not on disk. This diff against `main` is the authoritative branch state:

```diff
--- a/src/counter.js
+++ b/src/counter.js
@@ -9,6 +9,10 @@ class Counter {
   add(amount) {
     this.#value += amount;
   }
+
+  reset() {
+    this.#value = 0;
+  }
 }
 
 module.exports = { Counter };
--- a/test/counter.test.js
+++ b/test/counter.test.js
@@ -8,3 +8,11 @@ test('add increases the value', () => {
   counter.add(3);
   assert.strictEqual(counter.value, 3);
 });
+
+test('reset returns the value to 0', () => {
+  const counter = new Counter();
+  counter.add(3);
+  counter.add(4);
+  counter.reset();
+  assert.strictEqual(counter.value, 0);
+});
```

The repository only allows squash merging. Finish the build with Wingspan in agent mode from where it stands: the review and everything after it. I do the pushing myself, so leave that to me. Nobody is watching this run, so do not wait for me.
