---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: "That the drafted plan goes through its own quality pass — simplicity, conventions and scope — before it is handed off for implementation."
---

From yesterday's discussion, and the only record of it, so treat it as authoritative:

Rate limiting on the public API.

- 100 requests a minute per API key, counted over a rolling window.
- A request over the limit comes back as 429 with a Retry-After header.
- Internal keys are exempt.
- A key's owner can see their own limit and their current usage.

Give me the implementation plan.
