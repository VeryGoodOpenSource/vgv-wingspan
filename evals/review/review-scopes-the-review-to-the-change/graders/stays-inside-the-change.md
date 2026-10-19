---
type: llm
weight: 2
---

PASS if the response says which files it reviewed and every finding it reports is located
in `src/cart.js` or `src/pricing.js`, for example a finding that the view calls the HTTP
endpoint directly in `src/cart.js`.

FAIL if it reports findings in files outside those two, for example a finding about
`src/counter.js` or `test/counter.test.js`, or if it reviews the project as a whole without
saying what it covered.
