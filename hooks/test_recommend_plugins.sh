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
# Android recommendation (tests the shipped android-cli.json)
#
# Fixtures are shaped like real files: share_plus and url_launcher_android
# (plugin implementations), url_launcher (app-facing federated package), the
# Flutter module template (add-to-app), and flutter/samples platform_channels.
# ---------------------------------------------------------------------------

# Pubspec shaped like share_plus: a native implementation of a plugin.
ANDROID_PLUGIN_PUBSPEC="name: share_plus
flutter:
  plugin:
    platforms:
      android:
        package: dev.fluttercommunity.plus.share
        pluginClass: SharePlusPlugin
      ios:
        pluginClass: FPPSharePlusPlugin"

test_android_gradle_kotlin_dsl() {
  echo "test: android-cli recommended for a Kotlin DSL build.gradle.kts"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins {
    id("com.android.application") version "8.5.0" apply false
}'
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  assert_file_exists "$MARKER" "marker file created"
  teardown
}

test_android_gradle_groovy_library() {
  echo "test: android-cli recommended for a Groovy build.gradle library"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle" "plugins {
    id 'com.android.library'
}"
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_version_catalog_alias() {
  echo "test: android-cli recommended for a version catalog plugin alias"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins {
    alias(libs.plugins.android.application) apply false
    alias(libs.plugins.kotlin.android) apply false
}'
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_version_catalog_file() {
  echo "test: android-cli recommended from gradle/libs.versions.toml alone"
  setup
  use_real_recommendation "android-cli"
  add_project_file "gradle/libs.versions.toml" '[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }'
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_settings_gradle_kotlin_dsl() {
  echo "test: android-cli recommended from settings.gradle.kts alone"
  setup
  use_real_recommendation "android-cli"
  add_project_file "settings.gradle.kts" 'pluginManagement {
    plugins {
        id("com.android.application") version "8.5.0"
    }
}'
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_description_names_android_not_flutter() {
  echo "test: android-cli description names the technology and never Flutter"
  local desc
  desc=$(jq -r '.description' "$SCRIPT_DIR/recommendations/android-cli.json")
  assert_contains "$desc" "Android" "description names Android"
  assert_contains "$desc" "Kotlin" "description names Kotlin"
  assert_contains "$desc" "Jetpack Compose" "description names Jetpack Compose"
  if echo "$desc" | grep -qi "flutter"; then
    FAIL=$((FAIL + 1))
    echo "  FAIL: description must not mention Flutter"
  else
    PASS=$((PASS + 1))
    echo "  PASS: description does not mention Flutter"
  fi
}

test_android_gradle_non_android_plugin() {
  echo "test: android-cli not recommended for Gradle files without an Android plugin"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins {
    alias(libs.plugins.kotlin.android) apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
}'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output for a non-Android Gradle plugin"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_android_flutter_plugin_pubspec() {
  echo "test: android-cli recommended for a Flutter plugin's pubspec"
  setup
  use_real_recommendation "android-cli"
  add_project_file "pubspec.yaml" "$ANDROID_PLUGIN_PUBSPEC"
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_federated_implementation_pubspec() {
  echo "test: android-cli recommended for a federated Android implementation"
  setup
  use_real_recommendation "android-cli"
  add_project_file "pubspec.yaml" "name: url_launcher_android
flutter:
  plugin:
    implements: url_launcher
    platforms:
      android:
        package: io.flutter.plugins.urllauncher
        pluginClass: UrlLauncherPlugin"
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_federated_app_facing_not_recommended() {
  echo "test: android-cli not recommended for an app-facing federated package"
  setup
  use_real_recommendation "android-cli"
  add_project_file "pubspec.yaml" "name: url_launcher
flutter:
  plugin:
    platforms:
      android:
        default_package: url_launcher_android
      ios:
        default_package: url_launcher_ios
      linux:
        default_package: url_launcher_linux
      web:
        default_package: url_launcher_web"
  local output
  output=$(run_hook)
  assert_empty "$output" "no output for default_package only"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_android_add_to_app_pubspec() {
  echo "test: android-cli recommended for an add-to-app module"
  setup
  use_real_recommendation "android-cli"
  add_project_file "pubspec.yaml" "name: flutter_module_books
flutter:
  uses-material-design: true
  module:
    androidX: true
    androidPackage: dev.flutter.flutter_module_books
    iosBundleIdentifier: dev.flutter.flutterModuleBooks"
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends android-cli"
  teardown
}

test_android_plain_flutter_app_not_recommended() {
  echo "test: android-cli not recommended for a plain Flutter app"
  setup
  use_real_recommendation "android-cli"
  local output

  # flutter_launcher_icons: boolean form, with flutter_native_splash.
  add_project_file "pubspec.yaml" "name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter_launcher_icons:
  android: true
  ios: true
  image_path: assets/icon.png
flutter_native_splash:
  color: '#ffffff'
  android_12:
    color: '#ffffff'
flutter:
  uses-material-design: true"
  output=$(run_hook)
  assert_empty "$output" "silent for 'android: true' and 'android_12:'"

  # flutter_launcher_icons: string form.
  add_project_file "pubspec.yaml" "name: my_app
flutter_launcher_icons:
  android: \"launcher_icon\"
  image_path: assets/icon.png"
  output=$(run_hook)
  assert_empty "$output" "silent for 'android: \"launcher_icon\"'"

  # flutter_launcher_icons: nested block.
  add_project_file "pubspec.yaml" "name: my_app
flutter_launcher_icons:
  image_path: assets/icon.png
  android:
    generate: true
    image_path: assets/android.png
    adaptive_icon_background: '#ffffff'"
  output=$(run_hook)
  assert_empty "$output" "silent for a nested 'android:' block"

  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_android_plain_app_native_channel_code() {
  echo "test: android-cli recommended for a plain app with native channel code"
  setup
  use_real_recommendation "android-cli"
  local output pkg
  # Package paths of three, four, and five segments.
  for pkg in dev/flutter/app dev/flutter/samples/app dev/flutter/samples/app/channels; do
    rm -rf "$TEST_DIR/android"
    rm -f "$MARKER"
    add_project_file "android/app/src/main/kotlin/$pkg/MainActivity.kt" "package dev.flutter.platform_channels

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, \"samples.flutter.dev/battery\")
    }
}"
    output=$(run_hook)
    assert_contains "$output" "android-cli" "recommends android-cli at $pkg"
  done

  # Each keyword alone, so no alternative in the pattern is masked by another.
  local keyword
  for keyword in MethodChannel EventChannel BasicMessageChannel PlatformView FlutterPlugin configureFlutterEngine; do
    rm -rf "$TEST_DIR/android"
    rm -f "$MARKER"
    add_project_file "android/app/src/main/kotlin/dev/flutter/app/MainActivity.kt" "package dev.flutter.app

// $keyword"
    output=$(run_hook)
    assert_contains "$output" "android-cli" "recommends android-cli on '$keyword' alone"
  done
  teardown
}

test_android_plain_app_default_main_activity() {
  echo "test: android-cli not recommended for the generated MainActivity"
  setup
  use_real_recommendation "android-cli"
  add_project_file "android/app/src/main/kotlin/dev/flutter/app/MainActivity.kt" "package dev.flutter.animations

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()"
  local output
  output=$(run_hook)
  assert_empty "$output" "no output for the default MainActivity"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_android_docs_native_keywords() {
  echo "test: android-cli recommended when a plan or brainstorm names native Android tech"
  setup
  use_real_recommendation "android-cli"
  local output

  local keyword
  for keyword in Kotlin "Jetpack Compose" androidx; do
    rm -rf "$TEST_DIR/docs"
    rm -f "$MARKER"
    add_project_file "docs/plan/x.md" "We will build the screen with $keyword."
    output=$(run_hook)
    assert_contains "$output" "android-cli" "recommends from docs/plan on '$keyword'"
  done

  rm -rf "$TEST_DIR/docs"
  rm -f "$MARKER"
  add_project_file "docs/brainstorm/x.md" "We will build the screen with Jetpack Compose."
  output=$(run_hook)
  assert_contains "$output" "android-cli" "recommends from docs/brainstorm"
  teardown
}

test_android_docs_flutter_plan_not_recommended() {
  echo "test: android-cli not recommended for a Flutter plan that mentions Android"
  setup
  use_real_recommendation "android-cli"
  add_project_file "docs/plan/x.md" "Build the Flutter app. Run it from Android Studio. Run the Gradle build for the android flavor."
  local output
  output=$(run_hook)
  assert_empty "$output" "no output for a Flutter plan"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_android_and_flutter_recommended_together() {
  echo "test: android-cli and the Flutter plugin share one message"
  setup
  use_real_recommendation "android-cli"
  use_real_recommendation "vgv-ai-flutter-plugin"
  add_project_file "pubspec.yaml" "$ANDROID_PLUGIN_PUBSPEC"
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "android-cli in output"
  assert_contains "$output" "vgv-ai-flutter-plugin" "Flutter plugin in output"
  assert_contains "$output" "android/android-cli-plugin" "Android marketplace in output"
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

test_android_flutter_installed_still_recommends_android() {
  echo "test: android-cli still recommended when only the Flutter plugin is installed"
  setup
  use_real_recommendation "android-cli"
  use_real_recommendation "vgv-ai-flutter-plugin"
  add_project_file "pubspec.yaml" "$ANDROID_PLUGIN_PUBSPEC"
  add_settings ".claude/settings.json" '{"enabledPlugins": {"vgv-ai-flutter-plugin@very-good-claude-code-marketplace": true}}'
  local output
  output=$(run_hook)
  assert_contains "$output" "android-cli" "android-cli in output"
  assert_not_contains "$output" "vgv-ai-flutter-plugin" "installed Flutter plugin excluded"
  teardown
}

test_android_already_installed() {
  echo "test: android-cli not recommended when it is already installed"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins { id("com.android.application") }'
  add_settings ".claude/settings.json" '{"enabledPlugins": {"android-cli@android-cli-plugin": true}}'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when android-cli is installed"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

# Documents a known gap in is_plugin_installed (it substring-matches). When the
# hook matches on the plugin@marketplace key, flip this test to expect a recommendation.
test_android_marketplace_only_counts_as_installed() {
  echo "test: a settings file listing only the marketplace counts as installed (known gap)"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins { id("com.android.application") }'
  add_settings ".claude/settings.json" '{"extraKnownMarketplaces": {"android-cli-plugin": {"source": {"source": "github", "repo": "android/android-cli-plugin"}}}}'
  local output
  output=$(run_hook)
  assert_empty "$output" "silent: is_plugin_installed substring-matches the marketplace"
  assert_file_not_exists "$MARKER" "no marker written"
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
test_android_gradle_kotlin_dsl
echo ""
test_android_gradle_groovy_library
echo ""
test_android_version_catalog_alias
echo ""
test_android_version_catalog_file
echo ""
test_android_settings_gradle_kotlin_dsl
echo ""
test_android_description_names_android_not_flutter
echo ""
test_android_gradle_non_android_plugin
echo ""
test_android_flutter_plugin_pubspec
echo ""
test_android_federated_implementation_pubspec
echo ""
test_android_federated_app_facing_not_recommended
echo ""
test_android_add_to_app_pubspec
echo ""
test_android_plain_flutter_app_not_recommended
echo ""
test_android_plain_app_native_channel_code
echo ""
test_android_plain_app_default_main_activity
echo ""
test_android_docs_native_keywords
echo ""
test_android_docs_flutter_plan_not_recommended
echo ""
test_android_and_flutter_recommended_together
echo ""
test_android_flutter_installed_still_recommends_android
echo ""
test_android_already_installed
echo ""
test_android_marketplace_only_counts_as_installed
echo ""

echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
