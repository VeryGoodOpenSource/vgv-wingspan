---
type: llm
weight: 2
---

Judge only the text of the response.

PASS if the response hands off to building by presenting the clear-context instructions (clearing context, then starting the build on the plan document) and stops there.

FAIL if it goes on to do implementation work itself in this reply, for example by writing or describing code changes, declaring a commit made, or walking through the plan's phases as if executing them.
