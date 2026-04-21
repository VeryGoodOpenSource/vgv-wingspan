# 🦄 Contributing to VGV Wingspan

First of all, thank you for taking the time to contribute! 🎉👍 Before you do, please carefully read this guide.

## Getting Started

1. **Fork** the repository and clone your fork locally.
2. Create a new branch from `main` for your work.
3. Open the project in your editor of choice — any text editor works.

## Types of Contributions

| Contribution | Where |
| ------------ | ----- |
| **New skill** | `skills/<skill-name>/SKILL.md` |
| **Improve an existing skill** | Edit the relevant `skills/*/SKILL.md` or `reference.md` |
| **Hooks** | `hooks/` directory |
| **Bug reports & feature requests** | [GitHub Issues](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues) |

## Adding a New Skill

### 1. Create the skill file

Create `skills/<skill-name>/SKILL.md`. The file must begin with YAML frontmatter:

```yaml
---
name: <skill-name>
user-invocable: true
description: When this skill should be triggered — be specific.
argument-hint: "feature or idea to explore"
---
```

| Field | Required | Rules |
| ----- | -------- | ----- |
| `name` | Yes | Lowercase letters, numbers, and hyphens only |
| `user-invocable` | Yes | `true` if the user can invoke this skill directly, `false` otherwise |
| `description` | Yes | Describes when the skill should be triggered |
| `argument-hint` | No | Placeholder hint shown to the user |

After the frontmatter, structure the file as:

1. **H1 title** — human-readable skill name
2. **Core Standards** — enforced constraints, always first
3. **Content sections** — architecture, code examples, workflows, anti-patterns

### 2. Update `plugin.json` tags

Add relevant keywords to the `keywords` array in `.claude-plugin/plugin.json`.

### 3. Update the README skills table

Add a row to the skills table in `README.md`:

```markdown
| **Skill Name** | `/skill-name <args>` | Short description of what the skill covers |
```

## Skill Writing Guidelines

- **Use clear directives** — no soft language ("consider", "prefer"). Say "Use X" or "Do not use Y".
- **Fence all code blocks** with language identifiers (e.g., ` ```dart `).
- **Provide complete, copy-pasteable snippets** — not fragments.
- **Reference packages by full name** (e.g., `package:mocktail`, not just "mocktail").
- **Show anti-patterns alongside correct patterns** when helpful, so readers understand both what to do and what to avoid.
- **Keep prose tight** — every word in a SKILL.md consumes tokens in the model's context window. Verbose instructions reduce the space available for the user's actual work. Apply these techniques:
  - **Decision tables over prose chains** — replace long if/else narratives with a table or compact bulleted list.
  - **One sentence per rule** — if a guideline needs a paragraph to explain, it may be too complex or doing too much.
  - **Cut redundancy** — don't restate in an "Important" footer what the body already says.
  - **Collapse conditional blocks** — when multiple branches share structure, describe the shared part once and list only what differs.

## Shared Resources & Skill Boundaries

### The skill directory boundary

A skill can only reference files inside its own directory. Paths that escape the skill folder (e.g., `../shared/references/foo.md`) will fail validation with a `reference-exists` error. This applies to both markdown reference links and script paths in `!` blocks.

### Sharing content across skills

When multiple skills need the same content (templates, instructions, procedures), store the canonical file in `skills/shared/` and create a **symlink** inside each skill that needs it.

**Directory layout:**

```text
skills/
  shared/
    references/
      validate-and-fix.md          # canonical file
    scripts/
      detect-base-branch.sh        # canonical file
  build/
    references/
      validate-and-fix.md -> ../../shared/references/validate-and-fix.md
    SKILL.md
  hotfix/
    references/
      validate-and-fix.md -> ../../shared/references/validate-and-fix.md
    SKILL.md
```

**Creating a symlink:**

```bash
# From the repo root
ln -s ../../shared/references/validate-and-fix.md skills/build/references/validate-and-fix.md
```

**Referencing in SKILL.md** — always use the local path:

```markdown
Follow the [validation and fix procedure](references/validate-and-fix.md).
```

Never reference `../shared/` directly in a SKILL.md — the symlink makes the shared file appear local.

### Shared scripts

The same boundary rule applies to scripts. Store canonical scripts in `skills/shared/scripts/`, symlink into each skill's `scripts/` directory, and reference them with an absolute path via `${CLAUDE_SKILL_DIR}`.

**Example — adding a shared script to a skill:**

```bash
mkdir -p skills/my-skill/scripts
ln -s ../../shared/scripts/detect-base-branch.sh skills/my-skill/scripts/detect-base-branch.sh
```

**Referencing in SKILL.md** — use `${CLAUDE_SKILL_DIR}` in the skill body (substitutes to an absolute path at skill-load time) and a `*` glob in `allowed-tools` (frontmatter patterns do not substitute variables) to skip the per-invocation permission prompt:

```yaml
---
name: my-skill
allowed-tools: Bash(*/scripts/detect-base-branch.sh)
---
```

````markdown
Run the detection script:

```bash
${CLAUDE_SKILL_DIR}/scripts/detect-base-branch.sh
```
````

Keep scripts executable (`chmod +x`) so they can be invoked directly without a `bash` wrapper. Avoid the fenced `` ```! `` auto-execute form — under stricter permission checks (Claude Code v2.1.98+) it passes the literal block content (including the `!` prefix) to the permission matcher, which no longer aligns with a `Bash(<path>)` pattern.

### When to use scripts vs inline bash

Use a script when the operation is:

- **Deterministic** — no LLM judgment needed, just structured output
- **Reusable** — the same logic appears in 2+ skills
- **Multi-step** — combines several commands with conditional logic

Keep inline bash when:

- It's a single, simple command (e.g., `git rev-parse --abbrev-ref HEAD`)
- The model needs to see the raw output to make a decision
- The command is skill-specific and unlikely to be reused

**Script conventions:**

- Use `#!/usr/bin/env bash` and `set -euo pipefail` — this exits on any error (`-e`), treats unset variables as errors (`-u`), and fails the whole pipeline if any command in a pipe fails (`-o pipefail`). Without it, scripts can silently swallow failures.
- Output structured, parseable text (e.g., `KEY=value` lines)
- Write errors to stderr, data to stdout
- Exit 1 on failure with a descriptive message

## CI Checks

Every pull request runs the following checks automatically:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Markdown lint | Lints all `*.md` files | `config/custom.markdownlint.jsonc` |
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| Skill validation | Validates changed `SKILL.md` frontmatter and structure | `Flash-Brew-Digital/validate-skill@v1` |
| Plugin validation | Validates plugin manifests via Claude Code CLI | `claude plugin validate .` |

If the spelling check flags a legitimate word, add it to `config/cspell.json` in the `words` array.

## Commit Convention

Use [Conventional Commits](https://www.conventionalcommits.org/) with the format:

```text
type(scope): description
```

| Type | When to use | Example |
| ---- | ----------- | ------- |
| `feat` | New skill or feature | `feat: add bloc skill` |
| `fix` | Fix an error or incorrect guidance | `fix: correct GoRouter redirect example` |
| `docs` | Documentation-only change | `docs: add logo to README` |
| `chore` | Maintenance, CI, tooling | `chore: update cspell config` |
| `refactor` | Restructure without changing behavior | `refactor: reorganize testing skill sections` |
| `ci` | CI pipeline changes | `ci: add manifest validation step` |

## Pull Requests

- Branch from `main`.
- Keep PRs focused — **one skill per PR** for new skills.
- Fill out the [PR template](.github/PULL_REQUEST_TEMPLATE.md) completely.
- Ensure all CI checks pass before requesting review.
- Link any related issues in the PR description.
