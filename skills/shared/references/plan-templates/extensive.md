---
title: [Issue Title]
type: [feat|fix|refactor]
date: YYYY-MM-DD
---

## [Issue title] - Extensive

## Overview

[Executive summary]

## Problem Statement

[Detailed problem analysis]

## Proposed Solution

[Comprehensive solution design]

## Technical Approach

### Architecture

[Detailed technical design]

### Implementation Phases

#### Phase 1: [Foundation]

- Tasks and deliverables
- Phase exit condition
- Estimated effort

#### Phase 2: [Core Implementation]

- Tasks and deliverables
- Phase exit condition
- Estimated effort

#### Phase 3: [Polish & Optimization]

- Tasks and deliverables
- Phase exit condition
- Estimated effort

## Alternative Approaches Considered

[Other solutions evaluated and why rejected]

## Success Criteria

Each criterion names the command that proves it. Use `verify: <command>` (exit 0 = pass) when a command can prove it without human judgment, or `verify: manual <steps>` when only a human can. Reject vacuous criteria like "make it work" — rewrite them as something provable. Fold functional, non-functional, and quality-gate requirements into concrete criteria below.

```success-criteria
GOAL: <one sentence describing the intended end state>

SUCCESS CRITERIA:
- <functional criterion> | verify: <shell command; exit 0 = pass>
- <non-functional criterion, e.g. performance/security/accessibility> | verify: <shell command>
- <quality gate, e.g. coverage threshold> | verify: <shell command>
- <criterion only a human can check> | verify: manual <numbered human steps>

NON-GOALS:
- <explicitly out of scope>

VERIFICATION COMMAND: <the non-manual verify commands above joined into one runnable command (e.g. with &&); exit 0 = all green>
```

## Success Metrics

[Detailed KPIs and measurement methods]

## Dependencies & Prerequisites

[Detailed dependency analysis]

## Risk Analysis & Mitigation

[Comprehensive risk assessment]

## Resource Requirements

[Team, time, infrastructure needs]

## Future Considerations

[Extensibility and long-term vision]

## Documentation Plan

[What docs need updating]

## References & Research

### Internal References

- Architecture decisions: [file_path:line_number]
- Similar features: [file_path:line_number]
- Configuration: [file_path:line_number]

### External References

- Framework documentation: [url]
- Best practices guide: [url]
- Industry standards: [url]

### Related Work

- Previous PRs: #[pr_numbers]
- Related issues: #[issue_numbers]
- Design documents: [links]
