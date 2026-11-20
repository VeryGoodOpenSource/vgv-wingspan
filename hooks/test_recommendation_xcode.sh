#!/bin/bash
# Tests for the shipped xcode recommendation rule
# (hooks/recommendations/xcode.json).
#
# Usage: bash hooks/test_recommendation_xcode.sh
#
# One question: does the rule fire on the right projects? Each detect entry
# gets a positive and a negative. How the hook scans, installs and combines
# recommendations is covered by test_recommend_plugins.sh.
#
# Fixtures are shaped like real files: the Flutter app template's AppDelegate
# (classic and implicit-engine), Flutter plugin podspecs and Package.swift
# files, and the add-to-app module pubspec.

set -euo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/lib/test_helpers.sh"

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

test_ios_pbxproj_and_xcproj_at_root() {
  echo "test: iOS .xcodeproj at the root is recommended in both file formats"
  setup
  use_real_recommendation "xcode"
  add_project_file "App.xcodeproj/project.pbxproj" "IPHONEOS_DEPLOYMENT_TARGET = 12.0;"
  assert_recommended "xcode" "project.pbxproj with an iOS deployment target"
  add_project_file "App.xcodeproj/project.xcproj" '"IPHONEOS_DEPLOYMENT_TARGET": "12.0",'
  assert_recommended "xcode" "JSON project.xcproj with an iOS deployment target"
  teardown
}

test_ios_macos_only_projects_not_recommended() {
  echo "test: macOS-only .xcodeproj is not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "App.xcodeproj/project.pbxproj" "SDKROOT = macosx;
MACOSX_DEPLOYMENT_TARGET = 13.0;"
  assert_silent "macOS-only project.pbxproj"
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
  assert_silent "ios/Runner.xcodeproj is not detected"
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
  assert_recommended "xcode" "Package.swift with .iOS("
  add_project_file "Package.swift" "// swift-tools-version: 5.9
import PackageDescription
let package = Package(
  name: \"Lib\",
  platforms: [.macOS(.v13)]
)"
  assert_silent "macOS-only Package.swift"
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
  assert_recommended "xcode" "ios/<name>.podspec"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "darwin/my_plugin.podspec" "Pod::Spec.new do |s|
  s.name = 'my_plugin'
end"
  assert_recommended "xcode" "darwin/<name>.podspec"
  teardown
}

test_ios_flutter_plugin_swift_package_only() {
  echo "test: Flutter plugin that only ships a Package.swift is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "ios/my_plugin/Package.swift" "// swift-tools-version: 5.9
import PackageDescription"
  assert_recommended "xcode" "ios/<name>/Package.swift"
  add_project_file "pubspec.yaml" "name: my_plugin"
  add_project_file "darwin/my_plugin/Package.swift" "// swift-tools-version: 5.9
import PackageDescription"
  assert_recommended "xcode" "darwin/<name>/Package.swift"
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
  assert_silent "macos/<name>.podspec is not detected"
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
  assert_silent "pubspec naming a default_package, no ios/ folder"
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
  assert_recommended "xcode" "module: iosBundleIdentifier:"
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
  assert_silent "classic AppDelegate.swift and flutter_launcher_icons ios: true"
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
  assert_silent "FlutterImplicitEngineDelegate AppDelegate.swift and ios: \"icon\""
  teardown
}

test_ios_plain_app_native_channel_code() {
  echo "test: plain Flutter app with native channel code is recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/Handlers/BatteryHandler.swift" "let channel = FlutterMethodChannel(name: \"battery\", binaryMessenger: messenger)"
  assert_recommended "xcode" "FlutterMethodChannel under ios/Runner/Handlers/"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/AppDelegate.m" "FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@\"battery\" binaryMessenger:controller.binaryMessenger];"
  assert_recommended "xcode" "FlutterMethodChannel in Objective-C AppDelegate.m"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/BatteryChannel.mm" "FlutterMethodChannel *channel = [FlutterMethodChannel methodChannelWithName:@\"battery\" binaryMessenger:messenger];"
  assert_recommended "xcode" "FlutterMethodChannel in Objective-C++ BatteryChannel.mm"
  local keyword
  for keyword in FlutterEventChannel FlutterBasicMessageChannel FlutterPlatformView; do
    add_project_file "pubspec.yaml" "name: my_app"
    add_project_file "ios/Runner/Native.swift" "final class Native: NSObject, $keyword {}"
    assert_recommended "xcode" "$keyword alone"
  done
  teardown
}

test_ios_plain_app_generated_files_not_recommended() {
  echo "test: plain Flutter app's generated Objective-C files are not recommended"
  setup
  use_real_recommendation "xcode"
  add_project_file "pubspec.yaml" "name: my_app"
  add_project_file "ios/Runner/AppDelegate.m" "#import \"AppDelegate.h\"
#import \"GeneratedPluginRegistrant.h\"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application
    didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
  [GeneratedPluginRegistrant registerWithRegistry:self];
  return [super application:application didFinishLaunchingWithOptions:launchOptions];
}

@end"
  # The registrant names FlutterPluginRegistry and FLTWebViewFlutterPlugin: it
  # guards the dir entry against a FlutterPlugin keyword, which would match
  # every generated registrant.
  add_project_file "ios/Runner/GeneratedPluginRegistrant.m" "#import \"GeneratedPluginRegistrant.h\"

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [FLTWebViewFlutterPlugin registerWithRegistrar:[registry registrarForPlugin:@\"FLTWebViewFlutterPlugin\"]];
}

@end"
  assert_silent "stock AppDelegate.m and a registrant naming FlutterPluginRegistry"
  teardown
}

test_ios_docs_native_keywords() {
  echo "test: plan and brainstorm docs naming native iOS frameworks are recommended"
  setup
  use_real_recommendation "xcode"
  local keyword
  for keyword in "SwiftUI" "UIKit" "App Intents"; do
    add_project_file "docs/plan/x.md" "We will build the screen in $keyword."
    assert_recommended "xcode" "docs/plan saying $keyword"
  done
  add_project_file "docs/brainstorm/x.md" "We will build the screen in SwiftUI."
  assert_recommended "xcode" "docs/brainstorm saying SwiftUI"
  teardown
}

test_ios_docs_flutter_plan_not_recommended() {
  echo "test: Flutter plan that only mentions generic iOS tooling is not recommended"
  setup
  use_real_recommendation "xcode"
  local phrase
  for phrase in "Xcode" "CocoaPods"; do
    add_project_file "docs/plan/x.md" "The release needs a working $phrase setup."
    assert_silent "docs/plan saying $phrase"
  done
  teardown
}

# ---------------------------------------------------------------------------
# Run all tests
# ---------------------------------------------------------------------------

echo "=== xcode recommendation tests ==="
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
test_ios_plain_app_generated_files_not_recommended
echo ""
test_ios_docs_native_keywords
echo ""
test_ios_docs_flutter_plan_not_recommended
echo ""
finish
