#!/bin/bash
# Tests for recommend-plugins.sh
#
# Usage: bash hooks/test_recommend_plugins.sh
#
# Creates a temporary project directory with controlled fixtures and runs
# the hook script in isolation. Each test gets a fresh temp directory and
# a clean marker state so tests don't interfere with each other.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/test_helpers.sh"

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
  assert_single_json_block "$output" "single JSON output block"
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

test_dir_include_matches() {
  echo "test: 'dir' + 'include' finds a match at any depth under dir"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "include": "*.kt *.java", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  add_project_file "src/a/b/c/d/e/f/Bridge.java" "class Bridge { NativeBridge b; }"
  assert_recommended "test-plugin" "match in a .java file seven levels deep"
  add_project_file "src/Bridge.kt" "class Bridge(val b: NativeBridge)"
  assert_recommended "test-plugin" "match in a .kt file directly under dir"
  teardown
}

test_dir_include_no_match() {
  echo "test: 'dir' + 'include' is silent when no included file matches"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "include": "*.kt *.java", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  add_project_file "src/a/Other.kt" "class Other"
  assert_silent "files exist but the pattern does not match"
  add_project_file "src/a/Bridge.txt" "NativeBridge"
  assert_silent "pattern matches only in a file the include glob excludes"
  teardown
}

test_dir_include_missing_dir() {
  echo "test: 'dir' + 'include' is silent when dir does not exist"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "include": "*.kt", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  assert_silent "no output when dir is missing"
  # A file named like the dir is not a directory.
  add_project_file "src" "NativeBridge"
  assert_silent "no output when dir is a regular file"
  teardown
}

test_dir_include_absent() {
  echo "test: 'dir' without 'include' matches nothing"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  add_project_file "src/Bridge.kt" "class Bridge"
  assert_silent "no output when include is missing"
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "include": "", "pattern": "." },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  add_project_file "src/Bridge.kt" "class Bridge"
  assert_silent "no output when include is empty"
  teardown
}

test_dir_include_glob_not_expanded() {
  echo "test: 'include' globs are not expanded against the working directory"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "dir": "src", "include": "*.kt", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Dir plugin."
  }'
  # A stray x.kt in the project root would replace the include glob if it
  # were expanded by the shell, and then x.kt would be the only match.
  add_project_file "x.kt" "class X"
  add_project_file "src/Bridge.kt" "class Bridge(val b: NativeBridge)"
  assert_recommended "test-plugin" "include glob still filters by pattern, not by a root file"
  teardown
}

test_dir_include_mixed_array() {
  echo "test: a 'dir' entry mixes with 'file' and 'files' entries (OR logic)"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": [
      { "file": "pubspec.yaml", "pattern": "never-matches-here" },
      { "files": "docs/plan/*.md", "pattern": "never-matches-here" },
      { "dir": "src", "include": "*.kt", "pattern": "NativeBridge" }
    ],
    "marketplace": "Org/repo",
    "description": "Mixed plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "docs/plan/p.md" "a plan"
  add_project_file "src/a/Bridge.kt" "class Bridge(val b: NativeBridge)"
  assert_recommended "test-plugin" "matched via the dir entry"
  add_project_file "pubspec.yaml" "name: never-matches-here"
  assert_recommended "test-plugin" "matched via the file entry with no dir match"
  teardown
}

test_detect_precedence_file_files_dir() {
  echo "test: within one entry, file wins over files, and files wins over dir"
  setup
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "file": "pubspec.yaml", "dir": "src", "include": "*.kt", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Precedence plugin."
  }'
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "src/Bridge.kt" "NativeBridge"
  assert_silent "file set: the dir match is ignored"
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/*.md", "dir": "src", "include": "*.kt", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Precedence plugin."
  }'
  add_project_file "docs/a.md" "nothing here"
  add_project_file "src/Bridge.kt" "NativeBridge"
  assert_silent "files set: the dir match is ignored"
  add_recommendation "test-plugin" '{
    "plugin": "test-plugin",
    "detect": { "files": "docs/*.md", "dir": "src", "include": "*.kt", "pattern": "NativeBridge" },
    "marketplace": "Org/repo",
    "description": "Precedence plugin."
  }'
  add_project_file "docs/a.md" "NativeBridge"
  assert_recommended "test-plugin" "files set and matching"
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
test_dir_include_matches
echo ""
test_dir_include_no_match
echo ""
test_dir_include_missing_dir
echo ""
test_dir_include_absent
echo ""
test_dir_include_glob_not_expanded
echo ""
test_dir_include_mixed_array
echo ""
test_detect_precedence_file_files_dir
echo ""
finish
