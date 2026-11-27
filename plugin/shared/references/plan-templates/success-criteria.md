# Success Criteria block

The single source for the machine-checkable success-criteria block. Every plan template and the `/plan` Success Criteria Gate reference this file so it is maintained once.

Each criterion names the command that proves it. Use `verify: <command>` (exit 0 = pass) when a command can prove it without human judgment, or `verify: manual <steps>` when only a human can. Reject vacuous criteria like "make it work" — rewrite them as something provable. Fold functional, non-functional, and quality-gate requirements into concrete criteria.

Embed this block verbatim in the plan's `## Success Criteria` section, filling in the placeholders:

```success-criteria
GOAL: <one sentence describing the intended end state>

SUCCESS CRITERIA:
- <observable criterion> | verify: <shell command; exit 0 = pass>
- <observable criterion> | verify: manual <numbered human steps>

NON-GOALS:
- <explicitly out of scope>

VERIFICATION COMMAND: <the non-manual verify commands above joined into one runnable command (e.g. with &&); exit 0 = all green>
```
