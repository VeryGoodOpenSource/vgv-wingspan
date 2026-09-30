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

## Handle failures

An agent failure is non-fatal. Note it, continue with the rest, and record the failure in
both the report header and the chat summary so the user knows the review is incomplete —
a silently halved review reads as a clean one.
