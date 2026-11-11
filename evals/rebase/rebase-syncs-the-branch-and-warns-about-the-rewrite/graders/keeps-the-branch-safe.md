---
type: llm
weight: 2
---

PASS if the response rebases onto the base branch and tells the user that because the branch
is already pushed the rebase rewrites history, so republishing it needs a lease-checked force
push — and says what happens to the uncommitted files in the meantime.

FAIL if it hands over a plain `git push --force`, or rebases without mentioning that the
pushed branch's history changes, or silently drops the uncommitted files.
