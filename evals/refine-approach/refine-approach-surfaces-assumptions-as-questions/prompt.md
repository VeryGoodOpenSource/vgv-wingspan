---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [refine-approach]
description: "That what the approach silently takes for granted comes back as open questions for the author rather than being quietly decided."
---

Review my approach before I turn it into a plan. The text below is the whole document — nothing else is written down, there is no file on disk to open, so treat the pasted text as authoritative.

# Approach: offline support for the field app

Technicians lose signal in basements and the app is useless down there. It should keep working offline.

## How

- Cache the technician's job list on the device when the app starts.
- Let them fill in job reports while offline. Queue each finished report locally.
- When connectivity comes back, send the queued reports to the API in the background.
- The API already accepts the report payload, so nothing changes on the server side.
- Show a small banner while the app is offline.

## Scope

Phase one is the field app on Android only. Jobs are read-only offline; reports are the only thing written.
