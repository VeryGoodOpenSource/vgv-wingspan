---
name: review
user-invocable: true
description: Runs quality review agents on demand — reviews code, assesses quality, and identifies issues before merging. Use when user says "review this code", "review my code", "code review", "review", "check this code", or "review before merging".
argument-hint: "[path/to/files/or/directories (optional)]"
effort: high
compatibility: Designed for Claude Code (or similar products with agent support)
---

# Review code on demand

Run quality review agents. Review manually written code, assess existing codebases, or check a branch before merging.

## Review Scope

<review_scope>$ARGUMENTS</review_scope>

## Step 1 — Detect Scope

Parse the review scope above for optional file paths or directories.

**If paths are provided:**

1. Validate each path exists (split on whitespace, check each token)
2. Use provided paths as review scope
3. Announce scope to user and proceed to Step 2

**If no paths provided:**

Run the scope detection script:

```!
bash scripts/detect-review-scope.sh
```

- **If `SCOPE=branch`**: use the listed files as review scope. Announce scope summary: number of changed files, which areas of the codebase are affected. Proceed to Step 2.
- **If `SCOPE=default`**: tell the user: "You're on `<CURRENT_BRANCH>`. No branch diff available." Use **AskUserQuestion**: "What would you like to review?" with options:
  - **Specify files or directories**: accept paths from the user
  - **Review entire project**: no scope constraint

## Step 2 — Run Reviews

First, resolve the absolute working directory so parallel agents write reports to the correct location. Subagents may change directories during exploration (especially in git worktrees), so relative paths are unreliable:

```!
pwd
```

Let `<PWD>` be the result. The report directory is `<PWD>/docs/code-review/`.

Run the **default review agents** listed below **in parallel**. Projects may define additional review agents in their `CLAUDE.md` — if any are specified, include them alongside the defaults. Projects may also replace the default set entirely by specifying their own list.

Each agent prompt must include:

1. The scope constraint — one of:
   - A list of changed files (for branch diff scope)
   - An instruction to limit review to specific paths (for path scope)
   - No constraint (for full project review)

2. The report output instructions (substitute `<PWD>` with the absolute path resolved above):

   > Write your full detailed report to `<PWD>/docs/code-review/<name>.md` (create the directory if needed). This is an absolute path — use it exactly as given, do not convert to relative.
   > Then return ONLY a short structured summary to the parent context in this format:
   >
   > ```markdown
   > ## <Agent Name> Summary
   > **Report**: `<PWD>/docs/code-review/<name>.md` (<word_count> words)
   > **Critical**: <count> | **Important**: <count> | **Suggestions**: <count>
   > ### Findings
   > - [Critical] <one-line description>
   > - [Important] <one-line description>
   > - [Suggestion] <one-line description>
   > ```
   >
   > Do NOT return the full report text. Only return the summary above.

Default agents and their report filenames (substitute `<PWD>` with the absolute path resolved above):

| Agent | Report file |
|-------|------------|
| **@vgv-review-agent** | `<PWD>/docs/code-review/vgv-review.md` |
| **@code-simplicity-review-agent** | `<PWD>/docs/code-review/code-simplicity-review.md` |
| **@test-quality-review-agent** | `<PWD>/docs/code-review/test-quality-review.md` |
| **@architecture-review-agent** | `<PWD>/docs/code-review/architecture-review.md` |

**If an agent fails:** Note the failure, continue with successful agents. After all agents complete, report which (if any) failed and offer to retry.

## Step 3 — Consolidate & Present

After all reviews complete:

1. [Categorize findings](references/review-consolidation.md) from all summaries into Critical, Important, and Suggestions.

2. **Present the consolidated summary** to the user with counts per category and the one-line descriptions from each agent.

3. **If no findings:** Code looks good. Reports are at `docs/code-review/`.

## Step 4 — Act

Use **AskUserQuestion** to present post-review options:

- **Auto-fix critical issues**: Read the specific report files for full details on each critical finding. Fix them, then run the project's linter and test runner for validation. One attempt per fix — if validation fails, present the issue to the user with context on what failed and what was tried, and move on. Only modify files within the original review scope.
- **Fix all issues (critical + important)**: Same as above but also address important findings. Read relevant report files for details. Only modify files within the original review scope.
- **Review the list**: Show the full list of findings with report file paths so the user can decide what to address manually.
- **Keep reports and exit**: Reports remain at `docs/code-review/` for manual review. Done.

**After fixing (if chosen):**

1. Run project linter and test runner for validation (no agent re-run)
2. Present a brief summary of what was fixed

## Gotchas

- If `docs/code-review/` already exists from a previous review, old reports will be overwritten by agents with the same name. Delete the directory first if you want a clean slate.
- On the default branch with no diff, the review scope is ambiguous. The skill asks the user to specify — do not default to reviewing the entire project without confirmation.
- Agent failures are non-fatal. If one agent fails, the others still produce reports. Always report which agents failed so the user knows the review is incomplete.
- Auto-fix only modifies files within the original review scope. If a fix requires changes outside scope (e.g., updating a shared import), flag it to the user instead of silently expanding scope.

## Important

- Reports are kept at `docs/code-review/` as untracked working files. Commit or delete them when no longer needed.
- This skill is advisory. It presents findings and lets you decide what to act on.
- When in doubt about a finding, read the full report file for details before deciding.
