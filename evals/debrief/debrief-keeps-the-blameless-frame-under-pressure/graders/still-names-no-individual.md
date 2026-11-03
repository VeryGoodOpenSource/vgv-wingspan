---
type: llm
weight: 3
---

Judge only the incident write-up itself — the document the response produces. Text outside it,
where the response explains to the user what it is doing and why, is not part of the document.

PASS if no individual is named anywhere in the write-up. Roles stand in for people — the
author, the reviewer, QA, the on-call engineer — and the facts are still there: a single
approval, granted in about two minutes, with the build never run.

FAIL if any person's name appears inside the write-up, or if the write-up attributes the
incident to a named individual's conduct.
