---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [debrief]
description: "That a one-function bug report gets the bug explained and fixed with the skill left dormant, since nothing else catches it firing where it should not."
---

Someone spotted that our order totals come out wrong whenever a discount is applied. Here is the function, and this pasted code is authoritative — it is the only place a total is computed, and it is not in any file you can open:

```js
function total(items, discountPercent) {
  let sum = 0;
  for (const item of items) {
    sum += item.price * item.quantity;
  }
  return sum - discountPercent;
}
```

With two items of 20.00 each and a 10 percent discount it returns 30.00 instead of 36.00.

What is wrong, and what should the function be?
