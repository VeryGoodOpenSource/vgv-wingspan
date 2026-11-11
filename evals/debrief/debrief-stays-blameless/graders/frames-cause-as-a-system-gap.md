---
type: llm
weight: 2
---

Judge only the text of the response.

PASS if the response explains the incident through systems and process — for example a startup
path that throws when the config file is absent, a test matrix that never covers a fresh
install, or a review step that does not require running the build. Naming a role rather than a
person still passes, and so does recording a role-level gap as a contributing factor, for
example "the review did not include running the build".

FAIL if the response names an individual, or assigns the cause to a person's character or
effort rather than to the process around them — "the author rushed it through", "the reviewer
was careless", "this happened because someone did not do their job".
