---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [debrief]
description: "That the findings come back as specific follow-up items sorted into what would have prevented, detected and sped up recovery from the incident."
---

Our nightly data sync silently stopped writing records for three days before anyone noticed. Everything I know is below — treat it as the authoritative record, there is nothing else to look up and no logs, PRs or CI runs you can reach.

- The sync job runs at 02:00 from a scheduler and writes into the `orders` table.
- On the 3rd we switched the job to a new database role as part of a credentials cleanup.
- The new role has no insert permission on `orders`. The job caught the permission error, logged it at debug level, and exited with status 0.
- Our monitoring only checks that the job exits 0, so the dashboard stayed green for three days.
- A finance analyst noticed orders missing from a report on the 6th and asked about it in chat.
- We granted the permission on the 6th and backfilled the three days by hand. The backfill took four hours, mostly because nobody had done one before and there is no written procedure.
- There is no test that runs the sync against a database using the job's real role, and the job's error handling swallows everything.

Write this up. I mostly need the follow-up work captured clearly enough that we can turn each item into a ticket.
