# Plan on a GitHub issue

When `/plan` or `/build` is started from a GitHub issue — its URL or `#<number>` in the
arguments — the issue is where the plan lives. `/plan` writes the plan to it, and `/build`
reads the plan back from it. Started from anything else, both skills use `docs/plan/` as
before.

`REPO` is `owner/name` from `gh repo view --json nameWithOwner -q .nameWithOwner`, and
`ISSUE` is the issue's number.

## Layout

The layout is the contract between `/plan` and `/build`, so keep it exact.

- **Plan comment.** One comment on `ISSUE` holds the plan. Its first line is
  `<!-- wingspan:plan -->`, which is how `/build` finds it. Below it goes the plan as
  `/plan` would write it to `docs/plan/`, except the `## Implementation Phases` section,
  which lists each phase as `- Phase N: <name> — #<sub-issue>`.
- **Phase sub-issues.** A plan with phases gets one sub-issue of `ISSUE` per phase:
  - **Title:** `Phase N: <name> (<plan title>)`
  - **Body:** `Part of #<ISSUE>.`, then the phase's `**Scope:**`, `**Files touched:**`,
    `**Acceptance criteria:**` and `**Validation:**` fields from the
    [Implementation Phases block](implementation-phases.md). Leave out `**Status:**`: the
    issue being open or closed is the status.
  - Phase N is **blocked by** phase N-1, so the phases are built in order.
- **A plan with no phases** gets no sub-issues. Its pull request closes `ISSUE` itself.

## Publishing the plan (`/plan`)

### Before planning

Check `gh auth status` succeeds. Then look for a plan already on `ISSUE`: a comment
starting with `<!-- wingspan:plan -->`, or sub-issues.

```bash
gh api --paginate repos/REPO/issues/ISSUE/comments -q '.[] | select(.body | test("^<!-- wingspan:plan -->")) | .id'
gh api repos/REPO/issues/ISSUE/sub_issues -q 'length'
```

If the first prints an id or the second is non-zero, the issue already has a plan. Use
**AskUserQuestion**: build it with `/build #ISSUE`, or plan again and replace the plan
comment. Replacing leaves existing
sub-issues as they are: a phase someone already built is not undone, and a new plan that
drops a phase says so in the plan comment rather than deleting its issue.

### Draft and review

Write the draft to its usual `docs/plan/` path, so the plan review and refine steps work
on it unchanged. Skip the feature branch check: the draft leaves the repository once it is
published, and `/build` cuts a branch per phase.

When the plan review recommends a split, offer only **Restructure into phases** and **Keep
as one plan, no phases**. On an issue every phase already ships as its own pull request, so
part-N files would only duplicate the phases.

### Confirm before publishing

Publishing writes to the team's tracker, so never do it unprompted. Show the plan comment and
the sub-issue titles, then use **AskUserQuestion**:

**Question:** "Post this plan to #ISSUE and create N phase sub-issues? The local plan file is
removed once they exist."

1. **Yes** — publish
2. **Edit** — ask what to change, revise, ask again
3. **No** — keep the local plan file and continue as a local plan

### Publish

Write every body to a temporary file so the formatting survives the shell. Then, for each
phase in order:

```bash
gh issue create --repo REPO --title "<title>" --body-file <path>   # prints the URL; the number ends it
gh api repos/REPO/issues/<number> -q .id                            # the id the next calls need
gh api -X POST repos/REPO/issues/ISSUE/sub_issues -F sub_issue_id=<id>
gh api -X POST repos/REPO/issues/<number>/dependencies/blocked_by -F issue_id=<previous phase id>   # from phase 2 on
```

Then post the plan comment with the sub-issue numbers filled in:

```bash
gh issue comment ISSUE --repo REPO --body-file <path>
gh api -X PATCH repos/REPO/issues/comments/<comment id> -F body=@<path>   # instead, when replacing the plan comment
```

Store the issue's URL as `ISSUE_URL`, and delete the local plan file so the repository and the
issue never disagree.

### On failure

If a command fails — issues disabled, sub-issues or dependencies unavailable, insufficient
permissions — report the error and the issues already created, and keep the local plan file.
Never delete an issue to roll back; the user decides what to clean up.

## Picking up a phase (`/build`)

Read `ISSUE` and find its plan comment:

```bash
gh issue view ISSUE --repo REPO --json number,title,url,state,comments
gh api repos/REPO/issues/ISSUE -q .parent_issue_url   # the parent's API URL, or empty
```

- **`ISSUE` is a phase** (it has a parent whose comments hold the plan comment) → that phase
  is the one to build. From here on, `ISSUE` means its parent.
- **`ISSUE` holds the plan comment and has sub-issues** → list them in order and take the
  first open one with no open blocker:

  ```bash
  gh api repos/REPO/issues/ISSUE/sub_issues -q '.[] | "\(.number) \(.state) \(.title)"'
  gh api repos/REPO/issues/<phase>/dependencies/blocked_by -q '[.[] | select(.state == "open")] | length'
  ```

- **`ISSUE` holds the plan comment and has no sub-issues** → build the whole plan.
- **No plan comment** → the issue has not been planned. Suggest `/plan #ISSUE` and stop.

Stop and say why when there is nothing to build: every phase is closed, or every open phase
is blocked by an open issue (name the blockers — usually the previous phase's pull request is
not merged yet). A phase given directly that is closed or blocked stops the same way.

The phase's sub-issue is the unit of work, read with the plan comment for context. Build only
that phase, then ship it as its own pull request. Until the last phase, the ship gate is the
phase's `**Validation:**`, since the plan's success criteria also test the phases after it.
The pull request's body carries `Closes #<phase>` — or
`Closes #ISSUE` for a plan with no phases — and, when this is the last open phase, also
`Closes #ISSUE`. Merging the pull request closes the sub-issue, which is how the phase is
marked done and the next one unblocked.
