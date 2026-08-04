'use strict';

const { balance, parseAmount } = require('../src/ledger');

describe('balance', () => {
  it('returns 0 for no entries', () => {
    expect(balance([])).toBe(0);
  });

  it('sums every entry amount', () => {
    expect(balance([{ amount: 10 }, { amount: 32 }])).toBe(42);
  });
});

describe('parseAmount', () => {
  it('parses a numeric string', () => {
    expect(parseAmount('12.50')).toBe(12.5);
  });

  it('returns null for a non-numeric string', () => {
    expect(parseAmount('abc')).toBeNull();
  });
});
