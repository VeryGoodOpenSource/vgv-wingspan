# Recommendation file format

Recommendation files live in `plugins/wingspan/hooks/recommendations/` and describe companion plugins.

## Schema

```json
{
  "plugin": "plugin-name",
  "detect": {
    "file": "pubspec.yaml",
    "pattern": "^\\s*flutter:"
  },
  "create": {
    "keywords": ["flutter", "dart"]
  },
  "marketplace": "OrgName/repo-name",
  "description": "What the plugin provides."
}
```

## Fields

| Field | Required | Purpose |
|-------|----------|---------|
| `plugin` | Yes | Plugin name as registered in Claude Code settings |
| `detect` | No | File-based detection for existing projects (used by recommend-plugins hook) |
| `detect.file` | — | File to check for existence |
| `detect.pattern` | — | Regex pattern to match within the file |
| `create` | No | Creation capabilities (used by `/create` skill) |
| `create.keywords` | — | Terms that indicate this plugin handles the project type |
| `marketplace` | Yes | GitHub `owner/repo` for the plugin marketplace |
| `description` | Yes | Human-readable description of what the plugin provides |

## Adding a new companion plugin

1. Create a JSON file in `recommendations/` (e.g., `my-plugin.json`)
2. Add `detect` for existing-project detection (used by the recommend-plugins hook)
3. Add `create` with keywords for new-project routing (used by the `/create` skill)
4. Both fields are optional — a plugin can support detection, creation, or both
