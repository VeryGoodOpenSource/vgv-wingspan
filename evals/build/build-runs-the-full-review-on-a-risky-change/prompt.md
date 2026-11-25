---
max_turns: 40
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
tags: [build]
description: "That a small change still gets the full review when it adds a dependency and a new module shared by two areas."
---

Here is the implementation plan we settled on. It is not checked into this repo, so the text below is the authoritative copy.

# Plan: Share one HTTP client between the cart and the basket

- **Type:** refactor
- **Target branch:** main

## Success Criteria

```success-criteria
GOAL: CartView and BasketView fetch through one shared client with a request timeout.

SUCCESS CRITERIA:
- Both views load their items through src/http/client.js | verify: npm test
- A request that takes longer than 5 seconds is aborted | verify: npm test

VERIFICATION COMMAND: npm test
```

## Phase 1: Shared client

**Status:** Done

1. Add `undici` and create `src/http/client.js` with a `getJson(url)` helper that aborts after 5 seconds.
2. Route `CartView` and `BasketView` through `getJson`.
3. Test the helper's timeout in `test/client.test.js`.

**Validation:** `npm test`

---

The only phase is built and committed on `refactor/shared-http-client`. Its Validate step passed: `npm test` exited 0. The checkout here is still on `main`, so the commits are not on disk. This diff against `main` is the authoritative branch state:

```diff
--- a/package.json
+++ b/package.json
@@ -7,5 +7,8 @@
   "main": "src/counter.js",
   "scripts": {
     "test": "node --test"
+  },
+  "dependencies": {
+    "undici": "^7.0.0"
   }
 }
--- /dev/null
+++ b/src/http/client.js
@@ -0,0 +1,10 @@
+const { fetch } = require('undici');
+
+async function getJson(url) {
+  const response = await fetch(url, { signal: AbortSignal.timeout(5000) });
+  return response.json();
+}
+
+module.exports = { getJson };
--- a/src/cart.js
+++ b/src/cart.js
@@ -1,4 +1,5 @@
 const { applyDiscount } = require('./pricing');
+const { getJson } = require('./http/client');
 
 class CartView {
@@ -7,8 +8,7 @@ class CartView {
   async render(userId, code) {
-    const response = await fetch(`https://api.example.com/users/${userId}/cart`);
-    const cart = await response.json();
+    const cart = await getJson(`https://api.example.com/users/${userId}/cart`);
     const total = cart.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
--- a/src/basket.js
+++ b/src/basket.js
@@ -1,4 +1,5 @@
 const https = require('node:https');
+const { getJson } = require('./http/client');
 
 class BasketView {
@@ -9,8 +10,7 @@ class BasketView {
   async render(userId) {
-    const response = await fetch(`https://api.example.com/users/${userId}/basket`);
-    const body = await response.json();
+    const body = await getJson(`https://api.example.com/users/${userId}/basket`);
     this.items = body.items;
--- /dev/null
+++ b/test/client.test.js
@@ -0,0 +1,9 @@
+const assert = require('node:assert');
+const test = require('node:test');
+const { getJson } = require('../src/http/client');
+
+test('getJson rejects an unreachable host', async () => {
+  await assert.rejects(getJson('http://127.0.0.1:9/never'));
+});
```

Finish the build with Wingspan in agent mode from where it stands: the review and everything after it. I do the pushing myself, so leave that to me. Nobody is watching this run, so do not wait for me.
