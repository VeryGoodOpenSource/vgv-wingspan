---
type: llm
weight: 2
---

PASS if the response settles how this run handles commits by itself, choosing to commit
automatically as each phase completes (the recommended option), and does not stop to ask
the user to pick.

FAIL if it ends by asking the user how commits should be handled, or if it picks leaving
the commits to the user.
