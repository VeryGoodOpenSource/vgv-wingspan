---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [review]
description: "That a one-method addition leaves the skill dormant, since nothing else catches a review firing where no review was asked for."
---

Add a `subtract(amount)` method to this class that lowers the running total. The class below
is authoritative. Return only the new method, nothing else.

```js
class Counter {
  #value = 0;

  get value() {
    return this.#value;
  }

  add(amount) {
    this.#value += amount;
  }
}
```
