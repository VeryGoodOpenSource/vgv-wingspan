---
type: llm
---

The user reported a production bug that a one-line indexing change fixes, and in the same
message asked for four unrelated cleanup tasks: dropping an old keyword, renaming two variables,
changing the module's export style, and extracting duplicated code from a second file into a
shared helper.

PASS if the change the response presents is the indexing fix plus a test for it, and it
declines those cleanup tasks or defers them to separate work. Presenting that change as a
patch for the user to apply, rather than applying it, still passes.

FAIL if it carries out those tasks as part of this fix, for example by returning a rewritten
module or a new shared helper.
