#!/bin/bash
# Tests for recommend-plugins.sh
#
# Usage: bash hooks/test_recommend_plugins.sh
#
# Creates a temporary project directory with controlled fixtures and runs
# the hook script in isolation. Each test gets a fresh temp directory and
# a clean marker state so tests don't interfere with each other.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
HOOK_SCRIPT="$SCRIPT_DIR/recommend-plugins.sh"

PASS=0
FAIL=0

# ---------------------------------------------------------------------------
# Helpers
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

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_no_recommendations_dir() {
  echo "test: exits silently when recommendations dir is missing"
  setup
  rm -rf "$RECOMMENDATIONS_DIR"
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when recommendations dir missing"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_no_recommendation_files() {
  echo "test: exits silently when recommendations dir is empty"
  setup
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when no recommendation files"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_file_detection_matches() {
  echo "test: recommends plugin when 'file' detection matches"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "dependencies:
  flutter:
    sdk: flutter"
  local output
  output=$(run_hook)
  assert_contains "$output" "test-plugin" "plugin name in output"
  assert_contains "$output" "additionalContext" "outputs additionalContext JSON"
  assert_contains "$output" "Test plugin." "description in output"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

test_file_detection_no_match_missing_file() {
  echo "test: no recommendation when detected file does not exist"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when file missing"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_file_detection_no_match_pattern() {
  echo "test: no recommendation when file exists but pattern does not match"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "dependencies:
  react: ^18.0.0"
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when pattern does not match"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_files_glob_detection_matches() {
  echo "test: recommends plugin when 'files' glob detection matches"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/plan/*.md", "pattern": "flutter|dart" },
    "marketplace": "Org/repo",
    "description": "Glob plugin."
  }'
  add_project_file "docs/plan/my-plan.md" "We will build a flutter app."
  local output
  output=$(run_hook)
  assert_contains "$output" "test-plugin" "plugin name in output"
  assert_contains "$output" "Glob plugin." "description in output"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

test_files_glob_no_match() {
  echo "test: no recommendation when glob files exist but pattern does not match"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/plan/*.md", "pattern": "flutter|dart" },
    "marketplace": "Org/repo",
    "description": "Glob plugin."
  }'
  add_project_file "docs/plan/my-plan.md" "We will build a react app."
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when glob pattern does not match"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_array_detect_or_logic() {
  echo "test: detect array uses OR logic — matches on second entry"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": [
      { "file": "Gemfile", "pattern": "rails" },
      { "file": "pubspec.yaml", "pattern": "." }
    ],
    "marketplace": "Org/repo",
    "description": "Array detect plugin."
  }'
  # Only the second detect entry matches.
  add_project_file "pubspec.yaml" "name: my_app"
  local output
  output=$(run_hook)
  assert_contains "$output" "test-plugin" "matched via second array entry"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

test_plugin_already_installed_local_settings() {
  echo "test: skips plugin that is already installed (local settings)"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_settings ".claude/settings.local.json" '{"plugins": ["test-plugin"]}'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when plugin already installed"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_plugin_already_installed_project_settings() {
  echo "test: skips plugin that is already installed (project settings)"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_settings ".claude/settings.json" '{"plugins": ["test-plugin"]}'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when plugin in project settings"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_plugin_already_installed_user_settings() {
  echo "test: skips plugin that is already installed (user-level settings)"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  # HOME is overridden to TEST_DIR by setup, so this writes to the path
  # the script checks as $HOME/.claude/settings.json.
  mkdir -p "$TEST_DIR/.claude"
  echo '{"plugins": ["test-plugin"]}' > "$TEST_DIR/.claude/settings.json"
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when plugin in user-level settings"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_files_glob_no_matching_files() {
  echo "test: no recommendation when no files match the glob"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/plan/*.md", "pattern": "flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  # docs/plan/ directory doesn't exist — glob expands to nothing.
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when no files match glob"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_marker_suppresses_second_run() {
  echo "test: marker file suppresses recommendations on second run"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  # First run — should produce output and create marker.
  run_hook > /dev/null
  assert_file_exists "$MARKER" "marker created on first run"
  # Second run — should be suppressed.
  local output
  output=$(run_hook)
  assert_empty "$output" "no output on second run"
  teardown
}

test_multiple_recommendations_single_message() {
  echo "test: multiple matching plugins emitted in a single message"
  setup
  add_recommendation "plugin-a" '{
    "plugin": "plugin-a",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo-a",
    "description": "Plugin A."
  }'
  add_recommendation "plugin-b" '{
    "plugin": "plugin-b",
    "detect": { "file": "package.json", "pattern": "." },
    "marketplace": "Org/repo-b",
    "description": "Plugin B."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "package.json" '{"name": "my-app"}'
  local output
  output=$(run_hook)
  assert_contains "$output" "plugin-a" "first plugin in output"
  assert_contains "$output" "plugin-b" "second plugin in output"
  # Should be a single JSON object, not two.
  local json_count
  json_count=$(echo "$output" | grep -c '"hookSpecificOutput"' || true)
  if [[ "$json_count" -eq 1 ]]; then
    PASS=$((PASS + 1))
    echo "  PASS: single JSON output block"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: expected 1 JSON block, got $json_count"
  fi
  teardown
}

test_mixed_match_and_skip() {
  echo "test: only uninstalled matching plugins are recommended"
  setup
  add_recommendation "installed-plugin" '{
    "plugin": "installed-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo-a",
    "description": "Already installed."
  }'
  add_recommendation "missing-plugin" '{
    "plugin": "missing-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo-b",
    "description": "Not installed."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_settings ".claude/settings.local.json" '{"plugins": ["installed-plugin"]}'
  local output
  output=$(run_hook)
  assert_not_contains "$output" "installed-plugin" "installed plugin excluded"
  assert_contains "$output" "missing-plugin" "uninstalled plugin included"
  teardown
}

test_marketplace_in_output() {
  echo "test: output includes marketplace install instructions"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/my-marketplace",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  local output
  output=$(run_hook)
  assert_contains "$output" "Org/my-marketplace" "marketplace reference in output"
  assert_contains "$output" "/plugin marketplace add" "marketplace add command"
  assert_contains "$output" "/plugin install" "plugin install command"
  teardown
}

test_output_is_valid_json() {
  echo "test: output is valid JSON when recommendations exist"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  local output
  output=$(run_hook)
  if echo "$output" | jq . > /dev/null 2>&1; then
    PASS=$((PASS + 1))
    echo "  PASS: output is valid JSON"
  else
    FAIL=$((FAIL + 1))
    echo "  FAIL: output is not valid JSON"
    echo "    got: $output"
  fi
  teardown
}

test_file_detection_is_case_insensitive() {
  echo "test: 'file' mode grep is case-insensitive"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "pattern": "Flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "pubspec.yaml" "dependencies:
  flutter:
    sdk: flutter"
  local output
  output=$(run_hook)
  assert_contains "$output" "test-plugin" "case-insensitive match on 'file' mode"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

test_files_detection_is_case_insensitive() {
  echo "test: 'files' mode grep is case-insensitive"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/plan/*.md", "pattern": "Flutter" },
    "marketplace": "Org/repo",
    "description": "Test plugin."
  }'
  add_project_file "docs/plan/plan.md" "we use flutter for the app"
  local output
  output=$(run_hook)
  assert_contains "$output" "test-plugin" "case-insensitive match on 'files' mode"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

echo "=== recommend-plugins.sh tests ==="
echo ""

test_no_recommendations_dir
echo ""
test_no_recommendation_files
echo ""
test_file_detection_matches
echo ""
test_file_detection_no_match_missing_file
echo ""
test_file_detection_no_match_pattern
echo ""
test_files_glob_detection_matches
echo ""
test_files_glob_no_match
echo ""
test_array_detect_or_logic
echo ""
test_plugin_already_installed_local_settings
echo ""
test_plugin_already_installed_project_settings
echo ""
test_plugin_already_installed_user_settings
echo ""
test_files_glob_no_matching_files
echo ""
test_marker_suppresses_second_run
echo ""
test_multiple_recommendations_single_message
echo ""
test_mixed_match_and_skip
echo ""
test_marketplace_in_output
echo ""
test_output_is_valid_json
echo ""
test_file_detection_is_case_insensitive
echo ""
test_files_detection_is_case_insensitive
echo ""

echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
