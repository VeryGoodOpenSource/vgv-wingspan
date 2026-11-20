---
type: llm
---

The plan has three implementation phases.

PASS if the response asks the user how this run handles commits before any code is written,
and running all the phases unattended is one of the options of that same question rather
than a separate question.

FAIL if it never offers to run the phases unattended, asks about it as its own question, or
reports finished code or an already-made commit.
