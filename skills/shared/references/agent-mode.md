# Agent Mode

Agent mode lets a skill run without a human at the keyboard, for example under an
orchestrator that drives Wingspan end to end. The skill runs every step it normally runs.
The only change is who answers its questions: instead of stopping, the agent takes the
recommended option and records the decision so a human can review it later.

## Turning it on

Agent mode is on when any of these is true:

- the skill's arguments include `--agent-mode`;
- the user's request says to run Wingspan, or this skill, in agent mode (for example
  "use Wingspan in agent mode"); or
- the skill was invoked by another skill, or dispatched to a subagent, that is running in
  agent mode.

It stays on for the rest of the session. When one skill calls another, or dispatches a
subagent that may ask questions, pass `--agent-mode` along. Agent mode is never inferred: a
non-interactive session, a missing question tool, or a user who seems busy does not turn it
on. Without it, the skill's normal question rule applies.

## Answering a question

At every point where the skill would ask the user, do not ask. Instead:

1. **Gather context** the way you would before asking: the request, the documents the skill
   is working from, and the codebase.
2. **Pick an answer:**
   - The option marked **(Recommended)**, when there is one.
   - Otherwise, the option the skill's text names as the default or prefers.
   - Otherwise, the option the gathered context supports best. For an open question with no
     options, such as a brainstorm question, answer it from context and state the
     assumption you made.
   - When nothing settles it, neither a recommendation nor the request, the documents, or
     the codebase, the decision needs a human. Do not guess: treat it as a blocker, below.
3. **Record the decision** in the decision log, below, before acting on it.
4. **Continue** as if the user had chosen that answer.

### What agent mode does not answer

Some questions are not choices between options, and agent mode does not answer them:

- **Leaving the machine or destroying work.** Pushing, opening or merging a PR, publishing
  an issue, posting comments, force operations, and deleting anything the run did not
  create. Take the option that keeps the work local and reversible, even when another
  option is marked recommended, unless the agent-mode request explicitly allows that
  action (for example "agent mode, push and open the PR"). Record the decision either way.
- **Handoffs that wait for a human.** A "Clear context and …" option ends the run until a
  human types `/clear`. Take the option that continues in this context when the skill
  offers one. When it does not, end the skill and record the next step in the log. In
  place of the clear-context handoff block, print the next command with the flag, such as
  `/plan <doc path> --agent-mode`, so the next run stays in agent mode.
- **Attestations.** A question that asks the human to confirm something only a human can
  know, such as a `verify: manual` check, is not answered. Record it as **Pending human**,
  keep going, and never report it as confirmed.
- **Blockers.** When the skill would stop because it cannot proceed, such as validation
  still failing after the allowed attempts, a missing tool, a missing dependency, or a
  decision nothing in the context settles, do not guess past it. Record it as **Blocked**,
  finish the decision log, and end the run with a blocked status.

## The decision log

Keep one log per run at `docs/agent-decisions/decisions.md`. Create it on the first
decision. If it already exists, append to it, so a run that goes from `/brainstorm` to
`/plan` to `/build` keeps one log. The log is a working file: never stage or commit it, and
delete it once the human has reviewed it (below).

Write each decision so that someone who was not there can understand it from the entry
alone:

```markdown
## D-<NN> · <skill> · <short title>

- **Status:** Decided | Pending human | Blocked
- **Impact:** High | Medium | Low — <one line on how much the choice matters>
- **Question:** <the question exactly as the skill would have asked it>
- **Context:** <what was being done, what was known, and what the answer affects>
- **Options:**
  1. <option> — <what it would do>
  2. <option> — <what it would do>
- **Decision:** <the option taken, or the assumption made>
- **Why:** <the recommendation, the evidence, or the agent-mode rule that decided it>
- **Changes if reversed:** <what would need to be redone>
- **Reviewer:** _accept, or name a different option and add a note_
```

Number decisions `D-01`, `D-02`, … in order, and keep numbering across skills in the same
log.

Rate **Impact** by what a reversal would cost: **High** when it changes the product's
behavior, the design, or work other decisions build on; **Medium** when it changes how the
work is done but not what it produces; **Low** when it is cheap to change afterwards, such
as commit cadence or file naming.

## Ending the run

However the run ends — where the skill would ask its final question, at a handoff, or
blocked — the final reply prints:

- the path to the decision log;
- a list with one line per decision: `D-NN · <impact> · <title> → <decision>`, with every
  **Pending human** and **Blocked** entry listed first, then the rest from **High** to
  **Low** impact; and
- how to review: fill in each **Reviewer** line, or reply with the ids to change, then ask
  the agent to apply the review.

When describing what a later run will do, keep to what agent mode allows: never say it will
push, open a PR, or ship unless the request allowed that action.

If the harness can render an interactive page, such as a Claude artifact, offer the same
review as a page: one card per decision showing its context and options, with a choice to
accept it or pick a different option, a notes field, and a way to copy the result back to
the agent.

## Applying the review

When the human returns the review, agent mode is off for this step: the human is here, so
ask with the skill's normal question rule if anything is unclear.

1. For each decision the human changed, redo the work it affected, in log order, since a
   later decision may rest on an earlier one. Re-run the skill's validation afterwards.
2. Move what should outlast the run to where the project keeps decisions: the PR
   description, the plan or brainstorm document, an ADR, or the project's agent
   instructions, whichever the project already uses. Ask the human when it is unclear.
3. Delete `docs/agent-decisions/`.
