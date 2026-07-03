# File Findings on the PR

Post selected review findings to the branch's pull request as comments. Findings keep the
`FINDING-NN` ids and `<category>/<rule>` from the [consolidation procedure](review-consolidation.md),
so a PR comment maps back to the consolidated report unambiguously.

Outward-facing action: only post after the user has selected findings in Step 1 below. Never
post without an explicit selection.

## Step 1 — Choose which findings

Use **AskUserQuestion**: "Which findings should I file on the PR?"

- **All** — every finding in the report.
- **Critical + Important** — skip Suggestions.
- **Pick specific** — present the findings as one or more multi-select lists (batches of up to
  four, by `FINDING-NN` id + title) and post only the checked ones.

If the user picks none, stop without posting.

## Step 2 — Detect the platform and PR

Run in parallel:

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
| `none` | No CLI — go to the fallback in Step 4. |

If no PR exists for the branch, tell the user and offer the fallback (print the comments as
markdown to paste manually). Do not create a PR from here.

## Step 3 — Post the comments

Prefer **inline** comments anchored to each finding's `file:line`. Comment out of these fields:

```markdown
**FINDING-03 · 🟡 Important · `vgv/force-unwrap`**

Why: <why line>
Fix: <fix line>
```

### gh (GitHub)

Resolve `OWNER_REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)`,
`PR=$(gh pr view --json number -q .number)`, `SHA=$(gh pr view --json headRefOid -q .headRefOid)`.
For each finding whose `location` is `file:line` and that line is part of the PR diff:

```bash
gh api "repos/$OWNER_REPO/pulls/$PR/comments" \
  -f body="$COMMENT" -f commit_id="$SHA" -f path="$FILE" -F line=$LINE -f side=RIGHT
```

### glab (GitLab)

Post each finding as a note on the MR: `glab mr note <id> -m "$COMMENT"` (include the
`file:line` in the comment text, since inline positions need the diff SHAs).

### Fallback (no line on the diff, `PR_CLI=none`, or no PR)

Collect the leftover findings into **one** summary comment and post it once
(`gh pr comment --body-file <file>` / `glab mr note -m ...`), or print it for manual paste
when there is no CLI/PR. Group by severity; keep the ids.

## Step 4 — Report

Tell the user how many comments were posted, how many fell back to the summary, and the PR
URL. If any `gh api` call failed (e.g. the line was not in the diff), report which findings
and include them in the summary comment rather than dropping them.
