---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [create]
description: "That adding one new module to a project already on disk leaves the project-creation skill dormant."
---

This is the authoritative copy of src/counter.js in the project I am working in:

// Keeps a running total.
class Counter {
  #value = 0;

  get value() {
    return this.#value;
  }

  add(amount) {
    this.#value += amount;
  }
}

module.exports = { Counter };

I want to pull reset logic into its own module next to it. Tell me the path and filename that new module should get, and nothing else.
