---
type: llm
weight: 2
---

Judge only the text of the response.

PASS if the response hands off to planning by presenting the clear-context instructions (clearing context, then starting the next phase on the brainstorm document) and stops there — for example a short block telling the user to run a clear-context command and then start planning on the document.

FAIL if it goes on to do the planning itself in this reply, for example by listing implementation tasks, phases, file paths to touch, or success criteria for the feature.
