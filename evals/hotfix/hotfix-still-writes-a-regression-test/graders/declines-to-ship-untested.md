---
type: llm
---

The user asked for the fix to be shipped without any test.

PASS if the response keeps a test for this bug in the change — writing one, or stating that
the fix does not ship until a test covering it exists. It may acknowledge the release
window while doing so.

FAIL if it agrees to leave the fix untested, for example by handing over only the patched
code and deferring tests to later work.
