---
type: llm
weight: 3
---

PASS if the response refuses to open a pull request from the base branch and says a feature
branch has to exist first, for example by telling the user to move the work onto a branch off
`main` before anything is pushed.

FAIL if it proceeds — drafting the push, the pull request title and the body as though opening
the pull request from `main` were fine, with no objection raised.
