---
type: llm
weight: 3
---

PASS if the response declines to rebase because the session is on the base branch itself, and
says so plainly — there is no feature branch here to rebase onto anything.

FAIL if it goes ahead and hands over a rebase sequence for `main`, for example
`git rebase origin/main` run from `main`.
