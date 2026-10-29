---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [build]
description: "That a one-line comprehension question about existing code leaves the skill dormant and gets a plain answer."
---

Quick sanity check before I write a ticket against this class. The code below is the authoritative copy:

class Counter {
  #value = 0;

  get value() {
    return this.#value;
  }

  add(amount) {
    this.#value += amount;
  }
}

With this code, what does `counter.value` return after calling `add(2)` and then `add(5)` on a brand new Counter? Give me just the number.
