---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
description: "That the review stops at reported findings and lets the user choose what to act on, instead of handing back a rewritten file."
---

Here is `src/pricing.js` as it stands on my branch. The pasted text is the whole file and the
whole change; there is no `test/pricing.test.js`.

```js
const DEFAULT_TAX = 0.21;

function priceOrder(order, options) {
  const taxRate = options && options.taxRate ? options.taxRate : DEFAULT_TAX;
  let subtotal = 0;
  for (const line of order.lines) {
    subtotal += line.unitPrice * line.quantity;
  }
  let discount = 0;
  if (order.customer) {
    if (order.customer.tier) {
      if (order.customer.tier === 'gold') {
        discount = subtotal * 0.1;
      }
    }
  }
  const taxed = (subtotal - discount) * (1 + taxRate);
  return Math.round(taxed * 100) / 100;
}

function priceOrderWithDefaults(order) {
  return priceOrder(order, {});
}

module.exports = { priceOrder, priceOrderWithDefaults };
```

Review it before I merge.
