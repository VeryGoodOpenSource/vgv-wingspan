---
type: llm
weight: 2
---

PASS if every sentence of the revised passage names who performed the action before the verb, for example "The platform team approved the migration on Tuesday."

FAIL if the revision keeps sentences where the action comes first and the actor trails behind a "by", for example "The migration was approved by the platform team."
