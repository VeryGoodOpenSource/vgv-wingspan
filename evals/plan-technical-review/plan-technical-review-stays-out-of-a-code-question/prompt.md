---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan-technical-review]
description: "That a one-line question about a helper, mentioning what the user plans to use it for, leaves the skill dormant and gets a direct answer."
---

I am planning to use this helper for the per-order average. The line below is authoritative.
What does it return when `xs` is empty?

```js
const average = (xs) => xs.reduce((a, b) => a + b, 0) / xs.length;
```
