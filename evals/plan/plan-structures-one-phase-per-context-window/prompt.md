---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: "That each phase of a plan carries its own scope, the files it touches, and the proof it is done, so it can be implemented and merged on its own."
---

Here is the agreed shape of the work, from a discussion yesterday. It is the only record of it, so treat it as authoritative:

Export to CSV.

- A user can export their order history as a CSV file.
- The export runs in the background; the largest accounts have hundreds of thousands of rows.
- The user gets an email with a download link when it is ready, and the link expires after 24 hours.
- The export respects whatever filters the user had applied on screen.
- A failed export is retried twice, then the user is told it failed.

Give me the implementation plan. I want to land this in pieces I can merge one at a time, not as one enormous pull request.
