#!/bin/bash
# PreToolUse hook on Task: when a VeryGoodCLI-dependent agent is launched,
# check if very_good_cli >= 1.0.0 is available and inject context.

INPUT=$(cat)

# Only act on Task tool calls targeting VGV CLI-dependent agents
SUBAGENT=$(echo "$INPUT" | jq -r '.tool_input.subagent_type // empty')

case "$SUBAGENT" in
  *vgv-scaffold-agent*)
    # These agents require very_good_cli MCP tools
    ;;
  *)
    # Not a VGV CLI-dependent agent — pass through
    exit 0
    ;;
esac

MIN_VERSION="1.0.0"
MIN_MAJOR=1
MIN_MINOR=0
MIN_PATCH=0

context() {
  jq -n \
    --arg ctx "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        additionalContext: $ctx
      }
    }'
  exit 0
}

deny() {
  jq -n \
    --arg reason "$1" \
    '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $reason
      }
    }'
  exit 0
}

# CLI not installed
if ! command -v very_good &>/dev/null; then
  deny "VeryGoodCLI is not installed. This agent requires VeryGoodCLI MCP tools which need VeryGoodCLI >= ${MIN_VERSION}. Install with: dart pub global activate very_good_cli"
fi

# Parse version (first semver from first line)
RAW=$(very_good --version 2>/dev/null)
VERSION=$(echo "$RAW" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$VERSION" ]; then
  deny "Could not determine VeryGoodCLI version. This agent requires VeryGoodCLI >= ${MIN_VERSION}. Check with: very_good --version"
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# Version too old
if [ "$MAJOR" -lt "$MIN_MAJOR" ] 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -lt "$MIN_MINOR" ]; } 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -eq "$MIN_MINOR" ] && [ "$PATCH" -lt "$MIN_PATCH" ]; } 2>/dev/null; then
  deny "VeryGoodCLI ${VERSION} is too old. This agent requires VeryGoodCLI MCP tools which need >= ${MIN_VERSION}. Update with: dart pub global activate very_good_cli"
fi

# Version OK
exit 0
