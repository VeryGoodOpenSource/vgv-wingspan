# Review Autonomy

How `/build` and `/hotfix` act on Important findings after the review is consolidated.
Critical findings are always fixed and Suggestions follow the calling skill's rule; this
reference changes only the Important tier.

## The setting

**Apply Important findings without asking** is opt-in and off by default. It is a
per-developer preference, not a repo convention, so it never belongs in the project's
`CLAUDE.md`. Each skill says where the choice is made:

- `/build` settles it in Phase 0, in the commit-autonomy question.
- `/hotfix` reads the saved preference. With none saved, it asks at the Important findings
  stop, as it always has, and offers to remember the answer.

## When the setting is off

Present the Important findings to the user and wait for a decision, exactly as before.
When there are Important findings, always stop here and offer all three options below;
never pick one on the user's behalf, even when no question tool is available (ask in plain
text and end the turn):

1. **Apply all (Recommended)**: apply every Important finding this run.
2. **Choose by id**: the user names the findings to apply or skip.
3. **Always apply**: apply every Important finding now, and remember the preference for
   future runs.

Skipped findings are deferred and noted in the PR description.

## When the setting is on

Apply every Important finding whose `fix` you can make without a decision the plan, the
bug description, or the codebase does not already answer. Stop and ask only for a finding
that:

- changes public API, user-facing behavior, or scope beyond the plan or the bug;
- contradicts the plan or an explicit instruction from the user; or
- offers more than one reasonable fix and nothing in the input picks between them.

When some findings stop, apply the rest first, then ask about the stopped ones together in
one question. A stopped finding the user skips is deferred and noted in the PR description.

After applying, run the skill's validation step as usual. If a fix breaks validation and
cannot be repaired within the usual fix attempts, revert that fix, mark the finding
deferred, and say why.

## Record every applied finding

Keep a list of each Important finding applied without asking. The report is deleted at
cleanup, so record the content, not the id:

```markdown
- `<rule id>` · `<location>` · <title> — <one line on what changed>
```

Render this list, under the heading **Applied without asking**, in both:

- the end-of-run summary in chat, and
- the PR description.

If nothing was applied without asking, omit the section. Never list a finding the user
approved explicitly; the section exists to show the user what they did not see.
