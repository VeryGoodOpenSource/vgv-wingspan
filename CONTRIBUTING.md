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

## Cross-harness portability

Skills are authored for Claude Code but target the [Agent Skills open
standard](https://agentskills.io/specification) (the skills.sh / `npx skills`
format, supported by 70+ agents). Under that standard a skill is a **static
instruction set**: the agent loads it by matching its `description`, then reads
the body — there is no argument or template substitution. `$ARGUMENTS` and
`${CLAUDE_SKILL_DIR}` are Claude Code conveniences, not spec features, so a body
that uses them must still work when they arrive unsubstituted.

**`$ARGUMENTS`** — not a spec concept; on a plain Agent Skill it is never
substituted and stays literal. Always pair it with a fallback that fires when it
is empty *or still shows the literal text* `$ARGUMENTS`:

```markdown
<feature_description>$ARGUMENTS</feature_description>

**If the feature description above is empty or still shows the literal text
`$ARGUMENTS` (the host did not substitute it), ask the user** for it (or read it
from the conversation).
```

**`${CLAUDE_SKILL_DIR}`** — the spec references bundled files by **relative path
from the skill root** (`scripts/x.sh`), one level deep. Prefer that form. Claude
Code needs the absolute `${CLAUDE_SKILL_DIR}` only to match the `allowed-tools`
permission pattern and resolve outside the skill's directory, so keep it as the
primary form but add the relative-path fallback. See the `rebase` and `review`
skills.

**Frontmatter** — an agent silently skips a skill whose frontmatter is malformed.
Keep the opening `---` on line 1, close the block with `---`, and include a
non-empty `name:` (kebab-case, **matching the directory name**) and
`description:`. The spec also allows `license`, `compatibility`, `metadata`, and
`allowed-tools`. Claude Code extras (`when_to_use`, `user-invocable`,
`disable-model-invocation`, `effort`, `argument-hint`) are not spec fields, but
`npx skills` and other agents ignore unknown frontmatter — keep them top-level so
Claude Code reads them and nothing else breaks. (The spec's optional `skills-ref`
linter is stricter; skills.sh does not run it.) The `Skill validation` CI job
(`Flash-Brew-Digital/validate-skill@v1`) enforces the spec (incl.
name-matches-directory) across every skill on each pull request.

**MCP references** — MCP servers (only `context7` today) are optional. A skill or
agent that uses one must skip it silently and fall back to a built-in path (e.g.
web search) when the server is not connected. Never block on an MCP server.

**Subagents** — subagents are not part of the Agent Skills standard. A skill that
dispatches one (`Task @<agent>(...)`) must pair the dispatch with a fallback so the
step still runs on an agent without subagents — see the "no subagent mechanism?"
notes in `build`, `review`, `hotfix`, `plan`, `brainstorm`, and the shared
`plan-review`. Keep the `Task @<agent>` line intact (Claude Code uses it); the
fallback is additive.

**Reserved slash-command names** — a few skill names collide with host built-in slash
commands: `review` shadows a built-in `/review` on Codex and GitHub Copilot. On the Agent
Skills standard skills activate by **description**, not by a typed slash command, so the
collision only bites hosts that also expose skills as slash commands, and only the typed
form — description-activation still reaches the skill. Do not rename to dodge the collision:
the bare name is the Claude Code command and the spec ties `name` to the directory. Instead
the affected skill carries an in-body cross-harness note telling the user to invoke it by
request (or the host's namespaced form) where the bare command is shadowed.

**Shared content via symlinks** — references and scripts are symlinked into each
skill for DRY. `npx skills` dereferences symlinks when it copies a cloned/local
skill (`cp` with `dereference: true`), so those install paths work as-is. The
default GitHub install instead pulls a server-side snapshot from
`skills.sh/api/download`, whose handling of relative symlinks pointing outside the
skill (`../../shared/…`) is not documented. Before relying on skills.sh, verify
with a real `npx skills add github:VeryGoodOpenSource/vgv-wingspan` that the shared
files arrive intact. If they do not, materialize them (dereference the symlinks
into real files at publish time, or vendor real copies) — no need to do it before
that check confirms it.

## Testing Locally

Editing a skill or hook and pushing straight to a PR only tells you the files
are valid, not that they work correctly. Load your working copy into a real Claude Code
session and exercise it before you commit.

### Prerequisites

- **Claude Code CLI** installed (`npm install -g @anthropic-ai/claude-code`).
- **jq** on your `PATH` — the recommendation hook needs it and skips silently without it.

### Load your local copy

From the repository root, launch Claude Code pointed at this directory:

```bash
claude --plugin-dir .
```

`--plugin-dir` loads the plugin for that session only, needs no install or
marketplace, and overrides any marketplace-installed copy of the same plugin.
`${CLAUDE_PLUGIN_ROOT}` (used in `hooks/hooks.json`) resolves to the directory
you pass, so the hook script paths resolve correctly.

### Verify each component loaded

| Component | How to verify |
| --------- | ------------- |
| **Skills** | Run `/help`. Skills appear namespaced as `/vgv-wingspan:<skill>` (e.g. `/vgv-wingspan:brainstorm`). Invoke one to confirm it triggers. |
| **Agents** | Ask Claude to run one by name (e.g. "review this with the vgv-review-agent") and confirm it dispatches. |
| **Hooks** | In a project with a detectable type (e.g. a Flutter app), have Claude `Read` a file and confirm the plugin recommendation fires. |

The recommendation hook writes a marker file (`/tmp/wingspan-recommend-plugins-<hash>`)
after it emits a recommendation, suppressing repeats for the session. Delete the
marker to re-test:

```bash
rm -f /tmp/wingspan-recommend-plugins-*
```

### Iterate on changes

After editing a `SKILL.md` or `hooks/hooks.json`, **restart the
`claude --plugin-dir .` session** to guarantee the change is picked up. Changes
to `.claude-plugin/plugin.json` always require a restart. Edits to the hook
`.sh` scripts take effect on the next matching tool call with no restart, since
each hook runs the script fresh.

### Rehearse the real install (optional)

To mimic the marketplace install flow without pushing anything, register a
throwaway local marketplace. Create `.claude-plugin/marketplace.json` in a temp
directory with an **absolute** path to this repo:

```jsonc
// /tmp/vgv-test-marketplace/.claude-plugin/marketplace.json
{
  "plugins": [
    {
      "name": "vgv-wingspan",
      "source": {
        "type": "directory",
        "path": "/ABSOLUTE/path/to/wingspan"
      }
    }
  ]
}
```

Then, inside a session:

```text
/plugin marketplace add /tmp/vgv-test-marketplace
/plugin install vgv-wingspan
```

### Validate before you push

Run the same checks CI runs, from the repository root:

```bash
claude plugin validate .
```

```bash
bash scripts/ci/check-frontmatter.sh
```

The first validates the manifest, skill frontmatter, hook JSON, and file
references. The second is the frontmatter guard (BOM + agent frontmatter).
Both are static, so they confirm structure but do not replace the live checks
above.

### Troubleshooting

| Symptom | Likely cause | Fix |
| ------- | ------------ | --- |
| Skill missing from `/help` | Invalid frontmatter | Run `claude plugin validate .` and fix the reported error |
| Hook never fires | `jq` not installed, marker file left over, or script lacks `+x` / a shebang | Install `jq`; remove the `/tmp/wingspan-recommend-plugins-*` marker; `chmod +x` the script |
| Skill references a shared file that 404s | Symlink missing or points outside the skill directory | Recreate the symlink per [Sharing content across skills](#sharing-content-across-skills) |
| `${CLAUDE_PLUGIN_ROOT}` not resolving | Session not launched via `--plugin-dir` (or restart pending) | Restart with `claude --plugin-dir .` from the repo root |
| Local marketplace won't install | `source.path` is relative | Use an absolute path in `marketplace.json` |

## CI Checks

Every pull request runs the following checks automatically:

| Check | What it does | Config |
| ----- | ------------ | ------ |
| Markdown lint | Lints all `*.md` files | `config/custom.markdownlint.jsonc` |
| Spelling | Runs cspell on all `*.md` files | `config/cspell.json` |
| Skill validation | Validates **every** `SKILL.md`'s frontmatter and structure against the Agent Skills spec, so a malformed skill fails the build instead of silently vanishing on another host | `Flash-Brew-Digital/validate-skill@v1` |
| Frontmatter guard | Fails on a UTF-8 BOM in any `SKILL.md` or agent file (Gemini-fatal, passes validate-skill) and validates `agents/**/*.md` frontmatter, which no other check covers | `scripts/ci/check-frontmatter.sh` |
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
