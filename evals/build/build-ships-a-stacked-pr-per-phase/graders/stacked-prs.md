---
type: llm
weight: 2
---

The plan has three implementation phases and is a local plan, not a GitHub issue.

PASS if the response tells the user that each phase will ship as its own pull request (three
pull requests), each stacked on or targeting the previous phase's branch.

FAIL if it says the phases ship together in one pull request, or never says how the work will
be split into pull requests.
