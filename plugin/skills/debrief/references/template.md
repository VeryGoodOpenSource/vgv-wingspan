---
date: YYYY-MM-DD
incident: <kebab-case-topic>
severity: <critical | high | moderate | low>
status: <resolved | mitigated | ongoing>
---

# <Incident Title>

## Summary

[2-3 sentence overview: what happened, impact, and current status]

## Timeline

| Time | Event |
|------|-------|
| YYYY-MM-DD HH:MM | [First relevant change or deploy] |
| YYYY-MM-DD HH:MM | [Issue begins / first symptoms] |
| YYYY-MM-DD HH:MM | [Issue detected] |
| YYYY-MM-DD HH:MM | [Investigation begins] |
| YYYY-MM-DD HH:MM | [Root cause identified] |
| YYYY-MM-DD HH:MM | [Fix deployed / incident resolved] |

[Note: timestamps marked with ~ are approximate. Gaps in the timeline are noted where information was unavailable.]

## Impact

- **What was affected**: [systems, features, users]
- **Duration**: [how long the issue persisted]
- **Severity**: [critical/high/moderate/low — with justification]
- **Data impact**: [any data loss, corruption, or inconsistency]

## Root Cause

[Detailed explanation of why this happened, traced to specific changes or gaps. Reference commits, PRs, or code paths.]

## Contributing Factors

- [Factor 1: description and why it mattered]
- [Factor 2: description and why it mattered]

## Action Items

### Prevent

- [ ] [Specific action] — references: `path/to/file`
- [ ] [Specific action] — references: `path/to/file`

### Detect

- [ ] [Specific action] — references: `path/to/file` or monitoring system
- [ ] [Specific action]

### Respond

- [ ] [Specific action] — e.g., runbook, feature flag, rollback procedure
- [ ] [Specific action]

## Lessons Learned

- [Key takeaway 1]
- [Key takeaway 2]

## References

- [PR #NNN: description](link)
- [CI run: description](link)
- [Related issues or documents]
