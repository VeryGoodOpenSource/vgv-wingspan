#!/bin/bash
# Shared helpers for the hook test suites (hooks/test_*.sh).
#
# Source this file; do not run it. It lives in lib/ so the CI loop over
# hooks/test_*.sh never picks it up. It installs no traps and sets no shell
# options: each test file owns its own `set -euo pipefail`.
#
# Usage in a test file:
#   source "$(dirname "${BASH_SOURCE[0]}")/lib/test_helpers.sh"
#   ... define test_* functions, call them ...
#   finish

# Public globals test files may read: SCRIPT_DIR (the hooks/ directory), HOOK_SCRIPT,
# TEST_DIR, MARKER, RECOMMENDATIONS_DIR, PASS, FAIL.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/recommend-plugins.sh"

PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

setup() {
  TEST_DIR=$(mktemp -d)
  RECOMMENDATIONS_DIR="$TEST_DIR/hooks/recommendations"
  mkdir -p "$RECOMMENDATIONS_DIR"

  # Copy hook script so SCRIPT_DIR resolves to the temp hooks/ dir.
  WRAPPER="$TEST_DIR/hooks/recommend-plugins.sh"
  cp "$HOOK_SCRIPT" "$WRAPPER"
  chmod +x "$WRAPPER"

  # Override HOME so the script's $HOME/.claude/settings.json check
  # reads from the test directory instead of the real user home.
  ORIGINAL_HOME="$HOME"
  export HOME="$TEST_DIR"

  # Ensure no stale marker exists for this test dir.
  PROJECT_HASH=$(echo "$TEST_DIR" | shasum | cut -d' ' -f1)
  MARKER="/tmp/wingspan-recommend-plugins-$PROJECT_HASH"
  rm -f "$MARKER"
}

teardown() {
  export HOME="$ORIGINAL_HOME"
  rm -f "$MARKER" 2>/dev/null || true
  rm -rf "$TEST_DIR" 2>/dev/null || true
}

# Run the hook from the test project directory. Captures stdout.
run_hook() {
  echo '{}' | (cd "$TEST_DIR" && bash "$WRAPPER") 2>/dev/null || true
}

# Add a recommendation JSON file to the test fixtures.
add_recommendation() {
  local name="$1"
  local content="$2"
  echo "$content" > "$RECOMMENDATIONS_DIR/$name.json"
}

# Copy a shipped recommendation file into the fixtures.
use_real_recommendation() {
  cp "$SCRIPT_DIR/recommendations/$1.json" "$RECOMMENDATIONS_DIR/$1.json"
}

# Add a settings file relative to the test dir.
add_settings() {
  local path="$1"
  local content="$2"
  mkdir -p "$TEST_DIR/$(dirname "$path")"
  echo "$content" > "$TEST_DIR/$path"
}

# Add a project file relative to the test dir.
add_project_file() {
  local path="$1"
  local content="$2"
  mkdir -p "$TEST_DIR/$(dirname "$path")"
  echo "$content" > "$TEST_DIR/$path"
}

# Remove every project fixture but keep the hook and the settings files, so
# one test can check several fixtures in a row.
reset_project() {
  local entry
  for entry in "$TEST_DIR"/* "$TEST_DIR"/.[!.]*; do
    case "$(basename "$entry")" in
      hooks | .claude) continue ;;
    esac
    [[ -e "$entry" ]] && rm -rf "$entry"
  done
  rm -f "$MARKER"
}

# ---------------------------------------------------------------------------
# Assertions
# ---------------------------------------------------------------------------

assert_contains() {
  local output="$1"
  local expected="$2"
  local msg="$3"
  if echo "$output" | grep -q "$expected"; then
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    expected to contain: $expected"
    echo "    got: $output"
  fi
}

assert_not_contains() {
  local output="$1"
  local unexpected="$2"
  local msg="$3"
  if echo "$output" | grep -q "$unexpected"; then
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    expected NOT to contain: $unexpected"
    echo "    got: $output"
  else
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  fi
}

assert_empty() {
  local output="$1"
  local msg="$2"
  if [[ -z "$output" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    expected empty output, got: $output"
  fi
}

assert_file_exists() {
  local path="$1"
  local msg="$2"
  if [[ -f "$path" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    file does not exist: $path"
  fi
}

assert_file_not_exists() {
  local path="$1"
  local msg="$2"
  if [[ ! -f "$path" ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    file should not exist: $path"
  fi
}

# Assert the output holds exactly one hook JSON block, not one per plugin.
assert_single_json_block() {
  local output="$1"
  local msg="$2"
  local json_count
  json_count=$(echo "$output" | grep -c '"hookSpecificOutput"' || true)
  if [[ "$json_count" -eq 1 ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: $msg"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: $msg"
    echo "    expected 1 JSON block, got $json_count"
  fi
}

# Run the hook on the current fixtures and assert <plugin> is recommended,
# then reset for the next fixture.
assert_recommended() {
  local plugin="$1"
  local msg="$2"
  local output
  output=$(run_hook)
  assert_contains "$output" "The '$plugin' Claude Code plugin" "$msg"
  reset_project
}

# Run the hook on the current fixtures and assert it stays silent, then reset.
assert_silent() {
  local msg="$1"
  local output
  output=$(run_hook)
  assert_empty "$output" "$msg"
  reset_project
}

# Print the results line and exit non-zero when any assertion failed.
finish() {
  echo "=== Results: $PASS passed, $FAIL failed ==="
  if [[ $FAIL -gt 0 ]]; then
    exit 1
  fi
}
