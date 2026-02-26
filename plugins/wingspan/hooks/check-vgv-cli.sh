#!/bin/bash
# PreToolUse hook: verify VeryGoodCLI is installed and >= 1.0.0
# Receives tool call JSON on stdin; outputs a permission decision.

MIN_MAJOR=1
MIN_MINOR=0
MIN_PATCH=0

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

if ! command -v very_good &>/dev/null; then
  deny "VeryGoodCLI is not installed. Install it with: dart pub global activate very_good_cli (requires >= ${MIN_MAJOR}.${MIN_MINOR}.${MIN_PATCH})"
fi

VERSION=$(very_good --version 2>/dev/null)

if [ -z "$VERSION" ]; then
  deny "Could not determine VeryGoodCLI version. Run 'very_good --version' to check your installation."
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"
MAJOR=${MAJOR:-0}
MINOR=${MINOR:-0}
PATCH=${PATCH%%[-+]*}  # strip pre-release suffix
PATCH=${PATCH:-0}

if [ "$MAJOR" -lt "$MIN_MAJOR" ] 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -lt "$MIN_MINOR" ]; } 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -eq "$MIN_MINOR" ] && [ "$PATCH" -lt "$MIN_PATCH" ]; } 2>/dev/null; then
  deny "VeryGoodCLI ${VERSION} is too old. Minimum required: ${MIN_MAJOR}.${MIN_MINOR}.${MIN_PATCH}. Update with: dart pub global activate very_good_cli"
fi

# Version OK — allow the tool call
exit 0
