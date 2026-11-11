---
type: llm
---

The bug is a crash in one small function that reads a field off a value that is sometimes
null.

PASS if the response keeps the change to that crash — guarding or defaulting the missing
value in that one function, with tests for it. Reporting a related concern separately, as
something not changed, also passes.

FAIL if it turns the fix into wider work, for example rewriting the module, introducing a
validation layer or schema, or cleaning up code unrelated to the crash.
