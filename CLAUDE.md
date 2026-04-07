# Wingspan

See [AGENTS.md](AGENTS.md) for project philosophy, workflow, conventions, and guidance.

## Hooks

Wingspan uses Claude Code hooks to automate behavior at tool-call boundaries. Hooks are defined in `hooks/hooks.json`.

### Companion Plugin Recommendations

A `PreToolUse` hook runs on every `Read`, `Glob`, or `Grep` call. It detects the project type and recommends companion plugins the user hasn't installed yet.

**How it works:**

1. `hooks/recommend-plugins.sh` fires on the first matched tool call and scans every JSON file in `hooks/recommendations/`. Each file declares a detection rule and the plugin to recommend.
2. Every file whose detection rule matches — and whose plugin isn't already installed — is collected. All matching recommendations are emitted together in a single `additionalContext` message.
3. A marker file (`/tmp/wingspan-recommend-plugins-<hash>`) is written only when at least one recommendation is emitted, suppressing repeats for the rest of the session. If no plugins are missing, no marker is written and the script re-evaluates on the next tool call — so a newly added recommendation file can still fire later in the same session.

**Recommendation file format** (`hooks/recommendations/<plugin-name>.json`):

```json
{
  "plugin": "plugin-name",
  "detect": { "file": "Gemfile", "pattern": "^\\s*gem\\s+['\"]rails['\"]" },
  "marketplace": "OrgName/repo-name",
  "description": "What the plugin provides."
}
```

| Field             | Purpose                                          |
|-------------------|--------------------------------------------------|
| `plugin`          | Plugin name as registered in the marketplace     |
| `detect.file`     | File whose presence signals the project type     |
| `detect.pattern`  | Regex grep pattern to confirm the match          |
| `marketplace`     | GitHub `owner/repo` for the marketplace registry |
| `description`     | One-line summary shown in the recommendation     |

**Adding a new recommendation:** Drop a JSON file in `hooks/recommendations/` following the format above. No code changes required. All matching files are evaluated.
