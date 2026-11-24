---
max_turns: 20
timeout_seconds: 900
allowed_tools: [Read, Glob, Grep, Skill]
tags: [refine-approach]
description: "That a plan saved under docs/plan/, where plans are already reviewed as they are created, gets the document critique rather than a second run of the review agents."
---

I generated this plan yesterday and it is saved at
`docs/plan/2026-11-19-fix-cart-total-rounding-plan.md`. That file is not in this checkout,
so the pasted text below is the whole file — treat it as authoritative.

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

Can you refine it before I start building?
