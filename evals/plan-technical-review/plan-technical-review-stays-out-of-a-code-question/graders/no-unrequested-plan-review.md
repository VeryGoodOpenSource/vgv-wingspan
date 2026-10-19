---
type: llm
---

PASS if the response answers what the helper evaluates to for an empty list — it returns
NaN, because zero is divided by a length of zero. It may add a one-line guard as a
suggestion.

FAIL if it does not answer that question, for example by reviewing the work as a plan,
proposing phases or pull request boundaries, or asking for a plan document to review.
