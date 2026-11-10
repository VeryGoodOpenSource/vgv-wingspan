# Review Agent Dispatch

How a skill launches its quality-review agents. The calling skill supplies two things: the
absolute raw-reports directory (`<RAW_DIR>`) and the table of agents with their report names.

## Resolve the paths

Run `pwd` and let `<PWD>` be the result — subagents may change directories, so a relative
path is unreliable. Substitute `<PWD>` into `<RAW_DIR>` before dispatching; never pass a
relative path to an agent.

## Dispatch

Run every agent in the skill's table **in parallel**, in a single message. Each agent prompt
carries:

1. **The scope constraint** — the changed-file list, the specific paths under review, or no
   constraint, whichever the calling skill established.
2. **The [review agent instructions](review-agent-instructions.md)**, with `<RAW_DIR>` set to
   the resolved absolute directory and `<name>` set to that agent's report name from the
   table (a bare stem — the agent writes `<RAW_DIR>/<name>.md`).

## Companion reviewers

When the calling skill includes companion reviewers, read the plugin's
`hooks/recommendations/*.json`. A file participates only if it carries a `reviewAgent`
field. Evaluate its `detect` rule against the current project, with the same logic the
`recommend-plugins.sh` hook applies. When `detect` matches and the agent type named in
`reviewAgent` is available, dispatch it in the same parallel message as the skill's own
agents. Pass it only the scope constraint: a companion reviewer has its own output format,
so it gets no review agent instructions. Its report name is the agent name without the
plugin prefix (`vgv-ai-flutter-plugin:flutter-reviewer` → `flutter-reviewer`). When the
agent type is not installed, skip it; the recommendation hook already suggests the plugin.

## Handle failures

An agent failure is non-fatal. Note it, continue with the rest, and record the failure in
both the report header and the chat summary so the user knows the review is incomplete —
a silently halved review reads as a clean one.

A reply that does not start with the findings block and its **Verdict** line counts as a
failure too, so a missing or empty reply never passes for a clean review. Companion
reviewers are the exception: they return their own format, which
[consolidation](review-consolidation.md) maps.
