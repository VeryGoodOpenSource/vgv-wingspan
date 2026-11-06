---
type: llm
weight: 2
---

PASS if the response says which files it reviewed and every finding it reports is located
in `src/cart.js` or `src/pricing.js`, for example a finding that the view calls the HTTP
endpoint directly in `src/cart.js`.

FAIL if it reports findings in any other file in the project — `src/counter.js`,
`src/session.js`, `src/invoicing.js`, `src/basket.js`, `src/reports.js` and the rest are all
out of scope — or if it reviews the project as a whole without saying what it covered.
