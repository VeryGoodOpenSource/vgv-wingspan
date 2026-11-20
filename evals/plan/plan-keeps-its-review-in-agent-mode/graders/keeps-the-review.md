---
type: llm
weight: 3
---

PASS if the response does not use the Minimal plan template and does not skip the plan
review: it uses Standard (or Extensive), or it says the plan review ran.

FAIL if it says it chose the Minimal template, or that the plan review was skipped.
