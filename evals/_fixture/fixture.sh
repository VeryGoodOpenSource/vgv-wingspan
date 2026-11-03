#!/usr/bin/env bash
# Recreates the project skeleton in the run's empty workspace.
#
# THE ONLY COPY. Every case's fixture.sh is a symlink to this file. Edit it here.
#
# KEEP THIS NEUTRAL. Nothing here may name anything a skill teaches: no docs/brainstorm,
# docs/plan or docs/reviews directory, no pull request template, no conventional commit
# history, no review checklist. Nothing here may name the eval harness either — a workspace
# that introduces itself as a test fixture makes the model step out of the task and ask what
# the exercise is instead of doing the work.
#
# Every module a case talks about lives here, under the name that case uses, holding exactly
# the code that case pastes. A prompt that refers to a file the workspace does not have
# spends the run on the mismatch: the model goes looking, reports the file missing, and asks
# how to proceed rather than answering.
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

cat > src/pricing.js <<'JS'
function applyDiscount(total, code) {
  let result = total;
  if (code) {
    if (code.startsWith('SAVE')) {
      result = total - Number(code.slice(4));
    }
  }
  return result;
}

module.exports = { applyDiscount };
JS

cat > src/cart.js <<'JS'
const { applyDiscount } = require('./pricing');

class CartView {
  constructor(element) {
    this.element = element;
  }

  async render(userId, code) {
    const response = await fetch(`https://api.example.com/users/${userId}/cart`);
    const cart = await response.json();
    const total = cart.items.reduce((sum, i) => sum + i.price * i.quantity, 0);
    this.element.innerHTML = `<span>${applyDiscount(total, code)}</span>`;
  }
}

module.exports = { CartView };
JS

cat > src/invoicing.js <<'JS'
const DEFAULT_TAX = 0.21;

function priceOrder(order, options) {
  const taxRate = options && options.taxRate ? options.taxRate : DEFAULT_TAX;
  let subtotal = 0;
  for (const line of order.lines) {
    subtotal += line.unitPrice * line.quantity;
  }
  let discount = 0;
  if (order.customer) {
    if (order.customer.tier) {
      if (order.customer.tier === 'gold') {
        discount = subtotal * 0.1;
      }
    }
  }
  const taxed = (subtotal - discount) * (1 + taxRate);
  return Math.round(taxed * 100) / 100;
}

function priceOrderWithDefaults(order) {
  return priceOrder(order, {});
}

module.exports = { priceOrder, priceOrderWithDefaults };
JS

cat > src/basket.js <<'JS'
const https = require('node:https');

class BasketView {
  constructor(element) {
    this.element = element;
    this.items = [];
  }

  async render(userId) {
    const response = await fetch(`https://api.example.com/users/${userId}/basket`);
    const body = await response.json();
    this.items = body.items;
    let total = 0;
    for (const item of this.items) {
      if (item.price != null) {
        if (item.quantity != null) {
          total = total + item.price * item.quantity;
        }
      }
    }
    this.element.innerHTML = `<span>${formatTotal(total)}</span>`;
  }
}

function formatTotal(total) {
  return toCurrency(total);
}

function toCurrency(amount) {
  return `$${amount.toFixed(2)}`;
}

module.exports = { BasketView, formatTotal, toCurrency };
JS

cat > src/session.js <<'JS'
class BaseStore {
  constructor(key) {
    this.key = key;
  }

  read() {
    return JSON.parse(localStorage.getItem(this.key));
  }
}

class SessionStore extends BaseStore {
  constructor() {
    super('session');
  }
}

class SessionView {
  constructor(element) {
    this.element = element;
    this.store = new SessionStore();
  }

  async signIn(email, password) {
    try {
      const response = await fetch('https://api.example.com/sign-in', {
        method: 'POST',
        body: JSON.stringify({ email, password }),
      });
      const user = await response.json();
      localStorage.setItem('session', JSON.stringify(user));
      this.element.textContent = user.profile.name;
    } catch (error) {}
  }
}

module.exports = { BaseStore, SessionStore, SessionView };
JS

cat > src/reports.js <<'JS'
function summarize(orders) {
  return orders.map((order) => ({
    id: order.id,
    total: order.payment.total,
  }));
}

module.exports = { summarize };
JS

cat > src/pagination.js <<'JS'
function pageSlice(items, page, perPage) {
  var start = page * perPage;
  var end = start + perPage;
  return items.slice(start, end);
}

module.exports = { pageSlice };
JS

cat > src/search.js <<'JS'
function searchPage(hits, page, perPage) {
  var start = page * perPage;
  var end = start + perPage;
  return hits.slice(start, end);
}

module.exports = { searchPage };
JS

cat > src/auth.js <<'JS'
function isExpired(token, now) {
  return token.expiresAt <= now;
}

module.exports = { isExpired };
JS

cat > package.json <<'JSON'
{
  "name": "storefront",
  "version": "1.0.0",
  "private": true,
  "description": "Order totals, carts and reporting for the storefront.",
  "main": "src/counter.js",
  "scripts": {
    "test": "node --test"
  }
}
JSON
