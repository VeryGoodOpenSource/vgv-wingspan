---
max_turns: 40
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
tags: [build]
description: "That a change with no risk signal still gets the full review once it touches more than five files."
---

Here is the implementation plan we settled on. It is not checked into this repo, so the text below is the authoritative copy.

# Plan: Tidy the paging helpers and guard Counter.add

- **Type:** refactor
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: The paging helpers use const, and Counter.add rejects amounts that are not numbers.

SUCCESS CRITERIA:
- pageSlice and searchPage return the same slices as before | verify: npm test
- Counter.add throws a TypeError for a non-finite amount | verify: npm test

VERIFICATION COMMAND: npm test
```

## Phase 1: Tidy and guard

**Status:** Done

1. Replace `var` with `const` in `src/pagination.js` and `src/search.js`.
2. Make `Counter.add` in `src/counter.js` throw a `TypeError` when `amount` is not a finite number.
3. Add `test/pagination.test.js` and `test/search.test.js`, and a test for the guard in `test/counter.test.js`.

**Validation:** `npm test`

---

The only phase is built and committed on `refactor/tidy-paging`. Its Validate step passed: `npm test` exited 0. The checkout here is still on `main`, so the commits are not on disk. This diff against `main` is the authoritative branch state:

```diff
--- a/src/pagination.js
+++ b/src/pagination.js
@@ -1,6 +1,6 @@
 function pageSlice(items, page, perPage) {
-  var start = page * perPage;
-  var end = start + perPage;
+  const start = page * perPage;
+  const end = start + perPage;
   return items.slice(start, end);
 }
--- a/src/search.js
+++ b/src/search.js
@@ -1,6 +1,6 @@
 function searchPage(hits, page, perPage) {
-  var start = page * perPage;
-  var end = start + perPage;
+  const start = page * perPage;
+  const end = start + perPage;
   return hits.slice(start, end);
 }
--- a/src/counter.js
+++ b/src/counter.js
@@ -7,6 +7,9 @@ class Counter {
   }
 
   add(amount) {
+    if (!Number.isFinite(amount)) {
+      throw new TypeError('amount must be a finite number');
+    }
     this.#value += amount;
   }
 }
--- a/test/counter.test.js
+++ b/test/counter.test.js
@@ -8,3 +8,8 @@ test('add increases the value', () => {
   counter.add(3);
   assert.strictEqual(counter.value, 3);
 });
+
+test('add rejects a non-number', () => {
+  const counter = new Counter();
+  assert.throws(() => counter.add('3'), TypeError);
+});
--- /dev/null
+++ b/test/pagination.test.js
@@ -0,0 +1,7 @@
+const assert = require('node:assert');
+const test = require('node:test');
+const { pageSlice } = require('../src/pagination');
+
+test('pageSlice returns the second page', () => {
+  assert.deepStrictEqual(pageSlice([1, 2, 3, 4, 5], 1, 2), [3, 4]);
+});
--- /dev/null
+++ b/test/search.test.js
@@ -0,0 +1,7 @@
+const assert = require('node:assert');
+const test = require('node:test');
+const { searchPage } = require('../src/search');
+
+test('searchPage returns the first page', () => {
+  assert.deepStrictEqual(searchPage(['a', 'b', 'c'], 0, 2), ['a', 'b']);
+});
```

Finish the build with Wingspan in agent mode from where it stands: the review and everything after it. I do the pushing myself, so leave that to me. Nobody is watching this run, so do not wait for me.
