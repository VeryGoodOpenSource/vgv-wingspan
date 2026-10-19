---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [debrief]
description: "That the underlying change is named as the cause while the visible symptom and the workaround that hid it are kept separate."
---

Write up Monday's home-feed incident for me. The notes below are the complete record — treat them as authoritative, there is nothing else available to read and no logs or CI runs you can reach.

- Monday 08:00 — users start reporting a blank home feed with a spinner that never stops. Support logged about 40 reports.
- Monday 14:00 — we shipped a client build that adds a null check around the feed response, so the screen now shows "No items yet" instead of spinning forever. The reports stopped.
- Monday 18:00 — while looking at something else, we found the actual trigger. The previous Thursday, backend PR #88 changed the feed response so an empty list is omitted from the payload entirely instead of being sent as `[]`. The client has always assumed the field is present.
- There is no contract test between the client and the feed API, and the client has no schema validation on that response.
- The client change we shipped Monday only hides the spinner. Users whose feed should have items but hit the same path still see an empty screen.
- The backend change to always send the field is written but not released. Nothing is scheduled yet.
- Nobody was paged. We found out from support tickets.
