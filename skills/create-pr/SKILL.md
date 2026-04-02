---
name: create-pr
description: Stage, commit, push, and open a pull request following project conventions and the Conventional Commits spec. Accepts optional skip-checks argument to bypass validation when called from /build.
argument-hint: "[optional: skip-checks | ticket/issue number e.g. VGV-123 | short description]"
disable-model-invocation: true
---

# Create a pull request

Stage uncommitted changes, commit them, push the branch, and open a pull request on the project's Git hosting platform.

## Steps checklist

- [ ] Step 0: Parse arguments
- [ ] Step 1: Validate (skip if `SKIP_CHECKS`)
- [ ] Step 2: Assess git state and determine base branch
- [ ] Step 3: Stage and commit
- [ ] Step 4: Push
- [ ] Step 5: Run CI checks (skip if `SKIP_CHECKS`)
- [ ] Step 6: Open PR

## Important

- Do not push before the user confirms the commit.
- Use the current branch as the source; target is `BASE_BRANCH` (determined in Step 2).

## When to use

Use this skill when:

- The user asks to open or create a pull request.
- The user asks to "create a PR", "open a PR", "submit a PR", or similar.
- Work on a branch is complete and the user wants to publish it for review.

## Context

<context>$ARGUMENTS</context>

This may include `skip-checks`, a ticket number (e.g. `VGV-123`), a short description, or be empty.

## Step 0: Parse arguments

Check whether the argument contains `skip-checks`. Store as `SKIP_CHECKS` (boolean).

Extract the ticket number or short description from the remaining argument text (if any).

## Step 1: Validate (conditional)

**Skip this step if `SKIP_CHECKS` is true.**

Detect and run the project's formatter, linter, and test runner.

If any command fails, report the error and stop. Do not proceed until all checks pass.

## Step 2: Assess git state and determine base branch

Run in parallel:

```bash
git branch --show-current
git status --short
git diff --cached
git diff
```

- If the branch is `main` or `master`, warn the user and stop.
- If there are no staged or unstaged changes:
  - Run `git log <BASE_BRANCH>..HEAD --oneline`. If there are no commits ahead of `BASE_BRANCH`, inform the user there is nothing to commit or push, and stop.
  - Otherwise, inform the user there is nothing new to commit and skip to Step 5.

### Determine base branch

Use **AskUserQuestion**:

**Question:** "Which branch should this PR target?"

**Options:**
1. `main` (default)
2. `develop`
3. Other — let the user type a custom branch name

Store as `BASE_BRANCH`.

## Step 3: Stage and commit

Use the **create-commit** skill with the `single-commit` argument to stage files and produce a single conventional commit message.

## Step 4: Push

Consult `references/push.md` to push the branch and handle any failures.

## Step 5: Run CI checks (conditional)

**Skip this step if `SKIP_CHECKS` is true.**

Consult `references/ci-checks.md` to discover and run checks locally from `.github/workflows/ci.yaml`.

If any check fails, report the errors and stop. Do not proceed until all checks pass.

## Step 6: Open PR

### Gather commit context

Run in parallel:

```bash
git log <BASE_BRANCH>..HEAD --oneline
git log <BASE_BRANCH>..HEAD --format="%s%n%b"
git diff <BASE_BRANCH>..HEAD --stat
```

Extract the ticket number from the branch name (e.g. `feat/VGV-59-...` → `VGV-59`) or from the argument.

### PR title

Follow Conventional Commits summarizing the overall change:

`type(scope): short description`

- Max 72 characters. Imperative mood, no period, no capital after colon.

### PR description

Check for a template:

```bash
cat .github/PULL_REQUEST_TEMPLATE.md 2>/dev/null
```

- **Template exists**: use it as structure; strip HTML comments; pre-fill the **Type of Change** section by checking the checkbox matching the commit type:
  - `feat` → ✨ New feature
  - `fix` → 🛠️ Bug fix
  - `refactor` → ♻️ Refactor
  - `docs` → 📝 Documentation
  - `test` → 🧪 Tests
  - `chore`/`build`/`ci` → 🔧 Maintenance
- **No template**: consult `references/pull-request-template.md` for the default template and filling rules.

Output the proposed PR:

````markdown
## Proposed PR

**Title:** `type(scope): short description`

**Description:**

...
````

### Confirm and create

Use **AskUserQuestion**:

**Question:** "Do you want me to create this PR?"

**Options:**
1. **Yes** — consult `references/pr-cli.md` to detect the available CLI tool, check for an existing PR, and create it.
2. **No** — stop; the Markdown above is ready for manual use.
3. **Edit** — ask what to change, revise, ask again.
