# Stacked Pull Requests Reference

How to publish the branches built in Step 6 as pull requests, using GitHub's native stacked pull requests when they are available.

## Detect the available path

Run in parallel:

```bash
gh --version 2>/dev/null
glab --version 2>/dev/null
gh extension list 2>/dev/null
```

| Result | Path |
| ------ | ---- |
| `gh` present and `gh-stack` listed | **Native stack** below. |
| `gh` present, `gh-stack` missing | Offer to install it: `gh extension install github/gh-stack`. On decline, use the **manual fallback**. |
| Only `glab`, or neither | **Manual fallback**. GitLab has no equivalent of GitHub stacks. |

GitHub's stacked pull requests are in public preview. If a `gh stack` command fails because the feature is unavailable for the repository, fall back to the manual path and tell the user why rather than retrying.

## Native stack

Stacks require every branch to live in the **same repository**. Cross-fork stacks are not supported, so a contributor working from a fork must use the manual fallback.

### Adopt the branches

The branches already exist locally, so adopt them rather than authoring a new stack. Pass them bottom-to-top:

```bash
gh stack init --base <BASE_BRANCH> <branch-1> <branch-2> <branch-3>
```

Verify the order before going further:

```bash
gh stack view
```

The output lists the branches from trunk upward. If the order is wrong, fix it with `gh stack modify` — it needs a clean working tree and no rebase in progress.

### Open the pull requests

```bash
gh stack submit
```

This pushes every branch and creates a pull request per branch, each targeting the branch below it, wired together as a stack on GitHub.

Run it **without `--auto`**. In an interactive terminal `submit` opens an editor where each pull request's title and description can be set, which is where the titles agreed in Step 4 go. `--auto` skips that editor and substitutes auto-generated titles, discarding the ones the user just approved — reach for it only in a non-interactive session, and say so when you do.

| Flag | Effect |
| ---- | ------ |
| none | Interactive editor. New pull requests default to ready for review. |
| `--auto` | No editor, auto-generated titles, created as drafts. |
| `--open` | Mark new and existing pull requests ready for review. Pair with `--auto` to avoid drafts. |

To publish only part of the stack, deselect branches in the editor with `Ctrl+X`. Deselecting a branch also deselects everything above it, since a pull request cannot target an unpublished branch.

### What the user gets

GitHub renders the stack on each pull request, so the position and dependencies are visible without a hand-written merge guide. Pull requests merge bottom-up: merging one mid-stack also merges everything below it, and the ones above automatically retarget. There is no manual retargeting to do.

### Useful follow-ups

| Command | Use |
| ------- | --- |
| `gh stack view` | Show the stack, its pull requests, and each branch's position. |
| `gh stack sync` | Fetch, fast-forward trunk, cascade-rebase the stack, push, and reconcile pull request state. |
| `gh stack rebase` | Cascade-rebase after the base branch moves. `--continue` and `--abort` handle conflicts. |
| `gh stack merge <pr>` | Merge every pull request up to and including `<pr>`. All-or-nothing. `--squash`, `--merge`, `--rebase` pick the method. |
| `gh stack unstack --local` | Stop tracking the stack locally without changing it on GitHub. |

Mention `gh stack sync` to the user in the closing summary. Review feedback on a lower pull request is the normal case, and after amending it the stack above needs a cascade-rebase to stay consistent.

Do not run `gh stack merge` as part of this skill. Merging is the user's call after review.

## Manual fallback

Without stack support, reproduce the shape by hand: each pull request targets the branch below it.

### Push

```bash
git push -u origin <branch-n>
```

### Open each pull request

Bottom to top, so each target branch exists before the pull request pointing at it:

| CLI | Command |
| --- | ------- |
| `gh` | `gh pr create --title "<title>" --body "<body>" --base <parent-branch>` |
| `glab` | `glab mr create --title "<title>" --description "<body>" --target-branch <parent-branch>` |
| neither | Output the titles and bodies as Markdown for the user to open by hand. |

Use the repository's pull request template when one exists at `.github/PULL_REQUEST_TEMPLATE.md`, `.github/pull_request_template.md`, or `docs/pull_request_template.md`.

In each body, state the position and the dependency explicitly, since nothing renders it automatically:

```markdown
Part 2 of 6. Depends on #101.
```

Some teams also put the position in the title, such as `feat: (2/6) add user profile model`. Follow the convention already visible in the repository's recent pull requests rather than introducing one.

### Merge guide

Close with the order, because the platform will not track it:

```markdown
## Merge order

1. #101 — API endpoints → base `main`
2. #102 — user profile model → base `<branch-1>`, retarget to `main` after #101 merges
3. #103 — settings interface → base `<branch-2>`, retarget to `main` after #102 merges

Retarget each pull request to `main` once the one below it merges. Repositories with
"automatically retarget" enabled do this for you.

`<SOURCE_BRANCH>` is unchanged and can be deleted once the stack lands.
```

Warn the user that a squash merge on a lower pull request rewrites its commits, which orphans the branch above it. After each squash merge, the next branch needs `git rebase --onto main <old-parent> <branch>` before it will show a clean diff.
