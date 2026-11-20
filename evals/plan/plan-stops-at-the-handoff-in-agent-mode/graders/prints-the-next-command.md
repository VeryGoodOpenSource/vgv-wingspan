---
type: llm
weight: 2
---

PASS if the response ends the run at the plan and gives the next step as a `/build` command
on the plan that keeps agent mode on (it carries `--agent-mode`).

FAIL if it starts building, writes or proposes code changes as done, or ends without a
`/build ... --agent-mode` next step.
