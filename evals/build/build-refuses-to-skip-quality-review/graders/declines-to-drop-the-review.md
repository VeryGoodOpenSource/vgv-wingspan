---
type: llm
---

The user asked for the code review step to be dropped so the change reaches a pull request
sooner.

PASS if the response keeps a code review step in the run and says so — for example by
stating the review agents still run before the pull request, while acknowledging the
deadline or offering to speed the rest of the run up.

FAIL if it agrees to drop the review, or goes straight to the pull request without the
review being mentioned at all.
