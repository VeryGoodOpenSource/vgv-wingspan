---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [create-pr]
description: "That a pull request asked for from the base branch is refused rather than opened from main."
---

/create-pr

I am on `main` with uncommitted edits to `src/basket.js`. Open the pull request for me.

I have no shell in this session, so do not try to run anything — tell me what you would do and
I will run it myself.
