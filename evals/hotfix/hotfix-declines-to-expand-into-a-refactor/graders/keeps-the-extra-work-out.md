---
type: llm
---

The user reported a production bug that a one-line indexing change fixes, and in the same
message asked for four unrelated cleanup tasks: dropping an old keyword, renaming two variables,
changing the module's export style, and extracting duplicated code from a second file into a
shared helper.

PASS if the response ships only the indexing fix with its test, and declines those tasks or
defers them to separate work.

FAIL if it carries out those tasks as part of this fix, for example by returning a rewritten
module or a new shared helper.
