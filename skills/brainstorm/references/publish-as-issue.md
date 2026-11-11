# Publishing the brainstorm as a GitHub issue

How to move the brainstorm document from `docs/brainstorm/` to a GitHub issue, so the issue
is the one place the team reads it.

## Check GitHub is reachable

Run in parallel:

```bash
gh auth status
gh repo view --json nameWithOwner -q .nameWithOwner
```

Both must succeed. Store the repository as `REPO` (`owner/name`).

If either fails — `gh` missing, not authenticated, or the remote is not GitHub — report the
failing command, keep the local document, and return to the handoff without this option.

## Build the issue

- **Title:** `Brainstorm: <Topic Title>`
- **Body:** the brainstorm document with its YAML frontmatter and its `# <Topic Title>`
  heading dropped, since the issue title carries both. Open the body with a
  `**Date:** YYYY-MM-DD` line, then the template sections unchanged. `/plan` reads them back
  by their headings.

Write the body to a temporary file so the formatting survives the shell.

## Confirm before creating

Creating an issue publishes the brainstorm to the repository's tracker, so never create it
unprompted. Show the proposed title and body, then use **AskUserQuestion**:

**Question:** "Create this issue on `REPO`? The local document is removed once it exists."

**Options:**

1. **Yes** — create it
2. **Edit** — ask what to change, revise, ask again
3. **No** — keep the local document and return to the handoff

## Labels

Apply a `brainstorm` label only if the repository already defines one:

```bash
gh label list --search brainstorm --json name -q '.[].name'
```

If the search returns `brainstorm`, add `--label brainstorm` to the create command. Never
create a new label.

## Create

```bash
gh issue create --repo REPO --title "<title>" --body-file <path> [--label brainstorm]
```

Store the URL it prints as `ISSUE_URL`. Then delete the local brainstorm document, so the
repository and the issue never disagree.

## On failure

If creation fails — issues disabled, insufficient permissions, network error — report the
error and keep the local document. Never discard the brainstorm.
