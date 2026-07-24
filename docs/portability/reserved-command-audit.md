# Reserved-command collision audit

Audit of Wingspan skill names against the built-in commands of the harnesses
targeted by epic [#66](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/66):
Claude Code (tier 1), Codex CLI, Gemini CLI, and OpenCode (tier 2). Findings
were verified against each host's source code or first-party docs on
**2026-07-24** — these hosts move fast, so re-check citations before acting on
this audit in a future phase.

## Decision rule

A skill is **renamed** when its bare name is shadowed by a built-in slash
command on **Claude Code (tier 1)** — there, a shadowed skill's slash form
silently runs the built-in instead, with no error.

Tier-2-only shadowing is **accepted and documented** as degradation: tier-2
invocation is model-driven or disambiguated by the host (Codex `$`-mention,
Gemini numeric suffix, OpenCode `skill` tool), so a rename there buys little
for its blast radius. Prefer a descriptive rename over a `vgv-` prefix; use
the prefix only when no good descriptive name exists.

## Per-host built-in commands

### Claude Code (tier 1)

Built-in `/review` exists (GitHub PR review; docs:
<https://code.claude.com/docs/en/commands>). Inside the plugin, skills are
namespaced (`plugin-name:skill-name`, "so they cannot conflict with other
levels"), which hides bare-name collisions — but a flat publish (skills.sh
install into `.claude/skills/`) exposes them: users can type any skill as
`/<skill-name>` by default (docs: <https://code.claude.com/docs/en/skills>).

Precedence nuance: the docs guarantee a custom skill overrides a same-named
**bundled skill** (their own example: `code-review`), but `/review` is a
**built-in command**, and custom-vs-built-in-command precedence is
undocumented. Best available evidence
(<https://github.com/anthropics/claude-code/issues/33080>, closed
not-planned): the built-in silently wins and displaces the custom skill —
including its model-invocation path. An undocumented, historically buggy
collision surface is exactly what a published skill must not sit on.

### Codex CLI

Built-ins (docs: <https://learn.chatgpt.com/docs/developer-commands?surface=cli>;
source: `codex-rs/tui/src/slash_command.rs`): `/model`, `/review`, `/plan`,
`/init`, `/compact`, `/agent` (`/subagents`), `/skills`, `/hooks`, `/import`,
`/new`, `/resume`, `/diff`, `/status`, `/mcp`, `/quit` and ~35 more.

Skills are **never slash commands** on Codex — they are invoked by `$`-mention
(`$plan …`), the `/skills` browser, or implicit description match (docs:
<https://learn.chatgpt.com/docs/build-skills>). A skill named `plan` or
`review` coexists with the built-in; `/`-typed input always hits the built-in.

### Gemini CLI

Built-ins (docs: <https://geminicli.com/docs/reference/commands/>): `/about`,
`/agents`, `/chat`, `/clear`, `/compress`, `/init`, `/mcp`, `/memory`,
`/model`, `/plan`, `/skills`, `/hooks`, `/stats`, `/tools`, `/vim` and ~23
more. **No built-in `/review`.**

Skills are slash-invocable (`/<skill-name>`) since March 2026. On collision
with a built-in, the built-in keeps its name and the user/workspace skill gets
a numeric suffix — a skill named `plan` surfaces as `/plan1` (source:
`packages/cli/src/services/SlashCommandResolver.ts`; extension-shipped skills
instead get an `<extension>:` prefix).

### OpenCode

Built-in TUI commands (docs: <https://opencode.ai/docs/tui/>): `/help`,
`/init`, `/new`, `/sessions`, `/share`, `/models`, `/themes`, `/compact`,
`/undo`, `/redo`, `/editor`, `/export`, `/exit` and aliases. **None of
Wingspan's names collide.** Skills, commands, and agents are separate
namespaces; the built-in `build` and `plan` **primary agents** do not shadow
skills of the same name (docs: <https://opencode.ai/docs/skills/>,
<https://opencode.ai/docs/agents/>).

## Per-skill verdict

| Skill | Claude Code | Codex | Gemini CLI | OpenCode | Verdict |
|---|---|---|---|---|---|
| `review` | **shadowed** (`/review` built-in) | shadowed (`/review`) | clear | clear | **Renamed → `quality-review`** (PR #220 precedent; GitHub Copilot's built-in `/review` was the original trigger) |
| `plan` | clear | shadowed (`/plan` = Plan mode) | shadowed (`/plan` = Plan Mode; skill → `/plan1`) | clear (agent namespace separate) | Keep — tier-2 degradation documented |
| `build` | clear | clear | clear | clear (agent namespace separate) | Keep |
| `create` | clear | clear | clear | clear | Keep |
| `brainstorm`, `create-pr`, `debrief`, `hotfix`, `rebase`, `refine-approach`, `plan-technical-review`, `elements-of-style` | clear | clear | clear | clear | Keep |

Naming note: after the rename, `quality-review` names both the standalone
skill and the `agents/quality-review/` agent group (architecture,
pr-readiness, test-quality agents). No technical collision — different
namespaces — but docs should not conflate the skill with that agent subset.

## Cross-plugin audit (`vgv-ai-flutter-plugin`)

Wingspan skills: `brainstorm`, `build`, `create`, `create-pr`, `debrief`,
`elements-of-style`, `hotfix`, `plan`, `plan-technical-review`,
`quality-review`, `rebase`, `refine-approach`.

Companion plugin skills: `accessibility`, `animations`, `bloc`,
`create-project`, `dart-flutter-sdk-upgrade`, `green-gate`,
`internationalization`, `layered-architecture`, `license-compliance`,
`material-theming`, `navigation`, `static-security`, `testing`, `ui-package`,
`very-good-analysis-upgrade`.

**Disjoint — no collisions.** Closest pair is `create` vs `create-project`
(distinct names, distinct purposes: routing vs scaffolding).

## Frontmatter extras tolerance (source-verified)

Wingspan's Claude Code extras (`when_to_use`, `user-invocable`,
`disable-model-invocation`, `effort`, `argument-hint`) are ignored — not
fatal — on all three tier-2 hosts:

- **Codex**: `SkillFrontmatter` serde struct has no `deny_unknown_fields`;
  only `name`, `description`, `metadata.short-description` are read
  (`codex-rs/core-skills/src/loader.rs`).
- **Gemini CLI**: loader extracts only `name` and `description`; everything
  else is discarded (`packages/core/src/skills/skillLoader.ts`).
- **OpenCode**: "Unknown frontmatter fields are ignored" (verbatim,
  <https://opencode.ai/docs/skills/>).

Fatal cases to guard instead: missing/empty `description` (all three),
frontmatter not first in file / malformed `---` (all three), and a UTF-8 BOM
before the opening `---` (Gemini-fatal, passes `validate-skill` — covered by
`scripts/ci/check-frontmatter.sh`).

## Out of scope for this phase

Hooks portability: Codex hooks are wire-compatible with Claude Code's
JSON-over-stdin events; Gemini CLI uses different event names
(`BeforeTool` vs `PreToolUse`) with a `gemini hooks migrate` converter;
OpenCode requires a JS/TS plugin rewrite. Handled per host in
[#226](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/226)/[#227](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/227)/[#229](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/229).
