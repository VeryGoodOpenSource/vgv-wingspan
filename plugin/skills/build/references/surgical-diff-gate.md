# Surgical-Diff Gate

Before the implementation goes to review, every change on the branch must trace to a plan task or the original request. This gate removes untraceable churn (drive-by reformatting, unrequested type hints, speculative validation), deletes only the symbols this branch orphaned, and reports pre-existing dead code without touching it. The build skill runs it at the end of Phase 2, before the review phase, so reviewers only see the diff that belongs.

## Step 1: Establish the diff base

Determine the base branch, then diff the whole branch against it.

1. Base branch: use the plan's stated target if it names one. Otherwise read `git symbolic-ref refs/remotes/origin/HEAD` and strip it to the branch name. Fall back to `main`.
2. Anchor: `BASE=$(git merge-base HEAD <base-branch>)`.
3. Inspect the full branch diff: `git diff "$BASE"` for tracked changes, and `git status --porcelain` for new untracked files.

Diff against the merge-base, not a bare `git diff`. That captures the whole branch — committed history and working-tree changes alike — so the gate sees every hunk no matter what has been committed yet. At the end of Phase 2 the implementation is usually still uncommitted, so remember to include untracked files.

## Step 2: Classify every hunk

A hunk is **traceable** when it maps to one of two origins:

1. A **plan task** — the hunk's file appears in the plan's files-to-create/modify list and the change matches the task's intent.
2. The **original request**.

## Step 3: Honor the auto-traceable whitelist

Never flag or remove these, even when they lack an obvious plan task:

- Generated files: mocks, codegen output, `*.g.dart`, `*.mocks.dart`, `*.freezed.dart`, and equivalents.
- New test files. The non-negotiable testing rule mandates them, so they trace to the task whose code they cover.
- Formatter or whitespace-only hunks on lines this branch already touched.
- Auto-added or reordered imports that are side effects of a traceable change.
- Dependency lockfiles and manifests changed by a dependency the plan called for (`pubspec.lock` and equivalents).

## Step 4: Remove untraceable churn

Edit the working tree to strip untraceable lines. Work at line-level granularity, not whole-hunk, because a single hunk often mixes a real change with a drive-by edit. If any work is already committed, do not rewrite history — correcting the working tree reaches the same end state, and the removal gets committed with the rest of the implementation.

## Step 5: Revert safety

After removals, re-run the linter and tests per [validate-and-fix](validate-and-fix.md). If a removal breaks the build, that hunk was load-bearing, not pure churn. Restore it and surface it to the user with **AskUserQuestion** rather than shipping a red build.

## Step 6: Handle dead code — bias toward keeping

Delete a symbol only when **both** conditions hold:

1. Its sole references were on lines this branch removed, and
2. It is defined in a file this branch touched.

That is a self-created orphan. Every other unused symbol is pre-existing dead code: leave it in place and add it to a **"Noticed (not changed):"** list. When in doubt, do not delete.

## Step 7: Surface results

Report the removed churn and the "Noticed (not changed):" list to the user. This is an observation about pre-existing code the branch did not touch, so keep it in the build session for the user to act on. Do not add it to the PR body, which describes only what this change implements.
