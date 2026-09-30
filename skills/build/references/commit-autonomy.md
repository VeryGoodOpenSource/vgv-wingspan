# Commit Autonomy

Decide once, in Phase 0, how this build commits; carry the choice through the whole run.
Honor a saved preference if one exists. Otherwise use **AskUserQuestion**:

- **Auto-commit each phase (Recommended)** — commit as each phase completes. Pushing and
  opening the PR still pause for approval.
- **I'll commit myself** — build one phase, then stop so the user reviews and commits.
  Nothing is committed or pushed without them.

The choice is a per-developer preference, not a repo convention, so it never belongs in the
project's `CLAUDE.md`.

## Applying it

| Moment | Auto-commit | I'll commit myself |
| ------ | ----------- | ------------------ |
| A phase completes (Phase 2, Step 4) | Stage and commit the phase | Summarize the changed files, leave them staged, stop |
| Review fixes and drive-to-green land (Phase 4) | Commit whatever is still outstanding; skip if nothing is | Summarize everything uncommitted, leave it staged |

Commit message formats:

```text
<type>: <phase name>

<one-line summary of what the phase delivered>
```

```text
<type>: address review findings

<one-line summary of the fixes>
```

`<type>` matches the plan's type (`feat`, `fix`, `refactor`, …). One commit per phase keeps
the branch history clean and each phase independently reviewable; a single-phase plan
produces one implementation commit. Review findings are fixed in place and the report is
deleted at cleanup, so no commit cites `FINDING-NN` ids — there would be no report left to
map them to.

## Pushing

Pushing is outward-facing, so it is gated separately from the commit choice. With a saved
preference to push automatically, push and open the PR without asking. Otherwise use
**AskUserQuestion** before anything leaves the machine:

1. **Review locally first (Recommended)** — stop here; the commits stay local and the user
   opens the PR when ready. Do not call `/create-pr`.
2. **Push and open the PR now** — proceed this once.
3. **Always push automatically** — proceed, and remember the preference for future builds.
