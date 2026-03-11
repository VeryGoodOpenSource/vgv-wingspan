---
name: review
description: Run quality review agents on demand — review code, assess quality, and identify issues before merging.
argument-hint: "[path/to/files/or/directories (optional)]"
---

# Review code on demand

Run quality review agents independently of `/build`. Review manually written code, assess existing codebases, or check a branch before merging.

## Review Scope

<review_scope> #$ARGUMENTS </review_scope>

## Step 1 — Detect Scope

Parse the review scope above for optional file paths or directories.

**If paths are provided:**

1. Validate each path exists (split on whitespace, check each token)
2. Use provided paths as review scope
3. Announce scope to user and proceed to Step 2

**If no paths provided:**

1. Detect current branch:

   ```bash
   git rev-parse --abbrev-ref HEAD
   ```

2. Detect default branch:

   ```bash
   git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'
   ```

   Fallback: check for `main`, then `master`.

3. **If on a feature branch** (current branch differs from the default branch):
   - Get changed files: `git diff <default-branch>...HEAD --name-only`
   - Include uncommitted changes: `git diff --name-only` and `git diff --cached --name-only`
   - Deduplicate the combined file list
   - Announce scope summary: number of changed files, which areas of the codebase are affected
   - Proceed to Step 2 — the user invoked `/review`, intent is clear

4. **If on the default branch:**
   - Tell the user: "You're on `<branch>`. No branch diff available."
   - Use **AskUserQuestion**: "What would you like to review?" with options:
     - **Specify files or directories**: accept paths from the user
     - **Review entire project**: no scope constraint

## Step 2 — Run Reviews

Run 4 review agents **in parallel**.

Each agent prompt must include:

1. The scope constraint — one of:
   - A list of changed files (for branch diff scope)
   - An instruction to limit review to specific paths (for path scope)
   - No constraint (for full project review)

2. The report output instructions:

   > Write your full detailed report to `docs/reviews/<name>.md` (create the directory if needed).
   > Then return ONLY a short structured summary to the parent context in this format:
   >
   > ```markdown
   > ## <Agent Name> Summary
   > **Report**: `docs/reviews/<name>.md` (<word_count> words)
   > **Critical**: <count> | **Important**: <count> | **Suggestions**: <count>
   > ### Findings
   > - [Critical] <one-line description>
   > - [Important] <one-line description>
   > - [Suggestion] <one-line description>
   > ```
   >
   > Do NOT return the full report text. Only return the summary above.

The 4 agents and their report filenames:

| Agent | Report file |
|-------|------------|
| **@vgv-review-agent** | `docs/reviews/vgv-review.md` |
| **@code-simplicity-review-agent** | `docs/reviews/code-simplicity-review.md` |
| **@test-quality-review-agent** | `docs/reviews/test-quality-review.md` |
| **@architecture-review-agent** | `docs/reviews/architecture-review.md` |

**Note:** `/build` Phase 3 also references `@pr-readiness-review-agent`, which does not exist in the codebase. `/review` intentionally excludes it — PR readiness is specific to the `/build` shipping context.

**If an agent fails:** Note the failure, continue with successful agents. After all agents complete, report which (if any) failed and offer to retry.

## Step 3 — Consolidate & Present

After all reviews complete:

1. **Consolidate findings** from all summaries into three categories:
   - **Critical** (must fix before merge): Bugs, missing tests, layer violations, broken analysis
   - **Important** (should fix): Convention deviations, test gaps, naming issues
   - **Suggestions** (nice to have): Style improvements, minor simplifications

2. **Present the consolidated summary** to the user with counts per category and the one-line descriptions from each agent.

3. **If no findings:** Code looks good. Reports are at `docs/reviews/`.

## Step 4 — Act

Use **AskUserQuestion** to present post-review options:

- **Auto-fix critical issues**: Read the specific report files for full details on each critical finding. Fix them, then run the project's linter and test runner for validation. One attempt per fix — if validation fails, present the issue to the user with context on what failed and what was tried, and move on. Only modify files within the original review scope.
- **Fix all issues (critical + important)**: Same as above but also address important findings. Read relevant report files for details. Only modify files within the original review scope.
- **Review the list**: Show the full list of findings with report file paths so the user can decide what to address manually.
- **Keep reports and exit**: Reports remain at `docs/reviews/` for manual review. Done.

**After fixing (if chosen):**

1. Run project linter and test runner for validation (no agent re-run)
2. Present a brief summary of what was fixed

## Important

- Reports are kept at `docs/reviews/` as untracked working files. Commit or copy them if you need persistence — `/build` cleanup will delete this directory.
- This skill is advisory. It presents findings and lets you decide what to act on.
- When in doubt about a finding, read the full report file for details before deciding.
