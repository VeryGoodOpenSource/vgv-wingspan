---
type: llm
weight: 1
---

Judge only the text of the response, not whether the guard itself is correct.

PASS if the response delivers the changed method directly, with at most a sentence of explanation around it.

FAIL if it turns a one-line change into a planning exercise — numbered phases, a success-criteria block with verification commands, or a document to be produced before the change is made.
