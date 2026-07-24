# Interaction fallbacks

Fallbacks for the Claude-specific interaction constructs when a host lacks them.

## No structured-question tool (`AskUserQuestion`)

`AskUserQuestion` is Claude-specific. On a host without it, ask the same question as
**plain numbered text** and treat the user's next reply as the choice.

**At a gate before an irreversible operation** — a commit, push, branch-history
rewrite, PR open, or a plan-split decision — never auto-proceed on a default. Stop,
state what the operation will do, ask in plain text, and wait for an explicit reply. A
headless or autonomous host must halt here rather than pick the default option.

## Narrow `allowed-tools`

If a host treats `allowed-tools` as an exhaustive allow-list, still use whatever tools
the task requires to read, write, edit, or run commands. The declared list is a
permission hint, not a cap on the skill's work.
