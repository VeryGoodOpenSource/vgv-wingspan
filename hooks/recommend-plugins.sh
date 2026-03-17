#!/bin/bash
# PreToolUse hook: recommend companion plugins based on project type.
#
# Scans JSON files in the recommendations/ directory. Each file describes
# a plugin to recommend: how to detect the project type (a file + grep
# pattern) and the plugin name to look for in Claude Code settings.
#
# To add a new recommendation, drop a JSON file in recommendations/ with:
#   {
#     "plugin":      "plugin-name",
#     "detect":      { "file": "Gemfile", "pattern": "^\\s*gem\\s+.rails." },
#     "marketplace": "OrgName/repo-name",   (GitHub owner/repo)
#     "description": "What the plugin provides."
#   }
#
# A per-project temp marker (/tmp/wingspan-recommend-plugins-<hash>) ensures
# recommendations are emitted at most once per session. Without it, the
# hook would inject the same context on every matched tool call.

INPUT=$(cat)

# Skip if we already ran recommendations for this project in this session.
PROJECT_HASH=$(echo "$PWD" | shasum | cut -d' ' -f1)
MARKER="/tmp/wingspan-recommend-plugins-$PROJECT_HASH"

if [[ -f "$MARKER" ]]; then
  exit 0
fi

touch "$MARKER"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RECOMMENDATIONS_DIR="$SCRIPT_DIR/recommendations"

if [[ ! -d "$RECOMMENDATIONS_DIR" ]]; then
  exit 0
fi

# Collect settings files to check (local > project > user).
SETTINGS_FILES=(
  ".claude/settings.local.json"
  ".claude/settings.json"
  "$HOME/.claude/settings.json"
)

is_plugin_installed() {
  local plugin_name="$1"
  for settings_file in "${SETTINGS_FILES[@]}"; do
    if [[ -f "$settings_file" ]] && grep -q "$plugin_name" "$settings_file" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# Evaluate each recommendation file.
for rec_file in "$RECOMMENDATIONS_DIR"/*.json; do
  [[ -f "$rec_file" ]] || continue

  plugin=$(jq -r '.plugin' "$rec_file")
  detect_file=$(jq -r '.detect.file' "$rec_file")
  detect_pattern=$(jq -r '.detect.pattern' "$rec_file")
  marketplace=$(jq -r '.marketplace' "$rec_file")
  description=$(jq -r '.description' "$rec_file")

  # Project type detection
  if [[ ! -f "$detect_file" ]] || ! grep -qE "$detect_pattern" "$detect_file" 2>/dev/null; then
    continue
  fi

  # Already installed — skip
  if is_plugin_installed "$plugin"; then
    continue
  fi

  # Build recommendation message with marketplace-specific install instructions
  message="The '${plugin}' Claude Code plugin is not installed. It provides: ${description} Recommend the user install it by first adding the marketplace with: /plugin marketplace add ${marketplace} — then installing via: /plugin install ${plugin}"

  # Emit recommendation (first match wins, one recommendation per session)
  jq -n \
    --arg ctx "$message" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
      }
    }'
  exit 0
done
