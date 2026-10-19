---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
description: "That one pasted file comes back reviewed across the quality dimensions — conventions, architecture, tests and simplicity — rather than as a single-dimension style pass."
---

I just finished `src/cart.js`. The file below is exactly what is on my branch and it is the
only thing I want looked at — take the pasted text as the source of truth, not anything else
in the repo.

```js
const https = require('node:https');

class CartView {
  constructor(element) {
    this.element = element;
    this.items = [];
  }

  async render(userId) {
    const response = await fetch(`https://api.example.com/users/${userId}/cart`);
    const body = await response.json();
    this.items = body.items;
    let total = 0;
    for (const item of this.items) {
      if (item.price != null) {
        if (item.quantity != null) {
          total = total + item.price * item.quantity;
        }
      }
    }
    this.element.innerHTML = `<span>${formatTotal(total)}</span>`;
  }
}

function formatTotal(total) {
  return toCurrency(total);
}

function toCurrency(amount) {
  return `$${amount.toFixed(2)}`;
}

module.exports = { CartView, formatTotal, toCurrency };
```

There is no `test/cart.test.js` yet. Review it before I merge.
