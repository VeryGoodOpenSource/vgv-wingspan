---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [plan]
description: "That a one-line guard in a single method leaves the skill dormant, since nothing else catches it firing where it should not."
---

The `add` method in `src/counter.js` takes a negative amount without complaining:

add(amount) {
  this.#value += amount;
}

Make it throw when the amount is negative. Give me the updated method and nothing else.
