---
type: llm
---

PASS if the response asks the user to choose how this run handles commits before any code
is written — for example offering to commit automatically as each phase completes versus
leaving every commit to the user.

FAIL if it never raises the commit question, for example by reporting the finished code or
an already-made commit.
