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

## Find the issue template

Look for the repository's issue templates: `.github/ISSUE_TEMPLATE/*.md`, `*.yml` and
`*.yaml` (issue forms), and `.github/ISSUE_TEMPLATE.md`. Skip `config.yml`.

- **None** → build the issue without a template, as below.
- **One fits new work** (a feature request or similar) → use it.
- **Several could fit** → **AskUserQuestion** with the candidates by their `name`.

## Build the issue

Strip the brainstorm document's YAML frontmatter and its `# <Topic Title>` heading, since
the issue title carries both. Keep its four section headings — `## What We're Building`,
`## Why This Approach`, `## Key Decisions`, `## Open Questions` — word for word. `/plan`
reads the issue back by those headings.

**Without a template:**

- **Title:** `Brainstorm: <Topic Title>`
- **Body:** a `**Date:** YYYY-MM-DD` line, then the brainstorm sections unchanged.

**With a template:**

- **Title:** the template's `title` prefix, if it has one, then `<Topic Title>`.
- **Labels:** the template's `labels`.
- **Body:** follow the template's structure. For an issue form, write each field as a
  `### <label>` heading, the way GitHub renders a submitted form. For a Markdown template,
  keep its headings and drop its HTML comments.
- Fill every required field from the brainstorm. Leave out optional fields the brainstorm
  says nothing about.
- Place each brainstorm section under the field that fits it best, keeping its heading.
  Never reword a section to fit a field.

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

If the search returns `brainstorm`, add it to the template's labels. Never create a new
label.

## Create

```bash
gh issue create --repo REPO --title "<title>" --body-file <path> [--label <label>]...
```

Store the URL it prints as `ISSUE_URL`. Then delete the local brainstorm document, so the
repository and the issue never disagree.

## On failure

If creation fails — issues disabled, insufficient permissions, network error — report the
error and keep the local document. Never discard the brainstorm.
