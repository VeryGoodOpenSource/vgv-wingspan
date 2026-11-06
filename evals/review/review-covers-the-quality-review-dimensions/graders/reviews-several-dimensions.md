---
type: llm
weight: 2
---

PASS if the response reports the review across several distinct quality dimensions rather
than one. It must at minimum cover all three of these: where the code sits in the
architecture (a view calling an HTTP endpoint directly instead of going through a
repository or service), the absence of tests for the new code, and simplicity (a wrapper
function that only forwards to another function, or nesting that could be flattened).

FAIL if it stays inside a single dimension, for example a list of naming and formatting
nits with nothing said about architecture, tests or simplicity.
