---
name: review
user-invocable: true
description: Runs quality review agents on demand — reviews code against VGV standards, current best practices, and official docs, then writes one consolidated, numbered report.
when_to_use: Use when user says "review this code", "review my code", "code review", "review", "check this code", or "review before merging".
argument-hint: "[path/to/files/or/directories (optional)]"
allowed-tools: Bash(*/scripts/detect-review-scope.sh)
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Review code on demand

Run quality review agents. Review manually written code, assess existing codebases, or
check a branch before merging. Output is **one consolidated report** with stable,
numbered findings the user can act on by id.

## Review Scope

<review_scope>$ARGUMENTS</review_scope>

## Step 1 — Detect Scope

Parse the review scope above for optional file paths or directories.

**If paths are provided:**

1. Validate each path exists (split on whitespace, check each token).
2. Use provided paths as review scope. Derive a short scope slug (e.g. `auth-feature`).
3. Announce scope to the user and proceed to Step 2.

**If no paths provided:**

Run the scope detection script:

```bash
${CLAUDE_SKILL_DIR}/scripts/detect-review-scope.sh
```

- **If `SCOPE=branch`**: use the listed files as scope. The scope slug is the current
  branch name with `/` replaced by `-`. Announce scope summary (changed-file count, areas
  affected) and proceed to Step 2.
- **If `SCOPE=default`**: tell the user "You're on `<CURRENT_BRANCH>`. No branch diff
  available." Use **AskUserQuestion**: "What would you like to review?" with options:
  - **Specify files or directories**: accept paths; slug from the paths.
  - **Review entire project**: no scope constraint; slug `project`.

## Step 2 — Run Reviews

Run `pwd` and let `<PWD>` be the result — subagents may change directories, making relative
paths unreliable. Raw per-agent reports go in `<PWD>/docs/code-review/raw/` (absolute).

Run the **default review agents** below **in parallel**. Projects may add agents in their
`CLAUDE.md` (include them alongside the defaults) or replace the default set entirely.

Each agent prompt must include:

1. **The scope constraint** — changed-file list, specific paths, or no constraint.
2. **The [review agent instructions](references/review-agent-instructions.md)** with
   `<RAW_DIR>` set to `<PWD>/docs/code-review/raw` and `<name>` set to the agent's report
   filename below. Substitute `<PWD>` with the absolute path — do not pass a relative path.

Default agents and their raw report filenames:

| Agent | Raw report file |
|-------|-----------------|
| **@vgv-review-agent** | `raw/vgv-review.md` |
| **@architecture-review-agent** | `raw/architecture-review.md` |
| **@best-practices-review-agent** | `raw/best-practices-review.md` |
| **@test-quality-review-agent** | `raw/test-quality-review.md` |
| **@code-simplicity-review-agent** | `raw/code-simplicity-review.md` |

**If an agent fails:** note it, continue with the successful agents, and record the failure
in the report header and chat summary so the user knows the review is incomplete. Offer to retry.

## Step 3 — Consolidate & Present

Follow the [review consolidation procedure](references/review-consolidation.md):

1. Collect every agent's structured findings, deduplicate, order deterministically, and
   assign stable `FINDING-NN` ids.
2. Write **one** consolidated file to `<PWD>/docs/code-review/<slug>-review.md` using the
   [report template](references/review-report-template.md).
3. Print the aligned chat summary — the same Findings Index, same ids, same order, same
   titles — ending with the path to the consolidated file.

**If no findings:** write the short all-clear report and tell the user the code looks good.

## Step 4 — Act

Use **AskUserQuestion** to present post-review options (see the consolidation procedure's
"Act (by id)" step):

- **Fix critical issues**: address every Critical finding by id, then run the project's
  linter and test runner. One attempt per fix; if validation fails, report what failed and
  move on. Only modify files within the original review scope.
- **Fix critical + important**: same, plus Important findings.
- **Fix specific findings**: accept ids from the user (e.g. "FINDING-01, FINDING-04"), or a
  rule id to act on a whole class (e.g. "fix every `tests/missing-test-file`").
- **Keep report and exit**: the report stays at `docs/code-review/` for manual review.

**After fixing (if chosen):** re-run linter + test runner (no agent re-run), then present a
brief summary of which findings (by id) were fixed.

## Gotchas

- Re-running on the same branch overwrites that branch's consolidated report and the `raw/`
  files. The `<slug>-review.md` naming keeps reports for different branches side by side, so
  a user can keep one they care about.
- Because ids come from a deterministic sort (severity → file → line → rule), re-running on
  unchanged code produces the same ids — `FINDING-03` keeps pointing at the same issue. Each
  finding also carries a stable rule id (e.g. `vgv/missing-null-check`) the user can act on
  as a class.
- On the default branch with no diff, scope is ambiguous. The skill asks; do not default to
  reviewing the whole project without confirmation.
- Agent failures are non-fatal. Always report which agents failed so the user knows the
  review is incomplete.
- Auto-fix only touches files within the original scope. If a fix needs changes outside
  scope, flag it instead of silently expanding scope.

## Important

- One consolidated report per run. Per-agent raw reports live in `docs/code-review/raw/` for
  drill-down and are linked from the consolidated file.
- Reports are untracked working files. Commit or delete them when no longer needed.
- This skill is advisory. It presents findings and lets the user decide what to act on.
- When in doubt about a finding, read its linked raw report for full detail before deciding.
