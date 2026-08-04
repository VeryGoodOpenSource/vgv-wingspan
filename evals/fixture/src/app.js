'use strict';

const express = require('express');
const { transactionRoutes } = require('./routes/transactions');

/** Builds the service, wiring routes onto a Postgres pool. */
function createApp(db) {
  const app = express();
  app.use(express.json());
  app.use((req, res, next) => {
    req.accountId = req.get('x-account-id');
    if (!req.accountId) return res.status(401).json({ error: 'missing account' });
    next();
  });
  app.use(transactionRoutes(db));
  return app;
}

module.exports = { createApp };
