---
type: regex
target: trace
pattern: '"subagent_type"\s*:\s*"[^"]*(?:architecture|code-simplicity)-review-agent"'
match: not_contains
weight: 3
---
