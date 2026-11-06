---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [refine-approach]
description: "That a review tightens the author's deliberately chosen approach instead of handing back a redesign of it."
---

Refine this with me before I start building. The text below is the whole document — nothing else is written down, there is no file on disk to open, so treat the pasted text as authoritative.

# Approach: live status board for the ops team

The ops team wants a wall-mounted board showing the status of every running job.

## How

- A single page that fetches `/api/jobs` every 60 seconds and re-renders the table.
- Rows are coloured by status: running, failed, done.
- No login. The board runs on a machine inside the office network.

## Why polling and not websockets

We have about 50 concurrent viewers at peak, almost all of them this one wall display. The `/api/jobs` endpoint already exists and is already used by the admin UI, so there is nothing new to build on the server. Nobody on the team has ever run a socket server in production, and we do not want to be the first team to learn that during this project. Ops confirmed that up to a minute of staleness is fine for them — they care about spotting a failed job within a few minutes, not instantly.

## Out of scope

History, filtering, and anything that writes.
