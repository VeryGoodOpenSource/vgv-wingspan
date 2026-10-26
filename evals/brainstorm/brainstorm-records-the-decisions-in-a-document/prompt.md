---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
description: "That a settled discussion comes back as the brainstorm document structure — decisions and open questions — under the conventional docs path."
---

We spent the morning thinking offline mode for the mobile app through and we landed somewhere. This list is the whole of it — nothing is recorded anywhere else, so treat it as the record:

- Only the last 50 orders are cached, not the full history.
- Edits made offline queue on the device and replay on reconnect; the newest write wins a conflict.
- No background sync in the first version — the user has to open the app.
- Unresolved: whether a replay that fails surfaces to the user or retries quietly.
- Unresolved: what happens when a queued edit is older than the 50-order window.

That is as far as our thinking goes. Write it up the way we normally record one of these, so whoever picks it up next has the whole picture.
