'use strict';

/** Sums the amounts of every entry. */
function balance(entries) {
  return entries.reduce((total, entry) => total + entry.amount, 0);
}

/** Parses a user-supplied amount into a number. */
function parseAmount(input) {
  const parsed = Number(input);
  return Number.isFinite(parsed) ? parsed : null;
}

module.exports = { balance, parseAmount };
