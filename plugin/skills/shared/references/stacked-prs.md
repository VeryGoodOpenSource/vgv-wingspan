# Stacked Pull Requests

How to publish a stack of branches as one pull request per branch, each targeting the branch
below it. It uses GitHub's native stacked pull requests when they are available, and plain
`git` with parent-targeted pull requests otherwise.

The caller decides how the branches came to be. This reference only publishes them and keeps
them consistent afterwards. Rebasing the stack uses `git rebase --update-refs`, which needs git
2.38 or later.

## Inputs

| Input | Meaning |
| ----- | ------- |
| `<BASE_BRANCH>` | The branch the bottom pull request targets, such as `main` |
| `<BRANCHES>` | The stack's branches, bottom to top. Each one is cut from the one before it |
| A title and a body per branch | What each pull request shows |
| `<REMOTE>` | The remote to push to. `origin` unless the caller says otherwise |
| No install offer | Set by a caller that cannot stop to ask, such as an unattended run or agent mode |

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
| `gh` present, `gh-stack` missing | Offer to install it with `gh extension install github/gh-stack`. On decline, use the **manual fallback**. When the caller set **no install offer**, skip the offer, use the fallback, and say why in the closing summary. |
| Only `glab`, or neither | **Manual fallback**. GitLab has no equivalent of GitHub stacks. |

**A fork** changes the shape. Check with
`gh repo view "$(git remote get-url <REMOTE>)" --json isFork -q .isFork`. When `<REMOTE>` is a
fork and the pull requests go to its parent, a pull request there can only target a branch
the parent has, and the phase branches live only in the fork. Open the bottom pull request
alone, from `<owner>:<branch-1>` to `<BASE_BRANCH>`, and tell the user to open each next one
after the one below it merges and the next branch is rebased onto `<BASE_BRANCH>`. Native
stacks do not work across forks either.

GitHub's stacked pull requests are in public preview. If a `gh stack` command exits with code
9 (stacked pull requests unavailable for the repository), use the manual fallback and tell the
user why rather than retrying.

## Native stack

`gh stack` opens prompts or a full-screen editor when it thinks it has a terminal, and an
agent's shell cannot answer them. Always pass the flags below. Pass `--remote <REMOTE>` to
every command that pushes, because a clone with more than one remote otherwise fails or picks
the wrong one. `gh stack checkout`, `top` and the other navigation commands take no `--remote`,
so when `git remote` lists more than one remote and `git config remote.pushDefault` prints
nothing, set it for this repository with `git config remote.pushDefault <REMOTE>` and tell the
user you did.

### Adopt the branches

The branches already exist locally. Pass them bottom to top, and `init` adopts them:

```bash
gh stack init --base <BASE_BRANCH> <branch-1> <branch-2> <branch-3>
gh stack view --json
```

Check that `branches[]` lists them in the same order. If it does not, run
`gh stack unstack --local` and `init` again with the right order.

### Open the pull requests

```bash
gh stack submit --auto --open --remote <REMOTE>
```

This pushes every branch, creates one pull request per branch, each targeting the branch below
it, and links them as a stack on GitHub. `--open` makes them ready for review instead of
drafts. Never run `submit` without `--auto`: its editor needs a terminal and blocks.

`--auto` gives the pull requests generated titles. Set each one's real title and body
afterwards, bottom to top:

```bash
gh pr edit <branch> --title "<title>" --body-file <file>
```

Write each body to a file first: a body passed inline breaks on quotes and backticks.

GitHub renders the stack on each pull request, so the bodies need no position line or merge
guide.

## Manual fallback

Reproduce the shape by hand: each pull request targets the branch below it.

### Push

Push every branch, bottom to top:

```bash
git push -u <REMOTE> <branch>
```

A branch that is already on the remote and was rebased since needs
`git push --force-with-lease <REMOTE> <branch>`. Never use a bare `--force`.

### Open each pull request

Bottom to top, so each target branch exists before the pull request that points at it. The
bottom pull request targets `<BASE_BRANCH>`, and every other one targets the branch below it.
First check whether the branch already has one: `gh pr view <branch> --json url,state` or
`glab mr view <branch>`. An open one only needs the push above. A merged or closed one means
the stack changed outside this run: stop and ask the user.

| CLI | Command |
| --- | ------- |
| `gh` | `gh pr create --head <branch> --base <parent> --title "<title>" --body-file <file>` |
| `glab` | `glab mr create --source-branch <branch> --target-branch <parent> --title "<title>" --description "<body>" --yes` |
| neither | Output each title and body as Markdown for the user to open by hand, with the branch it targets. |

Nothing renders the stack, so start each body with its position and dependency:

```markdown
Part 2 of 3. Depends on #101.
```

### Merge guide

Put the order in the closing summary, because the platform will not track it:

```markdown
## Merge order

1. #101 — <title> → base `main`
2. #102 — <title> → base `<branch-1>`, retarget to `main` after #101 merges
3. #103 — <title> → base `<branch-2>`, retarget to `main` after #102 merges
```

## Keeping the stack consistent

Review feedback on a lower pull request is the normal case. Tell the user how the stack stays
consistent after a fix or a merge, and do the work when the caller asks for it.

### A fix lower in the stack

Commit the fix on the branch that owns the change, then carry it up through every branch above:

| Path | Commands |
| ---- | -------- |
| Native | `gh stack checkout <branch>`, commit, `gh stack rebase --upstack --remote <REMOTE>`, `gh stack top`, `gh stack push --remote <REMOTE>` |
| Fallback | `git checkout <branch>`, commit, `git checkout <top branch>`, `git rebase --update-refs <branch>`, then push `<branch>` and every branch above it, the ones above with `--force-with-lease` |

`--update-refs` moves each intermediate branch onto its rebased commit, so one rebase from the
top branch updates the whole stack. On a conflict, resolve it and `git rebase --continue`, or
`git rebase --abort` to leave the stack as it was.

### After a squash merge

A squash merge rewrites the merged branch's commits into one new commit on `<BASE_BRANCH>`, so
the branch above still carries the old commits and its pull request shows them again.

| Path | What to do |
| ---- | ---------- |
| Native | `gh stack sync --remote <REMOTE>`. It fetches, rebases the rest of the stack onto the new base, pushes, and retargets the pull requests. If it prints `Sync aborted`, the local and GitHub stacks have diverged and nothing changed, even though it exits 0: show the user both chains and stop. |
| Fallback | Fetch, then from the top branch rebase everything above the merged branch onto the base: `git rebase --onto <REMOTE>/<BASE_BRANCH> <merged branch> --update-refs`. Push the rebased branches with `--force-with-lease`, and retarget the next pull request to `<BASE_BRANCH>` if the platform did not (`gh pr edit <next branch> --base <BASE_BRANCH>`, or `glab mr update <next branch> --target-branch <BASE_BRANCH>`). |

The local `<merged branch>` must still point at its pre-merge commit for the `--onto` rebase,
so do not delete it until the branch above is rebased.

## Merging

Never merge as part of publishing. Merging is the user's call after review. Pull requests
merge bottom up.
