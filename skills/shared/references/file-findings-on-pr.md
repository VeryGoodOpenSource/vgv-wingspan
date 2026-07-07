# File Findings on the PR

Post selected review findings to the branch's pull request as comments. Findings keep the
`FINDING-NN` ids and `<category>/<rule>` from the [consolidation procedure](review-consolidation.md),
so a PR comment maps back to the consolidated report unambiguously.

This is a **two-step decision**, and nothing is posted until both are made:

1. **What to post** — the user picks which findings are worth a comment (Step 1).
2. **How to post** — the user then decides how those findings reach the PR, including *not*
   posting and taking the drafted text to post themselves (Step 2).

AI reviews run long; keep each comment to its one-line `why` and `fix` so the PR does not
drown in prose, and never post without an explicit choice at both steps.

## Step 1 — Choose which findings (what to post)

Use **AskUserQuestion**: "Which findings should I file on the PR?"

- **All** — every finding in the report.
- **Critical + Important** — skip Suggestions.
- **Pick specific** — present the findings as one or more multi-select lists (batches of up to
  four, by `FINDING-NN` id + title) and keep only the checked ones.

If the user picks none, stop.

## Step 2 — Choose how to post (how to deliver)

First **draft** the comments for the selected findings and show them to the user as a compact
preview, so they see exactly what would go out before anything is posted:

```markdown
**FINDING-03 · 🟡 Important · `vgv/force-unwrap`**

Why: <why line>
Fix: <fix line>
```

Then use **AskUserQuestion**: "How should I post these <N> findings?"

- **Inline comments** — one comment per finding, anchored to its `file:line` (a finding whose
  line isn't on the diff falls back into the summary comment).
- **One summary comment** — all selected findings in a single PR comment, grouped by severity.
- **Print for manual posting** — post nothing; output the drafted markdown so the user posts
  it (or edits it) themselves.

Do not auto-post: apply only the method the user picks. If they pick "Print for manual
posting", skip Steps 3–4 and just output the markdown.

## Step 3 — Detect the platform and PR

Only when the user chose to post. Run in parallel:

```bash
gh --version 2>/dev/null
glab --version 2>/dev/null
```

Store the first available as `PR_CLI` (`gh`, `glab`, or `none`). Then find the PR for the
current branch:

| `PR_CLI` | Command |
| -------- | ------- |
| `gh` | `gh pr view --json number,url,headRefOid` |
| `glab` | `glab mr view` |
| `none` | No CLI — print the drafted markdown instead and tell the user. |

If no PR exists for the branch, tell the user and print the markdown instead. Do not create a
PR from here.

## Step 4 — Post (using the chosen method)

### Inline comments — gh (GitHub)

Resolve `OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)`,
`PR=$(gh pr view --json number -q .number)`, `SHA=$(gh pr view --json headRefOid -q .headRefOid)`.
For each finding whose `location` is `file:line` and that line is part of the PR diff:

```bash
gh api "repos/$OWNER_REPO/pulls/$PR/comments" \
  -f body="$COMMENT" -f commit_id="$SHA" -f path="$FILE" -F line=$LINE -f side=RIGHT
```

Findings whose line isn't on the diff go into the summary comment instead of being dropped.

### Inline comments — glab (GitLab)

Post each finding as a note on the MR: `glab mr note <id> -m "$COMMENT"` (include the
`file:line` in the text, since inline positions need the diff SHAs).

### One summary comment

Render the selected findings into a single body (grouped by severity, ids kept) and post once:
`gh pr comment --body-file <file>` / `glab mr note -m ...`.

## Step 5 — Report

Tell the user what happened: how many comments were posted (or that the markdown was printed
for manual posting), how many fell back to the summary, and the PR URL. If a post call fails
(e.g. the line wasn't on the diff), report which findings and include them in the summary or
the printed markdown rather than dropping them.
