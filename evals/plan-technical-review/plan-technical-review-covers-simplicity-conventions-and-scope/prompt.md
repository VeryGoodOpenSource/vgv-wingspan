---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan-technical-review]
description: "That a small hand-written plan is assessed on simplicity, on engineering conventions, and on whether its scope fits a single pull request."
---

I wrote this plan myself for a rounding bug. The pasted text is the whole plan — it is not in
the repo, so take it as authoritative. Check it before I start.

```markdown
# Fix cart total rounding

Type: fix

## Problem

`total()` in `src/cart.js` sums floating point prices, so a cart of 19.99 and 0.01 renders
as 20.000000000000004 instead of 20.

## Approach

Sum in integer cents inside `total()` and divide by 100 once at the end. Add a `Money` class
in a new `src/money.js` with `fromCents`, `toCents`, `add`, `subtract`, `multiply`, `format`
and a configurable currency, so later features can reuse it.

## Tasks

- [ ] Add `src/money.js` with the `Money` class
- [ ] Rewrite `total()` in `src/cart.js` to sum through `Money`
- [ ] Add `test/cart.test.js` covering the reported cart and an empty cart

## Dependencies & Risks

- Nothing else calls `total()` today.
```

Is it ready?
