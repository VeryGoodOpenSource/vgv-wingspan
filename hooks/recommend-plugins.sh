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
# The "detect" field can be a single object or an array of objects (OR logic).
# Each object supports either "file" (exact path) or "files" (shell glob for
# content search — greps inside every matching file for "pattern"):
#   "detect": [
#     { "file": "pubspec.yaml", "pattern": "." },
#     { "files": "docs/plan/*.md", "pattern": "flutter|dart" }
#   ]
#
# All matching recommendations are collected and emitted together in a
# single message. A per-project temp marker (/tmp/wingspan-recommend-plugins-
# <hash>) ensures recommendations are emitted at most once per session.
# Without it, the hook would inject the same context on every matched tool
# call.

INPUT=$(cat)

# Skip if we already ran recommendations for this project in this session.
PROJECT_HASH=$(echo "$PWD" | shasum | cut -d' ' -f1)
MARKER="/tmp/wingspan-recommend-plugins-$PROJECT_HASH"

if [[ -f "$MARKER" ]]; then
  exit 0
fi

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

# Evaluate each recommendation file and collect all matches.
RECOMMENDATIONS=()

for rec_file in "$RECOMMENDATIONS_DIR"/*.json; do
  [[ -f "$rec_file" ]] || continue

  plugin=$(jq -r '.plugin' "$rec_file")
  marketplace=$(jq -r '.marketplace' "$rec_file")
  description=$(jq -r '.description' "$rec_file")

  # Project type detection — supports single object or array of objects (OR logic).
  # Each object can use "file" (exact path) or "files" (shell glob pattern).
  detect_type=$(jq -r '.detect | type' "$rec_file")
  if [[ "$detect_type" == "array" ]]; then
    detect_entries=$(jq -c '.detect[]' "$rec_file")
  else
    detect_entries=$(jq -c '.detect' "$rec_file")
  fi

  matched=false
  while IFS= read -r entry; do
    entry_file=$(echo "$entry" | jq -r '.file // empty')
    entry_files=$(echo "$entry" | jq -r '.files // empty')
    entry_pattern=$(echo "$entry" | jq -r '.pattern')

    if [[ -n "$entry_file" ]]; then
      # Exact file detection
      if [[ -f "$entry_file" ]] && grep -qE "$entry_pattern" "$entry_file" 2>/dev/null; then
        matched=true
        break
      fi
    elif [[ -n "$entry_files" ]]; then
      # Content search — grep inside files matching the glob pattern
      for gf in $entry_files; do
        if [[ -f "$gf" ]] && grep -qiE "$entry_pattern" "$gf" 2>/dev/null; then
          matched=true
          break 2
        fi
      done
    fi
  done <<< "$detect_entries"

  if [[ "$matched" != "true" ]]; then
    continue
  fi

  # Already installed — skip
  if is_plugin_installed "$plugin"; then
    continue
  fi

  # Collect recommendation
  RECOMMENDATIONS+=("The '${plugin}' Claude Code plugin is not installed. It provides: ${description} Recommend the user install it by first adding the marketplace with: /plugin marketplace add ${marketplace} — then installing via: /plugin install ${plugin}")
done

# Emit all recommendations in a single message, then set the marker.
if [[ ${#RECOMMENDATIONS[@]} -gt 0 ]]; then
  touch "$MARKER"
  newline=$'\n'
  message=""
  for rec in "${RECOMMENDATIONS[@]}"; do
    if [[ -n "$message" ]]; then
      message="$message${newline}${newline}$rec"
    else
      message="$rec"
    fi
  done

  jq -n \
    --arg ctx "$message" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
      }
    }'
fi
