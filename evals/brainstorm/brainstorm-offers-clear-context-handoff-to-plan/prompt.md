---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
description: "That a finished discussion hands off by offering a fresh context before planning, rather than sliding into the plan itself."
---

I want to think the weekly digest email through with you before anything gets built. We talked it over on a call this morning and this is where we got to — nothing else is written down, so this is the whole of it:

- Existing subscribers only, opt in, off by default.
- One email every Monday at 08:00 in the subscriber's own timezone, listing what was added to their watchlist in the last seven days.
- A subscriber with nothing new gets no email at all.
- The approach we picked: a scheduled job reading the watchlist table we already have, rendered with the template system we already use. We rejected a separate digest service as more than this needs.
- Unsubscribing is one click and takes effect immediately.
- Done means a subscriber with activity gets exactly one email a week and a subscriber without activity gets none.

That is as far as our thinking goes, and we are happy with it. Take it from here and tell me what my next move is.
