# Agent-definition conversion spec

Defines how Wingspan's 10 agent definitions (`agents/**/*.md`, Claude Code
format) convert to the three tier-2 harness formats. The **canonical source
stays `agents/**/*.md` exactly as Claude Code consumes it** — frontmatter
`<examples>` blocks and the `skills:` field drive tier-1 delegation and are
not removed. Converters implement this spec in
[#226](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/226) (Codex),
[#227](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/227) (Gemini
CLI), and
[#229](https://github.com/VeryGoodOpenSource/vgv-wingspan/issues/229)
(OpenCode). Format facts verified against host docs/source on **2026-07-24**.

## Target formats

| | Codex CLI | Gemini CLI | OpenCode |
|---|---|---|---|
| File | one TOML per agent | Markdown + YAML frontmatter | Markdown + YAML frontmatter |
| Location (project) | `.codex/agents/` | `.gemini/agents/` | `.opencode/agents/` |
| Location (user) | `~/.codex/agents/` | `~/.gemini/agents/` | `~/.config/opencode/agents/` |
| Identity | `name` field | `name` field (slug) | filename stem |
| System prompt | `developer_instructions` | body | body |
| Invocation | `/agent`, `spawn_agent` tools, or delegation | auto-delegation or `@agent-name` | Task tool or `@mention` |
| Docs | learn.chatgpt.com/docs/agent-configuration/subagents | geminicli.com/docs/core/subagents/ | opencode.ai/docs/agents/ |

## Field dispositions

| Source field | Codex TOML | Gemini md | OpenCode md |
|---|---|---|---|
| `name` | `name` | `name` | filename stem (drop the field) |
| `description` — plain one-liner (4 agents) | `description` | `description` | `description` |
| `description` — block scalar with `<examples>` XML (6 agents) | first paragraph → `description`; `<examples>` block appended to the end of `developer_instructions` under a "Delegation examples" heading | same split: prose → `description`, examples → end of body | same split |
| body | `developer_instructions` (TOML multi-line string) | body | body |
| `model: sonnet` | concrete model id chosen by the converter config (no alias support) | omit (session default) or concrete Gemini model | omit or concrete `provider/model` string |
| `model: haiku` | small-tier model id from converter config | same as above | same as above |
| `model: inherit` | omit the field | omit | omit |
| `effort: medium` (3 agents) | `model_reasoning_effort = "medium"` | **drop** — no equivalent | **drop** — no equivalent |
| `skills: [elements-of-style]` (6 agents) | `skills.config` (Codex supports skill wiring) | **drop field**, prepend one line to the body: "Write findings in clear, vigorous English — active voice, omit needless words." | same as Gemini |
| — (absent in source) | — | — | **add `mode: subagent`** (required to keep it out of the primary-agent rotation) |

Notes:

- All 10 agent names are unique, so flattening the nested
  `agents/{analysis,codebase-review,quality-review,research}/` directories
  into the hosts' flat agent dirs is collision-free. Converters must recurse
  (`agents/**/*.md`), not glob one level.
- Gemini defaults worth pinning in converted output: `max_turns` (default
  30) and `timeout_mins` (default 10) are fine for all 10 agents; do not
  emit them unless a specific agent needs more.
- No source agent declares `tools:`. Codex has no tools field (use
  `sandbox_mode` if restriction is wanted); Gemini `tools:` and OpenCode
  `permission:` allowlists may be added per host later — not part of this
  conversion.
- Intentional source inconsistencies — do **not** "fix" during conversion:
  `effort: medium` appears on only 3 of the 6 `model: sonnet` agents
  (deliberate: bounded reasoning where review depth is capped);
  `codebase-review-agent` has no Output Instructions section (it is a
  context-gathering agent, not a findings reporter).

## Body rewrites (conversion-time, per host)

Claude-isms cluster in exactly two copy-pasted blocks plus one agent's tool
mentions. Converters rewrite these; the canonical source keeps them.

| Construct | Where | Rewrite |
|---|---|---|
| Companion-plugin discovery block ("check your available-skills list… load with the **Skill tool**… glob `.claude/skills/**/SKILL.md`") | 5 review agents (`vgv-review`, `architecture-review`, `test-quality-review`, `code-simplicity-review`, `codebase-review`) | Generalize: "check the skills available in this environment and load relevant ones"; replace the `.claude/skills` glob with the host's skill dirs (`.agents/skills/**/SKILL.md` plus host-native dirs) |
| Context7 MCP block | 2 research agents (`best-practices-research`, `official-docs-research`) | Keep — already phrased "when available / fall back to web search"; all three hosts support MCP, so the reference degrades correctly as written |
| `Grep`/`Glob`/`Read` tool names ("uses ripgrep under the hood") | `codebase-review-agent` Search Strategies section | Replace with host tool names or neutral phrasing ("your file-search tool") |
| `CLAUDE.md` mentions | review + research agents | `AGENTS.md` (Codex, OpenCode) / `GEMINI.md` (Gemini CLI) |

Invocation mapping for the calling skills (`Task @<agent>(...)` syntax):
Codex delegates via the `spawn_agent`/`wait_agent` tool family; Gemini via
auto-delegation or `@agent-name`; OpenCode via the Task tool or `@mention`.
The skills layer already carries a "No subagent mechanism?" sequential-pass
fallback for hosts without any of these, so skill bodies need no further
change.

## Worked example: `plan-splitting-agent`

Hardest case: block-scalar description with `<examples>`, `model: sonnet`,
`effort: medium`. Source: `agents/analysis/plan-splitting-agent.md`.

### Codex (`.codex/agents/plan-splitting-agent.toml`)

```toml
name = "plan-splitting-agent"
description = "Analyzes implementation plans for scope and recommends splitting large plans into multiple independently-mergeable PRs. Use during plan creation and technical review to catch oversized plans before development begins."
model = "gpt-5.4"            # converter config decides; source alias was `sonnet`
model_reasoning_effort = "medium"
developer_instructions = """
# Plan Splitting Agent

You are a plan scope analyst at Very Good Ventures. Your role is to assess
whether an implementation plan is too large for a single reviewable PR...
[full body of agents/analysis/plan-splitting-agent.md]

## Delegation examples

[content of the <examples> block, converted to plain prose]
"""
```

### Gemini CLI (`.gemini/agents/plan-splitting-agent.md`)

```markdown
---
name: plan-splitting-agent
description: Analyzes implementation plans for scope and recommends splitting large plans into multiple independently-mergeable PRs. Use during plan creation and technical review to catch oversized plans before development begins.
---
# Plan Splitting Agent

You are a plan scope analyst at Very Good Ventures. ...
[full body]

## Delegation examples

[<examples> content as prose]
```

(`model` omitted → session default; `effort` dropped — no equivalent.)

### OpenCode (`.opencode/agents/plan-splitting-agent.md`)

```markdown
---
description: Analyzes implementation plans for scope and recommends splitting large plans into multiple independently-mergeable PRs. Use during plan creation and technical review to catch oversized plans before development begins.
mode: subagent
---
# Plan Splitting Agent

You are a plan scope analyst at Very Good Ventures. ...
[full body]

## Delegation examples

[<examples> content as prose]
```

(Name comes from the filename stem; `mode: subagent` keeps it out of the
Tab-cycled primary rotation.)

## Acceptance for the converter issues

A converter is done when: every `agents/**/*.md` produces one output file per
host with all field dispositions above applied; the worked example above
round-trips byte-for-byte in structure (modulo the converter's model-id
config); and converted files parse in the target host (Gemini and OpenCode
silently skip agents with malformed frontmatter — validate in CI per host).
