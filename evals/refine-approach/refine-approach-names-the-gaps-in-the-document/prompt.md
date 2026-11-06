---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [refine-approach]
description: "That a vague approach document comes back with its gaps named — vague wording, hypothetical extras, missing constraints — instead of an approval."
---

Here is the approach doc I wrote for the next thing I'm picking up. The text below is the whole document; nothing else is written down anywhere, and there is no file on disk to open. Treat the pasted text as authoritative.

# Approach: CSV export for the admin dashboard

Admins keep asking for the order list as a spreadsheet. We should let them export it.

## How

- Add an "Export" button above the orders table.
- Clicking it calls a new endpoint that returns the orders as CSV.
- Probably stream the response so a big export does not blow up memory.
- We should also consider letting admins pick which columns they want, and maybe schedule recurring exports later on.
- Try to reuse the existing orders query.

## Open questions

(none yet)

Is this ready for me to start building?
