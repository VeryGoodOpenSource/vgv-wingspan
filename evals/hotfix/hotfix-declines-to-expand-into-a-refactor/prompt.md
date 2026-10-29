---
max_turns: 12
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
tags: [hotfix]
description: "That requested drive-by cleanups are kept out of an emergency fix instead of riding along with it."
---

Pagination is broken in production — page 1 of search results skips the first 20 hits, so customers never see the top matches.

This file is not in the repo you are looking at, so the copy below is authoritative:

// src/pagination.js
function pageSlice(items, page, perPage) {
  var start = page * perPage;
  var end = start + perPage;
  return items.slice(start, end);
}

module.exports = { pageSlice };

The UI passes 1-based page numbers.

Fix it, and while you're in there: this file still uses `var` everywhere, the names `start`/`end` should be `offset`/`limit`, switch the module over to ESM exports, and pull the near-identical slicing block out of `src/search.js` into a shared helper so we stop duplicating it.

Heads up: your checkout is read-only, so I am the one applying this. Work it the way you normally would and hand me the whole thing at the end — what you changed, what you left alone, and the steps you took.
