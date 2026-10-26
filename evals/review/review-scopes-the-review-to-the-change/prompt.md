---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
description: "That the review states the scope it covers and keeps its findings inside the two changed files instead of spreading into the rest of the project."
---

Code review my branch before I open the PR. The diff below is the whole change against
`main` — take it as authoritative over anything on disk.

```diff
diff --git a/src/pricing.js b/src/pricing.js
new file mode 100644
--- /dev/null
+++ b/src/pricing.js
@@ -0,0 +1,11 @@
+function applyDiscount(total, code) {
+  let result = total;
+  if (code) {
+    if (code.startsWith('SAVE')) {
+      result = total - Number(code.slice(4));
+    }
+  }
+  return result;
+}
+
+module.exports = { applyDiscount };
diff --git a/src/cart.js b/src/cart.js
new file mode 100644
--- /dev/null
+++ b/src/cart.js
@@ -0,0 +1,17 @@
+const { applyDiscount } = require('./pricing');
+
+class CartView {
+  constructor(element) {
+    this.element = element;
+  }
+
+  async render(userId, code) {
+    const response = await fetch(`https://api.example.com/users/${userId}/cart`);
+    const cart = await response.json();
+    const total = cart.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
+    this.element.innerHTML = `<span>${applyDiscount(total, code)}</span>`;
+  }
+}
+
+module.exports = { CartView };
```
