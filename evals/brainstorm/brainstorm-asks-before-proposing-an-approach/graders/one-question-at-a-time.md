---
type: llm
weight: 1
---

Judge only how the questions are put to the user, not whether the idea is any good.

PASS if the response puts a single question about the idea to the user before moving on. One
headline question with a few sub-points clarifying that same question passes, and so does a
housekeeping question about where to work or which codebase this belongs in alongside it.

FAIL if the user is handed several unrelated questions about the idea to answer in one go, for
example a numbered list covering who uses it, pricing, retention, analytics and rollout
together.
