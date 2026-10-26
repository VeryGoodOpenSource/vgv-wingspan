---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [hotfix]
description: "That a live crash is triaged to a root cause and fixed with the smallest change, not a broader rework."
---

The live dashboard is down. Every refunded order takes the whole reports page with it. Here is what the logs show:

TypeError: Cannot read properties of null (reading 'total')
    at /app/src/reports.js:14:28
    at Array.map (<anonymous>)
    at summarize (/app/src/reports.js:12:17)

This file is not in the repo you are looking at, so the copy below is authoritative:

// src/reports.js
function summarize(orders) {
  return orders.map((order) => ({
    id: order.id,
    total: order.payment.total,
  }));
}

module.exports = { summarize };

Refunded orders come back from the payments API with `payment: null`. Customers are staring at an error page. Get it fixed.

Heads up: your checkout is read-only, so I am the one applying this. Work it the way you normally would and hand me the whole thing at the end — what you found, the change, and the steps you took to get there.
