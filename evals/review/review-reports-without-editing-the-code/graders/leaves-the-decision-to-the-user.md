---
type: llm
weight: 2
---

PASS if the response reports what the review found and then leaves the next move to the
user, for example by offering to fix only the critical findings, to fix specific findings
the user names, or to leave the report as it is. Naming the fix for each finding is part of
reporting and does not count as acting on it.

FAIL if the answer is a rewritten version of the file handed back as done, with no findings
reported and no choice offered, for example a corrected code block introduced as the
cleaned-up file.
