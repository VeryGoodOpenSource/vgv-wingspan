#!/bin/bash
# Tests for the shipped android-cli recommendation rule
# (hooks/recommendations/android-cli.json).
#
# Usage: bash hooks/test_recommendation_android_cli.sh
#
# Runs the hook against fixtures shaped like real files: share_plus and
# url_launcher_android (plugin implementations), url_launcher (app-facing
# federated package), the Flutter module template (add-to-app), and
# flutter/samples platform_channels.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/test_helpers.sh"

# ---------------------------------------------------------------------------
# Tests
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
  assert_single_json_block "$output" "single JSON output block"
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

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

echo "=== android-cli recommendation tests ==="
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
finish
