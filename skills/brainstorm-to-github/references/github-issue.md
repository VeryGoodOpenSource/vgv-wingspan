# Publishing the brainstorm as a GitHub issue

How to turn the brainstorm document into a GitHub issue on `REPO`.

## Build the issue

- **Title:** `Brainstorm: <Topic Title>`
- **Body:** the [brainstorm template](template.md) content with two adjustments — drop the YAML frontmatter and drop the `# <Topic Title>` heading, since the issue title carries both. Open the body with a `**Date:** YYYY-MM-DD` line, then the template sections unchanged.

Write the body to a temporary file so the formatting survives the shell.

## Confirm before creating

Creating an issue publishes the brainstorm to the repository's tracker, so never create it unprompted. Show the proposed title and body, then use **AskUserQuestion**:

**Question:** "Do you want me to create this issue on `REPO`?"

**Options:**
1. **Yes** — create it
2. **No** — stop; the Markdown above is ready for manual use
3. **Edit** — ask what to change, revise, ask again

## Labels

Apply a `brainstorm` label only if the repository already defines one:

```bash
gh label list --search brainstorm --json name -q '.[].name'
```

If the search returns `brainstorm`, append `--label brainstorm` to the create command. Never create a new label.

## Create

```bash
gh issue create --title "<title>" --body-file <path> [--label brainstorm]
```

Output the issue URL and store it as `ISSUE_URL`.

## On failure

If creation fails — issues disabled, insufficient permissions, network error — report the error and offer to fall back to `/brainstorm`'s file output instead. Never discard the document.
