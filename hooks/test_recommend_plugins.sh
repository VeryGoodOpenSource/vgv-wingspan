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

# Run the hook on the current fixtures and assert the xcode plugin is
# recommended, then reset for the next fixture.
assert_ios_recommended() {
  local msg="$1"
  local output
  output=$(run_hook)
  assert_contains "$output" "The 'xcode' Claude Code plugin" "$msg"
  reset_project
}

# Run the hook on the current fixtures and assert it stays silent, then reset.
assert_ios_silent() {
  local msg="$1"
  local output
  output=$(run_hook)
  assert_empty "$output" "$msg"
  reset_project
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
# iOS (xcode) recommendation tests — run against the shipped xcode.json
# ---------------------------------------------------------------------------

assert_ios_recommended() { assert_recommended "xcode" "$1"; }
assert_ios_silent() { assert_silent "$1"; }

test_ios_pbxproj_and_xcproj_at_root() {
  echo "test: iOS .xcodeproj at the root is recommended in both file formats"
  setup
  use_real_recommendation "xcode"
  add_project_file "App.xcodeproj/project.pbxproj" "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
  assert_ios_recommended "project.pbxproj with an iOS deployment target"
  add_project_file "App.xcodeproj/project.xcproj" '"IPHONEOS_DEPLOYMENT_TARGET": "12.0",'
  assert_ios_recommended "JSON project.xcproj with an iOS deployment target"
  teardown
}

test_ios_macos_only_projects_not_recommended() {
  echo "test: macOS-only .xcodeproj is not recommended in either file format"
  setup
  use_real_recommendation "xcode"
  add_project_file "App.xcodeproj/project.pbxproj" "SDKROOT = macosx;
MACOSX_DEPLOYMENT_TARGET = 13.0;"
  assert_ios_silent "macOS-only project.pbxproj"
  add_project_file "App.xcodeproj/project.xcproj" '"SDKROOT": "macosx",
"MACOSX_DEPLOYMENT_TARGET": "13.0",'
  assert_ios_silent "macOS-only JSON project.xcproj"
  teardown
}

test_ios_flutter_app_xcodeproj_not_at_root() {
  echo "test: Flutter app whose Xcode project is under ios/ is not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_app
dependencies:
  flutter:
    sdk: flutter"
  add_project_file "ios/Runner.xcodeproj/project.pbxproj" "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
  assert_ios_silent "ios/Runner.xcodeproj is not detected"
  teardown
}

test_ios_swift_package_platforms() {
  echo "test: Swift package is recommended only when it targets iOS"
  setup
  use_real_recommendation "xcode"
  add_project_file "Package.swift" "// swift-tools-version: 5.9
import PackageDescription
let package = Package(
  name: \"Lib\",
  platforms: [.iOS(.v16), .macOS(.v13)]
)"
  assert_ios_recommended "Package.swift with .iOS("
  add_project_file "Package.swift" "// swift-tools-version: 5.9
import PackageDescription
let package = Package(
  name: \"Lib\",
  platforms: [.macOS(.v13)]
)"
  assert_ios_silent "macOS-only Package.swift"
  teardown
}

test_ios_flutter_plugin_podspec() {
  echo "test: Flutter plugin with an iOS or darwin podspec is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "ios/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  assert_ios_recommended "ios/<name>.podspec"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "darwin/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  assert_ios_recommended "darwin/<name>.podspec"
  teardown
}

test_ios_flutter_plugin_swift_package_only() {
  echo "test: Flutter plugin that only ships a Package.swift is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "ios/my_plugin/Package.swift" "// swift-tools-version: 5.9
import PackageDescription"
  assert_ios_recommended "ios/<name>/Package.swift"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "darwin/my_plugin/Package.swift" "// swift-tools-version: 5.9
import PackageDescription"
  assert_ios_recommended "darwin/<name>/Package.swift"
  teardown
}

test_ios_flutter_macos_only_plugin_not_recommended() {
  echo "test: macOS-only Flutter plugin is not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_plugin
flutter:
  plugin:
    platforms:
      macos:
        pluginClass: MyPlugin"
  add_project_file "macos/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  assert_ios_silent "macos/<name>.podspec is not detected"
  teardown
}

test_ios_federated_app_facing_not_recommended() {
  echo "test: app-facing federated Flutter package is not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: url_launcher
flutter:
  plugin:
    platforms:
      android:
        default_package: url_launcher_android
      ios:
        default_package: url_launcher_ios"
  assert_ios_silent "pubspec naming a default_package, no ios/ folder"
  teardown
}

test_ios_add_to_app_pubspec() {
  echo "test: add-to-app module pubspec is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_module
flutter:
  module:
    androidX: true
    androidPackage: com.example.my_module
    iosBundleIdentifier: com.example.myModule"
  assert_ios_recommended "module: iosBundleIdentifier:"
  teardown
}

test_ios_plain_flutter_app_not_recommended() {
  echo "test: plain Flutter app is not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_app
dependencies:
  flutter:
    sdk: flutter
flutter_launcher_icons:
  android: true
  ios: true"
  add_project_file "ios/Runner/AppDelegate.swift" "import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}"
  add_project_file "ios/Runner.xcodeproj/project.pbxproj" "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
  assert_ios_silent "classic AppDelegate.swift and flutter_launcher_icons ios: true"
  add_project_file "pubspec.yaml" "name: my_app
flutter_launcher_icons:
  ios: \"icon\""
  add_project_file "ios/Runner/AppDelegate.swift" "import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}"
  assert_ios_silent "FlutterImplicitEngineDelegate AppDelegate.swift and ios: \"icon\""
  teardown
}

test_ios_plain_app_native_channel_code() {
  echo "test: plain Flutter app with native channel code is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/AppDelegate.swift" "let channel = FlutterMethodChannel(name: \"battery\", binaryMessenger: controller.binaryMessenger)"
  assert_ios_recommended "FlutterMethodChannel in AppDelegate.swift"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/Handlers/BatteryHandler.swift" "let channel = FlutterMethodChannel(name: \"battery\", binaryMessenger: messenger)"
  assert_ios_recommended "FlutterMethodChannel under ios/Runner/Handlers/"
  local keyword
  for keyword in FlutterEventChannel FlutterBasicMessageChannel FlutterPlatformView FlutterPlugin; do
    add_project_file "pubspec.yaml" "name: my_app"
    add_project_file "ios/Runner/Native.swift" "final class Native: NSObject, $keyword {}"
    assert_ios_recommended "$keyword alone"
  done
  teardown
}

test_ios_docs_native_keywords() {
  echo "test: plan and brainstorm docs naming native iOS frameworks are recommended"
  setup
  use_real_recommendation "xcode"
  local keyword
  for keyword in "SwiftUI" "UIKit" "App Intents"; do
    add_project_file "docs/plan/x.md" "We will build the screen in $keyword."
    assert_ios_recommended "docs/plan saying $keyword"
  done
  add_project_file "docs/brainstorm/x.md" "We will build the screen in SwiftUI."
  assert_ios_recommended "docs/brainstorm saying SwiftUI"
  teardown
}

test_ios_docs_flutter_plan_not_recommended() {
  echo "test: Flutter plan that only mentions generic iOS tooling is not recommended"
  setup
  use_real_recommendation "xcode"
  local phrase
  for phrase in "Xcode" "CocoaPods" "Swift Package Manager" "iOS build" "Flutter"; do
    add_project_file "docs/plan/x.md" "The release needs a working $phrase setup."
    assert_ios_silent "docs/plan saying $phrase"
  done
  teardown
}

test_ios_and_flutter_recommended_together() {
  echo "test: Flutter plugin project gets both recommendations in one message"
  setup
  use_real_recommendation "xcode"
  use_real_recommendation "vgv-ai-flutter-plugin"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "ios/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  local output
  output=$(run_hook)
  assert_contains "$output" "The 'xcode' Claude Code plugin" "xcode plugin recommended"
  assert_contains "$output" "The 'vgv-ai-flutter-plugin' Claude Code plugin" "Flutter plugin recommended"
  assert_contains "$output" "/plugin marketplace add anthropics/claude-plugins-official" "Apple marketplace named"
  assert_single_json_block "$output" "single JSON output block"
  teardown
}

test_ios_flutter_installed_still_recommends_ios() {
  echo "test: installed Flutter plugin does not silence the xcode recommendation"
  setup
  use_real_recommendation "xcode"
  use_real_recommendation "vgv-ai-flutter-plugin"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "ios/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  add_settings ".claude/settings.json" '{"enabledPlugins": {"vgv-ai-flutter-plugin@very-good-claude-code-marketplace": true}}'
  local output
  output=$(run_hook)
  assert_contains "$output" "The 'xcode' Claude Code plugin" "xcode plugin recommended"
  assert_not_contains "$output" "vgv-ai-flutter-plugin" "installed Flutter plugin not recommended"
  teardown
}

test_ios_already_installed() {
  echo "test: installed xcode plugin is not recommended again"
  setup
  use_real_recommendation "xcode"
  add_project_file "Package.swift" "platforms: [.iOS(.v16)]"
  add_settings ".claude/settings.json" '{"enabledPlugins": {"xcode@claude-plugins-official": true}}'
  local output
  output=$(run_hook)
  assert_empty "$output" "no output when xcode is installed"
  assert_file_not_exists "$MARKER" "no marker written"
  teardown
}

test_ios_xcodebuild_rule_counts_as_installed() {
  echo "test: a Bash(xcodebuild:*) permission rule counts as installed (known gap)"
  setup
  use_real_recommendation "xcode"
  add_project_file "Package.swift" "platforms: [.iOS(.v16)]"
  add_settings ".claude/settings.json" '{"permissions": {"allow": ["Bash(xcodebuild:*)"]}}'
  local output
  output=$(run_hook)
  assert_empty "$output" "installed check matches the substring xcode"
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
test_ios_pbxproj_and_xcproj_at_root
echo ""
test_ios_macos_only_projects_not_recommended
echo ""
test_ios_flutter_app_xcodeproj_not_at_root
echo ""
test_ios_swift_package_platforms
echo ""
test_ios_flutter_plugin_podspec
echo ""
test_ios_flutter_plugin_swift_package_only
echo ""
test_ios_flutter_macos_only_plugin_not_recommended
echo ""
test_ios_federated_app_facing_not_recommended
echo ""
test_ios_add_to_app_pubspec
echo ""
test_ios_plain_flutter_app_not_recommended
echo ""
test_ios_plain_app_native_channel_code
echo ""
test_ios_docs_native_keywords
echo ""
test_ios_docs_flutter_plan_not_recommended
echo ""
test_ios_and_flutter_recommended_together
echo ""
test_ios_flutter_installed_still_recommends_ios
echo ""
test_ios_already_installed
echo ""
test_ios_xcodebuild_rule_counts_as_installed
echo ""
finish
