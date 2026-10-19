---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
description: "That a finished discussion hands off by offering a fresh context before planning, rather than sliding into the plan itself."
---

Here is everything we decided about the weekly digest email on a call this morning. Treat it as the final word — nothing else is written down:

- Existing subscribers only, opt in, off by default.
- One email every Monday at 08:00 in the subscriber's own timezone, listing what was added to their watchlist in the last seven days.
- A subscriber with nothing new gets no email at all.
- The approach we picked: a scheduled job reading the watchlist table we already have, rendered with the template system we already use. We rejected a separate digest service as more than this needs.
- Unsubscribing is one click and takes effect immediately.
- Done means a subscriber with activity gets exactly one email a week and a subscriber without activity gets none.

Let's close this out — does the idea hold together, and where do we go from here?
