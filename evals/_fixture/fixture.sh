#!/usr/bin/env bash
# Recreates the neutral project skeleton in the run's empty workspace.
#
# THE ONLY COPY. Every case's fixture.sh is a symlink to this file. Edit it here.
#
# KEEP THIS NEUTRAL. Nothing here may name anything a skill teaches: no docs/brainstorm,
# docs/plan or docs/reviews directory, no pull request template, no conventional commit
# history, no review checklist. The source exists so a run opens in a real project rather
# than an empty directory, nothing more.
set -euo pipefail
mkdir -p src test
cat > src/counter.js <<'JS'
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
JS
cat > test/counter.test.js <<'JS'
const assert = require('node:assert');
const test = require('node:test');
const { Counter } = require('../src/counter');

test('add increases the value', () => {
  const counter = new Counter();
  counter.add(3);
  assert.strictEqual(counter.value, 3);
});
JS
cat > package.json <<'JSON'
{
  "name": "eval-fixture-app",
  "version": "1.0.0",
  "private": true,
  "description": "Scratch project used as working-directory context for behavior evals.",
  "main": "src/counter.js",
  "scripts": {
    "test": "node --test"
  }
}
JSON
