---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [create-pr]
description: "That a finished branch comes back as a conventional-commit title and a filled-in pull request body."
---

/create-pr VGV-318

I am on `feat/basket-totals`, three commits ahead of `main`, working tree clean. There is no
pull request template in this repo. `git log main..HEAD --oneline` gives:

```text
9f2a1c4 add BasketView and render the running total
3d81b70 format the total as currency
c05e9ab cover the empty-basket case with a test
```

The checkout is on my other machine and I have no shell in this session, so do not try to run
anything — write out the commit message, the title and the body and I will run the commands
myself.
