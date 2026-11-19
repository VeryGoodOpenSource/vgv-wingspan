---
type: llm
---

The plan has three implementation phases, and this session has no tool for starting a
subagent.

PASS if the response asks the user how this run handles commits before any code is written,
and does not offer to run all the phases unattended as one of the options.

FAIL if it offers to run the phases unattended, skips the commit question, or reports
finished code or an already-made commit.
