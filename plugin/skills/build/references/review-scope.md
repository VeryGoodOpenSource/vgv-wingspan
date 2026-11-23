# Review Scope

How `/build` sizes its final review to the change and tells the review agents what earlier
steps already checked. Run it once, after the surgical-diff gate and before dispatch.

## Step 1: Measure the branch

Diff the whole branch against the merge-base the [surgical-diff gate](surgical-diff-gate.md)
resolved:

```bash
git diff --stat "$BASE"
git diff --name-status "$BASE"
```

Count changed lines as the insertions plus deletions on the last line of `--stat`. Leave out
lockfiles and generated files (mocks, codegen output, `*.g.dart` and equivalents): they grow
with the change without adding anything to review.

## Step 2: Pick the tier

The review is **light** when the change is small and no risk signal fires. Every other change
gets the **full** review.

A change is small when it touches at most **5 files** and at most **150 changed lines**.

Any one of these risk signals makes the review full, whatever the size:

- A dependency manifest or lockfile changed (`pubspec.yaml`, `package.json`, `go.mod`, and
  equivalents).
- The changed source files span more than one package, or more than one directory under the
  source root (`lib/auth/` and `lib/home/`). Test files do not count toward this.
- The change adds a new package, module, or top-level source directory.
- The change touches security-sensitive code: authentication, sessions or tokens,
  permissions, cryptography, payments, secrets, or network and API client configuration.
- The change touches CI, build, or release configuration.

| Tier | Agents |
| ---- | ------ |
| **light** | `vgv-review-agent`, `test-quality-review-agent`, `pr-readiness-review-agent` |
| **full** | All five agents in the skill's table |

Installed companion reviewers run in both tiers: they are the stack's own reviewers.

When the user asks for the full review, run the full review, whatever the change. A request for
a lighter review than these rules pick does not lower the tier: treat it like a request to
skip the review, and keep the review the rules pick.

Record the tier and the reason in one line, such as
`Review scope: light (42 lines, 2 files, no risk signal)` or
`Review scope: full (risk signal: package.json changed)`. It goes in the consolidated
report's header, under the agents line, and in the end-of-run summary. A light review must
never be mistaken for a full one.

## Step 3: Collect what is already gated

Build the **Already gated** note that every review agent receives. It lists only checks that
really ran or will run before the PR opens:

- **Validate**: the commands each phase's Validate step ran and passed, such as the formatter
  check, the analyzer, and the test runner.
- **Ship gate**: the commands the [ship gate](ship-gate.md) runs before push. Phase 4 drives
  them to green, so any problem they catch gets fixed before the PR opens.
- **Merge strategy**: read it from the remote:

  ```bash
  gh repo view --json squashMergeAllowed,mergeCommitAllowed,rebaseMergeAllowed
  ```

  When squash is the only allowed method, the PR lands as a single commit. Without `gh`, read
  it from the project's contributing guide or `CLAUDE.md`. When no source settles it, write
  `unknown`.

Write the note in this shape, and pass it to each agent verbatim:

```markdown
**Already gated** (do not report what these checks cover):
- Validate passed: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test`
- Ship gate runs before push: `flutter analyze && flutter test`
- Merge strategy: squash only. The PR lands as one commit, so commit messages and how the
  work is split across commits do not matter.
```

When the merge strategy is not squash-only, write it as it is (`merge commits allowed`,
`unknown`) and leave out the sentence about commits.
