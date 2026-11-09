# PR CLI Reference

How to detect the available CLI tool for creating pull requests and how to act for each platform.

## Detect

Run in parallel:

```bash
gh --version 2>/dev/null
glab --version 2>/dev/null
```

Store the first available tool as `PR_CLI`. If neither is found, set `PR_CLI` to `none`.

## Check for existing PR

| `PR_CLI` | Command |
| -------- | ------- |
| `gh` | `gh pr view --json url,state 2>/dev/null` |
| `glab` | `glab mr view 2>/dev/null` |
| `none` | Skip. |

If a PR already exists, show its URL and ask the user whether to update the description or stop.

## Create

| `PR_CLI` | Command |
| -------- | ------- |
| `gh` | `gh pr create --title "<title>" --body "<body>" --base <BASE_BRANCH>` |
| `glab` | `glab mr create --title "<title>" --description "<body>" --target-branch <BASE_BRANCH>` |
| `none` | Output the PR title and description as Markdown and instruct the user to open the PR manually on their Git hosting platform targeting `BASE_BRANCH`. |

After creation, output the PR URL.
