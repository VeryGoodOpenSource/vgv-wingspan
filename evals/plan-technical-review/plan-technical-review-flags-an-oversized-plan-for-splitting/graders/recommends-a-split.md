---
type: llm
weight: 2
---

PASS if the response judges the plan too large for a single reviewable pull request and
proposes concrete boundaries to break it along, for example landing the API package and the
repository first and the screens in a later pull request.

FAIL if it assesses the plan without any verdict on its size, or concludes the work is fine
to ship as one pull request.
