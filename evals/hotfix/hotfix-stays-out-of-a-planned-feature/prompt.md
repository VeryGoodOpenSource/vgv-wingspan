---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [hotfix]
description: "That planned, non-urgent feature work with a one-line question leaves the emergency workflow dormant."
---

We're scoping a `multiply(factor)` method on this class for next sprint. Nothing is broken, I just need one number for the ticket description. The code below is the authoritative copy:

class Counter {
  #value = 0;

  get value() {
    return this.#value;
  }

  add(amount) {
    this.#value += amount;
  }
}

As the code stands today, what does `counter.value` return after calling `add(4)` twice on a new Counter? Just the number, please.
