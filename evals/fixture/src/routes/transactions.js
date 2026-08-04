'use strict';

const express = require('express');
const { balance, parseAmount } = require('../ledger');

/** Routes for reading and recording transactions. */
function transactionRoutes(db) {
  const router = express.Router();

  router.get('/transactions', async (req, res) => {
    const { rows } = await db.query('SELECT * FROM transactions WHERE account_id = $1', [
      req.accountId,
    ]);
    res.json(rows);
  });

  router.get('/balance', async (req, res) => {
    const { rows } = await db.query('SELECT amount FROM transactions WHERE account_id = $1', [
      req.accountId,
    ]);
    res.json({ balance: balance(rows) });
  });

  router.post('/transactions', async (req, res) => {
    const amount = parseAmount(req.body.amount);
    if (amount === null) return res.status(400).json({ error: 'amount must be a number' });
    await db.query('INSERT INTO transactions (account_id, amount) VALUES ($1, $2)', [
      req.accountId,
      amount,
    ]);
    res.status(201).json({ amount });
  });

  return router;
}

module.exports = { transactionRoutes };
