---
name: split-pr
user-invocable: true
description: Split a large branch or open pull request into a stack of smaller, independently-reviewable pull requests. Works on existing code changes only, not on plans or specs.
when_to_use: Use when the user says "split this PR", "break up this branch", "this PR is too big", "chunk these changes into smaller PRs", or pastes a PR URL and asks for it to be split.
argument-hint: "[optional: branch name, PR number, or PR URL]"
allowed-tools: Bash(*/scripts/detect-base-branch.sh) Bash(*/scripts/split-inventory.sh) Bash(git *) Bash(gh *) Bash(glab *)
effort: high
compatibility: Designed for Claude Code (or similar products with git access)
---

# Split a pull request

Break a large branch or open pull request into a stack of smaller pull requests that each tell one story and can be reviewed on their own.

## Steps checklist

- [ ] Step 0: Parse arguments
- [ ] Step 1: Validate preconditions
- [ ] Step 2: Inventory the diff
- [ ] Step 3: Group the changes
- [ ] Step 4: Propose the split and get approval
- [ ] Step 5: Build the stack
- [ ] Step 6: Verify each branch
- [ ] Step 7: Publish

## Important

- The source branch is read-only. Nothing here writes to it, and Step 6 checks that it did not move.
- Do not create any branch before the user approves the plan in Step 4.
- Do not push or open pull requests before the user confirms in Step 7.

## Context

<context>$ARGUMENTS</context>

This may be a branch name, a pull request number or URL, or empty.

## Step 0: Parse arguments

| Argument | Action |
| -------- | ------ |
| Branch name | Use it as `SOURCE_BRANCH`. |
| PR number or URL | Resolve the head branch and target branch from the platform (`gh pr view <ref> --json headRefName,baseRefName`). |
| Empty | Use the current branch as `SOURCE_BRANCH`. |

## Step 1: Validate preconditions

Run in parallel:

```bash
git rev-parse --abbrev-ref HEAD
git status --porcelain
${CLAUDE_SKILL_DIR}/scripts/detect-base-branch.sh
```

Stop and tell the user if any of these hold:

- `SOURCE_BRANCH` is the base branch — there is nothing to split.
- The working tree is dirty. Splitting checks out branches, so it needs a clean tree. Offer to commit or stash first.
- The base branch could not be detected. Ask the user which branch the work targets.

Store the detected base as `BASE_BRANCH`, overriding it with the pull request's target branch when Step 0 resolved one.

Record the source tip, so Step 6 can prove it never moved:

```bash
git rev-parse <SOURCE_BRANCH>
```

Store it as `SOURCE_SHA`.

Fetch so the comparison runs against current refs:

```bash
git fetch origin
```

## Step 2: Inventory the diff

```bash
${CLAUDE_SKILL_DIR}/scripts/split-inventory.sh <BASE_BRANCH> <SOURCE_BRANCH>
```

The script reports `MEANINGFUL_LINES`, `GENERATED_LINES`, and a per-file record of added and deleted lines classified as `source` or `generated`. Use `MEANINGFUL_LINES` for every size judgment — generated output inflates a diff without adding anything for a reviewer to read.

If `MEANINGFUL_LINES` is under 500, say so and ask whether the user still wants to split. A small branch usually should not be.

Then read the diff itself:

```bash
git log <BASE_BRANCH>..<SOURCE_BRANCH> --oneline
git diff <BASE_BRANCH>...<SOURCE_BRANCH>
```

Filenames alone are not enough. Read the changes to learn what each file does and which files reference each other — that is what determines whether two files can land separately.

## Step 3: Group the changes

Apply the [splitting heuristics](references/heuristics.md) to turn the file list into an ordered set of pull requests. That reference holds the size targets, the boundaries worth splitting on, the signals that a group should stay whole, and how to break down a layer that is still too large.

Every group must satisfy all of:

- It builds and passes its own tests without any later group.
- Its meaningful diff is under the size ceiling in the heuristics reference.
- It has one describable purpose.

## Step 4: Propose the split and get approval

Present the plan before touching any branch. For each proposed pull request give the title, the files, the meaningful line count, a one-sentence description, and which group it depends on.

```markdown
## Proposed split — 6 PRs from 2,340 meaningful lines

### 1. Add settings API endpoints
`src/api/settings.ts`, `src/api/settings.test.ts`
~120 lines · depends on: nothing
Adds the endpoints the feature calls. No business logic or interface code.

### 2. Add user profile model
`src/models/profile.ts`, `src/models/profile.test.ts`
~350 lines · depends on: 1
Core model the profile screen and the repository both need.

## Stack order
main → 1 → 2 → 3 → 4 → 5 → 6
```

Then ask, with **AskUserQuestion**:

**Question:** "Here is how I would split this. Does the grouping work?"

**Options:**

1. **Approve** — build the stack as proposed.
2. **Move files** — ask which files belong in which pull request, revise, ask again.
3. **Cancel** — stop without changing anything.

Tell the user the source branch is left untouched and that every group lands on a new branch, so nothing they have now is rewritten.

**Do not proceed without approval.**

## Step 5: Build the stack

Each branch starts from the branch below it, not from the base. That is what makes the result a stack: every pull request shows only its own changes rather than repeating everything underneath.

For the first group:

```bash
git checkout -b <branch-1> <BASE_BRANCH>
```

For each subsequent group:

```bash
git checkout -b <branch-n> <branch-n-minus-1>
```

Populate each branch by whichever of these fits:

| Situation | Approach |
| --------- | -------- |
| Commits already map to the groups | `git cherry-pick <commit>...` |
| Commits are mixed across groups | `git checkout <SOURCE_BRANCH> -- <files>`, then commit |
| One file spans two groups | Check the file out, then edit it down to only this group's changes |

Commit each branch with a message describing that group alone, following whatever commit convention the project already uses. Infer it from `git log <BASE_BRANCH> --oneline -20`.

Watch for these while building:

- **Partial files.** A file whose hunks belong to different groups has to be split by hand. Check it out from the source branch, then remove the hunks that belong later. Re-read the result before committing.
- **Generated output.** Include only the generated files matching source files in the same group, or leave generated files out entirely and regenerate after the stack lands. Never let a generated file arrive before the source that produces it.
- **Tests travel with their code.** Never separate an implementation from its tests.
- **Changes already on the base.** A branch that absorbed the base through a merge commit carries changes that are not part of the feature. Leave them out and say so.

## Step 6: Verify each branch

For each branch, from the bottom of the stack up:

```bash
git checkout <branch-n>
git diff <parent-branch>...<branch-n> --stat
```

Confirm that only the intended files appear and that nothing leaked in from an adjacent group. Then run the project's build and test commands on each branch. A branch that does not pass on its own is not independently mergeable — fold it into its neighbor or move the missing file into it, and re-verify.

Then confirm the source branch never moved:

```bash
git rev-parse <SOURCE_BRANCH>
```

This must still equal `SOURCE_SHA` from Step 1. Nothing in Step 5 writes to the source branch, so a different value means a command went to the wrong branch. Stop and tell the user, and recover the original tip from `git reflog <SOURCE_BRANCH>`.

Then prove nothing was lost, by diffing the top of the stack against the source branch:

```bash
git diff <top-branch> <SOURCE_BRANCH> --stat
```

Empty output means the stack reproduces the original exactly. Anything listed is a change that reached no group. Account for every line: generated files left out on purpose belong here, an overlooked source file is a bug in the split. Report whatever remains either way.

Report any branch you could not verify, and why.

## Step 7: Publish

Ask, with **AskUserQuestion**, whether to push the branches and open the pull requests. On **No**, stop and summarize the local branches so the user can publish by hand.

On **Yes**, consult the [stacked pull requests reference](references/stacked-prs.md). It detects whether GitHub's native stacked pull requests are available and gives both paths: the `gh stack` commands that adopt these branches into a real stack, and the manual parent-targeted fallback for GitLab, older CLIs, or repositories without the feature.

Finish with a summary listing each pull request, its base, and the merge order, and confirm the source branch is unchanged at `SOURCE_SHA`.
