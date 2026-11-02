---
type: llm
weight: 3
---

Judge only the text of the response.

PASS if the response acts on (fixes, or describes fixing) only FINDING-02 and FINDING-04, and either leaves FINDING-01 and FINDING-03 unaddressed or explicitly notes that they are being left for later as the user asked — for example "FINDING-01 and FINDING-03 are left as-is for now."

FAIL if the response fixes or changes all four findings, fixes a different pair than FINDING-02 and FINDING-04, or ignores the user's selection and re-asks which findings to act on instead of proceeding.
