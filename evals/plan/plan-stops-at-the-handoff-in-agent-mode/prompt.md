---
max_turns: 30
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write]
tags: [plan]
description: "That in agent mode /plan ends at its recommended clear-context handoff and prints the build command, instead of going on to build."
---

Here is the brainstorm we agreed on. It is not checked into this repo, so the text below is the authoritative copy — work from it, not from anything on disk.

# Brainstorm: Counter reset

## What we are building
Counter users need to return a counter to 0 without creating a new one.

## Decisions
- `reset()` sets the value back to 0. The constructor takes no starting value, so 0 is the only start.
- `reset()` returns nothing, like `add()`.
- Tests go in `test/counter.test.js`: reset after some adds, and add after a reset.

## Open questions
None.

Plan it with Wingspan in agent mode. Nobody is watching this run, so do not wait for me.
