#!/bin/bash
# Tests for the shipped android-cli recommendation rule
# (hooks/recommendations/android-cli.json).
#
# Usage: bash test/hooks/test_recommendation_android_cli.sh
#
# One question: does the rule fire on the right projects? Each detect entry
# gets a positive and a negative. How the hook scans, installs and combines
# recommendations is covered by test_recommend_plugins.sh.
#
# Fixtures are shaped like real files: share_plus (a plugin implementation),
# url_launcher (an app-facing federated package), the Flutter module template
# (add-to-app), and templates/plugin_ffi (an FFI plugin).

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/test_helpers.sh"

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_android_root_gradle_files() {
  echo "test: android-cli recommended for an Android plugin in a root Gradle file"
  setup
  use_real_recommendation "android-cli"

  add_project_file "build.gradle.kts" 'plugins {
    id("com.android.application") version "8.5.0" apply false
}'
  assert_recommended "android-cli" "recommends for a Kotlin DSL application"

  add_project_file "build.gradle" "plugins {
    id 'com.android.library'
}"
  assert_recommended "android-cli" "recommends for a Groovy library"

  add_project_file "build.gradle.kts" 'plugins {
    alias(libs.plugins.android.application) apply false
}'
  assert_recommended "android-cli" "recommends for a version catalog alias"

  add_project_file "settings.gradle.kts" 'pluginManagement {
    plugins {
        id("com.android.application") version "8.5.0"
    }
}'
  assert_recommended "android-cli" "recommends from settings.gradle.kts alone"
  teardown
}

test_android_gradle_non_android_plugin() {
  echo "test: android-cli not recommended for Gradle files without an Android plugin"
  setup
  use_real_recommendation "android-cli"
  add_project_file "build.gradle.kts" 'plugins {
    alias(libs.plugins.kotlin.android) apply false
    id("org.jetbrains.kotlin.android") version "2.0.0" apply false
}'
  assert_silent "silent for a non-Android Gradle plugin"
  teardown
}

test_android_version_catalog_file() {
  echo "test: android-cli recommended from gradle/libs.versions.toml alone"
  setup
  use_real_recommendation "android-cli"
  add_project_file "gradle/libs.versions.toml" '[plugins]
android-application = { id = "com.android.application", version.ref = "agp" }'
  assert_recommended "android-cli" "recommends from the version catalog"

  add_project_file "gradle/libs.versions.toml" '[plugins]
kotlin-android = { id = "org.jetbrains.kotlin.android", version.ref = "kotlin" }'
  assert_silent "silent for a catalog without an Android plugin"
  teardown
}

test_android_flutter_plugin_pubspec() {
  echo "test: android-cli recommended for a Flutter plugin's pubspec"
  setup
  use_real_recommendation "android-cli"
  # Shaped like share_plus. A federated implementation reaches this same package: branch.
  add_project_file "pubspec.yaml" "name: share_plus
flutter:
  plugin:
    platforms:
      android:
        package: dev.fluttercommunity.plus.share
        pluginClass: SharePlusPlugin
      ios:
        pluginClass: FPPSharePlusPlugin"
  assert_recommended "android-cli" "recommends for a native plugin implementation"

  # The same branch at another indent: package: sits four spaces in.
  add_project_file "pubspec.yaml" "name: my_plugin
flutter:
 plugin:
  platforms:
   android:
    package: com.example.my_plugin
    pluginClass: MyPlugin"
  assert_recommended "android-cli" "recommends at a four-space package: indent"
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
  assert_recommended "android-cli" "recommends for androidPackage"
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
      web:
        default_package: url_launcher_web"
  assert_silent "silent for default_package only"
  teardown
}

test_android_plain_flutter_app_not_recommended() {
  echo "test: android-cli not recommended for a plain Flutter app or package-like keys"
  setup
  use_real_recommendation "android-cli"
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
  assert_silent "silent for 'android: true' and 'android_12:'"

  add_project_file "pubspec.yaml" "name: my_app
package_rename_config:
  android:
    package_name: com.example.my_app
  ios:
    package_name: com.example.myApp
packages:
  - first
  - second"
  assert_silent "silent for package_rename_config and a packages: list"
  teardown
}

test_android_ffi_plugin() {
  echo "test: android-cli recommended for an FFI plugin"
  setup
  use_real_recommendation "android-cli"
  # The pubspec is context only: ffiPlugin: true has no package: line, so the
  # match comes from android/build.gradle (the com.android.library entry).
  add_project_file "pubspec.yaml" "name: my_ffi
flutter:
  plugin:
    platforms:
      android:
        ffiPlugin: true
      ios:
        ffiPlugin: true"
  # Shaped like templates/plugin_ffi/android.tmpl/build.gradle.tmpl.
  add_project_file "android/build.gradle" "group = 'com.example.my_ffi'
version = '1.0'

buildscript {
    dependencies {
        classpath('com.android.tools.build:gradle:8.1.0')
    }
}

apply plugin: 'com.android.library'

android {
    namespace = 'com.example.my_ffi'
    compileSdk = 34
}"
  assert_recommended "android-cli" "recommends for ffiPlugin with a library build.gradle"
  teardown
}

test_android_plain_app_gradle_files_not_recommended() {
  echo "test: android-cli not recommended for a plain app's Gradle files"
  setup
  use_real_recommendation "android-cli"
  add_project_file "pubspec.yaml" "name: my_app
dependencies:
  flutter:
    sdk: flutter"
  # Shaped like the flutter_tools app template, plus an application plugin id:
  # only com.android.library may match in android/build.gradle.
  add_project_file "android/build.gradle" "plugins {
    id 'com.android.application' apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.buildDir = '../build'
subprojects {
    project.buildDir = \"\${rootProject.buildDir}/\${project.name}\"
}"
  add_project_file "android/app/build.gradle" "plugins {
    id 'com.android.application'
    id 'kotlin-android'
}"
  add_project_file "android/settings.gradle" "pluginManagement {
    plugins {
        id 'com.android.application' version '8.1.0' apply false
    }
}"
  assert_silent "silent for the android/ Gradle files of a plain app"
  teardown
}

test_android_native_channel_code() {
  echo "test: android-cli recommended for native channel code"
  setup
  use_real_recommendation "android-cli"

  # Each keyword alone, so no alternative in the pattern is masked by another.
  local keyword
  for keyword in MethodChannel EventChannel BasicMessageChannel PlatformView configureFlutterEngine; do
    add_project_file "android/app/src/main/kotlin/dev/flutter/app/MainActivity.kt" "package dev.flutter.app

// $keyword"
    assert_recommended "android-cli" "recommends on '$keyword' alone"
  done

  add_project_file "android/app/src/main/java/dev/flutter/app/MainActivity.java" "package dev.flutter.app;

import io.flutter.embedding.android.FlutterActivity;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
}"
  assert_recommended "android-cli" "recommends for a MainActivity.java using MethodChannel"
  teardown
}

test_android_plain_app_generated_files_not_recommended() {
  echo "test: android-cli not recommended for the files Flutter generates"
  setup
  use_real_recommendation "android-cli"
  add_project_file "android/app/src/main/kotlin/dev/flutter/app/MainActivity.kt" "package dev.flutter.animations

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity()"
  # The registrant names WebViewFlutterPlugin: it guards the dir entry against a
  # FlutterPlugin keyword, which would match every generated registrant.
  add_project_file "android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java" "package io.flutter.plugins;

import androidx.annotation.Keep;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;

@Keep
public final class GeneratedPluginRegistrant {
  public static void registerWith(@NonNull FlutterEngine flutterEngine) {
    flutterEngine.getPlugins().add(new io.flutter.plugins.webviewflutter.WebViewFlutterPlugin());
  }
}"
  assert_silent "silent for the default MainActivity and a registrant naming WebViewFlutterPlugin"
  teardown
}

test_android_docs_native_keywords() {
  echo "test: android-cli recommended when a plan or brainstorm names native Android tech"
  setup
  use_real_recommendation "android-cli"

  local keyword
  for keyword in Kotlin "Jetpack Compose" androidx; do
    add_project_file "docs/plan/x.md" "We will build the screen with $keyword."
    assert_recommended "android-cli" "recommends from docs/plan on '$keyword'"
  done

  add_project_file "docs/brainstorm/x.md" "We will build the screen with Jetpack Compose."
  assert_recommended "android-cli" "recommends from docs/brainstorm"
  teardown
}

test_android_docs_flutter_plan_not_recommended() {
  echo "test: android-cli not recommended for a Flutter plan that mentions Android"
  setup
  use_real_recommendation "android-cli"
  add_project_file "docs/plan/x.md" "Build the Flutter app. Run it from Android Studio. Run the Gradle build for the android flavor."
  assert_silent "silent for a Flutter plan"
  teardown
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

echo "=== android-cli recommendation tests ==="
echo ""

test_android_root_gradle_files
echo ""
test_android_gradle_non_android_plugin
echo ""
test_android_version_catalog_file
echo ""
test_android_flutter_plugin_pubspec
echo ""
test_android_add_to_app_pubspec
echo ""
test_android_federated_app_facing_not_recommended
echo ""
test_android_plain_flutter_app_not_recommended
echo ""
test_android_ffi_plugin
echo ""
test_android_plain_app_gradle_files_not_recommended
echo ""
test_android_native_channel_code
echo ""
test_android_plain_app_generated_files_not_recommended
echo ""
test_android_docs_native_keywords
echo ""
test_android_docs_flutter_plan_not_recommended
echo ""
finish
