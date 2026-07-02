---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

## [Issue Title] - Standard

## Overview

[Comprehensive description]

## Problem Statement / Motivation

[Why this matters]

## Proposed Solution

[High-level approach]

## Technical Considerations

- Architecture impacts
- Performance implications
- Security considerations

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

## Success Metrics

[How we measure success]

## Dependencies & Risks

[What could block or complicate this]

## References & Research

- Similar implementations: [file_path:line_number]
- Best practices: [documentation_url]
- Related PRs: #[pr_number]
