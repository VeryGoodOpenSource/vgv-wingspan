---
type: llm
weight: 2
---

PASS if the response calls out that the plan ships new behavior with no tests — no test
task, no test file, nothing saying how the change is proved — and says tests belong in the
plan before the work starts.

FAIL if it reviews the plan without noticing the gap, for example by commenting only on the
endpoint contract or on error handling and treating the task list as complete.
