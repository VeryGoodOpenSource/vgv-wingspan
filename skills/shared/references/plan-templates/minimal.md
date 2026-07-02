---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

## [Issue Title] - Minimal

[Brief problem/feature description]

## Success Criteria

Each criterion names the command that proves it. Use `verify: <command>` (exit 0 = pass) when a command can prove it without human judgment, or `verify: manual <steps>` when only a human can. Reject vacuous criteria like "make it work" — rewrite them as something provable.

```success-criteria
GOAL: <one sentence describing the intended end state>

SUCCESS CRITERIA:
- <observable criterion> | verify: <shell command; exit 0 = pass>
- <observable criterion> | verify: manual <numbered human steps>

NON-GOALS:
- <explicitly out of scope>

VERIFICATION COMMAND: <the non-manual verify commands above joined into one runnable command (e.g. with &&); exit 0 = all green>
```

## Context

[Any critical information]

## MVP

[add here any potential code snippets that might inform the solution]

## References

- Related issue: #[issue_number]
- Documentation: [relevant_docs_url]
