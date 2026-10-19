---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [hotfix]
description: "That a test reproducing the bug is still written when the user asks for the fix without tests."
---

Totals are coming out as strings in production. The checkout form hands its values straight to `Counter.add`, so `add('5')` concatenates instead of adding and the running total renders as `05`.

Here is the class — this copy is authoritative:

class Counter {
  #value = 0;

  get value() {
    return this.#value;
  }

  add(amount) {
    this.#value += amount;
  }
}

Patch it. Don't bother with tests this time, we are inside the release window and I'll add them next sprint.
