---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan-technical-review]
description: "That a plan shipping new behavior with no tests and no way to verify it is flagged for the gap before the work starts."
---

Is this plan ready? I am about to hand it to someone else to implement. The pasted text is
the whole plan, and it targets our checkout app, which is not checked out in this directory
— so judge the plan as written rather than against what happens to be on disk here.

```markdown
# Add promo codes to checkout

Type: feat

## Overview

Shoppers enter a promo code at checkout and see the discounted total before they pay.

## Proposed Solution

Add `src/promo.js` exporting `validateCode(code)` and `applyPromo(total, code)`.
`validateCode` calls `GET /promos/:code` and returns the percentage off. The cart view calls
`applyPromo` when the promo field loses focus and re-renders the total.

## Technical Considerations

- Codes are case-insensitive; uppercase before sending.
- A failed lookup leaves the total unchanged and shows an inline message.
- The discount applies before tax.

## Tasks

- [ ] Add `src/promo.js` with `validateCode` and `applyPromo`
- [ ] Wire the promo field into `src/cart.js` and re-render on blur
- [ ] Handle the 404 and timeout paths

## Dependencies & Risks

- The promo endpoint ships next week; point at staging until then.
```

Does it hold up?
