---
max_turns: 30
timeout_seconds: 1500
allowed_tools: [Read, Glob, Grep, Skill, Write]
tags: [plan]
description: "That a GitHub issue handed over to be planned routes to the skill, and the plan is offered back to the issue rather than only saved locally."
---

Can you plan GitHub issue #42 for me? I have no GitHub access to give you right now, so here
is the issue as it stands. It is the only record of what we agreed, so treat it as
authoritative:

> **#42 Let a counter be reset to a starting value**
>
> Today `Counter` in `src/counter.js` always starts at zero, and there is no way to put it
> back without creating a new one.
>
> Acceptance criteria:
>
> - `new Counter(start)` starts at `start`; with no argument it still starts at zero.
> - `reset()` puts the counter back to the value it started at.
> - A non-integer start throws a `TypeError`.
> - The existing tests still pass, and each new behavior has its own test.

I have no more answers to give, so do not come back with questions about the scope — make the
calls yourself and write them down as the decisions they are.
