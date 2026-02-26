#!/bin/bash
# SessionStart hook: verify VeryGoodCLI is installed and >= 1.0.0.
# Outputs a warning as additionalContext when the CLI is missing or outdated.
# This runs at plugin load time so the user sees the warning immediately.

MIN_VERSION="1.0.0"
MIN_MAJOR=1
MIN_MINOR=0
MIN_PATCH=0

warn() {
  jq -n \
    --arg ctx "$1" \
    '{ additionalContext: $ctx }'
  exit 0
}

# --- CLI not installed ---
if ! command -v very_good &>/dev/null; then
  warn "VeryGoodCLI is not installed. VeryGoodCLI MCP tools (create, test, packages_get, packages_check_licenses) are unavailable. Install with: dart pub global activate very_good_cli (requires >= ${MIN_VERSION})"
fi

# --- Parse version (first line, first semver match) ---
RAW=$(very_good --version 2>/dev/null)
VERSION=$(echo "$RAW" | head -1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [ -z "$VERSION" ]; then
  warn "Could not determine VeryGoodCLI version. VeryGoodCLI MCP tools may be unavailable. Run 'very_good --version' to check your installation."
fi

IFS='.' read -r MAJOR MINOR PATCH <<< "$VERSION"

# --- Version comparison ---
if [ "$MAJOR" -lt "$MIN_MAJOR" ] 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -lt "$MIN_MINOR" ]; } 2>/dev/null ||
   { [ "$MAJOR" -eq "$MIN_MAJOR" ] && [ "$MINOR" -eq "$MIN_MINOR" ] && [ "$PATCH" -lt "$MIN_PATCH" ]; } 2>/dev/null; then
  warn "VeryGoodCLI ${VERSION} is installed but the MCP server requires >= ${MIN_VERSION}. VeryGoodCLI MCP tools (create, test, packages_get, packages_check_licenses) are unavailable. Update with: dart pub global activate very_good_cli"
fi

# Version OK — no output needed
exit 0
