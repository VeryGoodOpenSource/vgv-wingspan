---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [brainstorm]
description: "That a settled discussion comes back as the brainstorm document structure — decisions and open questions — under the conventional docs path."
---

We spent the morning arguing about offline mode for the mobile app and we landed somewhere. This list is the whole of it — nothing is recorded anywhere else, so treat it as the record:

- Only the last 50 orders are cached, not the full history.
- Edits made offline queue on the device and replay on reconnect; the newest write wins a conflict.
- No background sync in the first version — the user has to open the app.
- Unresolved: whether a replay that fails surfaces to the user or retries quietly.
- Unresolved: what happens when a queued edit is older than the 50-order window.

Pull together what we agreed and what is still open, so whoever picks this up next has the context.
