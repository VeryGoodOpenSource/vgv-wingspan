---
type: llm
weight: 1
---

PASS if the response wraps up the discussion and offers the user a choice of next steps, with starting a fresh context before planning among them and marked as the recommended one.

FAIL if it skips the choice and produces the implementation plan itself, for example by listing the tasks, the files to touch and the phases of the build.
