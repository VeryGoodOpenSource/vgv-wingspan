# Interaction fallbacks

<!-- portability:ask-fallback -->

Cross-harness fallbacks for the Claude-specific interaction constructs. A strong host
(Claude Code) uses the primary construct and ignores these notes; a weaker host follows
them. Each is a diff against the primary path, not a replacement.

## No structured-question tool (`AskUserQuestion`)

`AskUserQuestion` is Claude-specific. On a host without it, ask the same question as
**plain numbered text** and treat the user's next reply as the choice.

**At a gate before an irreversible operation** — a commit, push, branch-history
rewrite, PR open, or a plan-split decision — never auto-proceed on a default. Stop,
state what the operation will do, ask in plain text, and wait for an explicit reply. A
headless or autonomous host must halt here rather than pick the default option.

## Narrow `allowed-tools`

`allowed-tools` is an experimental spec field; some hosts treat the list as an
exhaustive allow-list rather than a permission hint. A skill whose body needs to read,
write, edit, or run commands beyond its declared list must use whatever tools the task
requires — the list is a permission hint for Claude Code, not a cap on the skill's work.
If a host enforces the list and blocks a needed tool, that is the signal to widen the
frontmatter list to the full set the skill uses.
