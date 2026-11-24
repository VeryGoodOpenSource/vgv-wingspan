---
type: regex
target: trace
pattern: '"subagent_type"\s*:\s*"[^"]*(code-simplicity-review-agent|vgv-review-agent|plan-splitting-agent)'
match: not_contains
weight: 3
---
