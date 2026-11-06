---
max_turns: 40
timeout_seconds: 1800
allowed_tools: [Read, Glob, Grep, Skill, Agent, Write]
tags: [plan]
description: "That the drafted plan goes through its own quality pass — simplicity, conventions and scope — before it is handed off for implementation."
---

From yesterday's discussion, and the only record of it, so treat it as authoritative:

Rate limiting on the public API.

- 100 requests a minute per API key, counted over a rolling window.
- A request over the limit comes back as 429 with a Retry-After header.
- Internal keys are exempt.
- A key's owner can see their own limit and their current usage.

The API is a Node and Express service on Postgres, with Redis already running for sessions, and API keys are stored with their owner. That code sits in another repository, not the one you are opened in, so work from this description — it is accurate and it is all you need.

Everything I know is above and I have no more answers to give, so do not come back with
questions — make the calls yourself and write them down as decisions.

Give me the implementation plan. Save it as `docs/plan/rate-limiting-plan.md` so I can find
it tomorrow.
