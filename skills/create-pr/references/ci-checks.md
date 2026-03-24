# CI Checks Reference

How to discover and run CI checks locally before opening a PR.

## Discover checks

Read `.github/workflows/ci.yaml` from the project root:

```bash
cat .github/workflows/ci.yaml 2>/dev/null
```

If the file does not exist, skip CI checks entirely.

## Scope to changed files

Run checks only on files changed relative to `BASE_BRANCH`:

```bash
git diff <BASE_BRANCH>...HEAD --name-only
```

Filter the changed file list to match the glob pattern each check uses.

## Translate jobs to local commands

For each job in the workflow, map its steps to a local equivalent:

| CI step | Local command |
| ------- | ------------- |
| `DavidAnson/markdownlint-cli2-action` | `npx markdownlint-cli2 --config <config> <files>` |
| `streetsidesoftware/cspell-action` | `npx cspell --config <config> <files>` |
| `run:` step | Run the script as-is |

Use the `with:` block values (`config`, `globs`, `files`) from the action to fill in the command arguments.

## Run

Run all discovered checks in parallel. If any fails, report the errors and stop.
