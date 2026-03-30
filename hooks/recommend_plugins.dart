#!/usr/bin/env dart
// PreToolUse hook: recommend companion plugins based on project type.
//
// Scans JSON files in the recommendations/ directory. Each file describes
// a plugin to recommend: how to detect the project type (a file + grep
// pattern) and the plugin name to look for in Claude Code settings.
//
// To add a new recommendation, drop a JSON file in recommendations/ with:
//   {
//     "plugin":      "plugin-name",
//     "detect":      { "file": "Gemfile", "pattern": "^\\s*gem\\s+.rails." },
//     "marketplace": "OrgName/repo-name",   (GitHub owner/repo)
//     "description": "What the plugin provides."
//   }
//
// All matching recommendations are collected and emitted together in a
// single message. A per-project temp marker (/tmp/wingspan-recommend-plugins-
// <hash>) ensures recommendations are emitted at most once per session.
// Without it, the hook would inject the same context on every matched tool
// call.

import 'dart:convert';
import 'dart:io';

void main() {
  // Read hook input from stdin (not used, but consumed to avoid broken pipe).
  try {
    stdin.readLineSync();
  } catch (_) {}

  final projectHash = _sha1Hash(Directory.current.path);
  final marker = File('/tmp/wingspan-recommend-plugins-$projectHash');

  // Skip if we already ran recommendations for this project in this session.
  if (marker.existsSync()) exit(0);

  final scriptDir = File(Platform.script.toFilePath()).parent.path;
  final recommendationsDir = Directory('$scriptDir/recommendations');

  if (!recommendationsDir.existsSync()) exit(0);

  // Collect settings files to check (local > project > user).
  final settingsFiles = [
    '.claude/settings.local.json',
    '.claude/settings.json',
    '${Platform.environment['HOME']}/.claude/settings.json',
  ];

  final recFiles = recommendationsDir.listSync()
    ..sort((a, b) => a.path.compareTo(b.path));

  // Evaluate each recommendation file and collect all matches.
  final recommendations = <String>[];

  for (final entry in recFiles) {
    if (entry is! File || !entry.path.endsWith('.json')) continue;

    final Map<String, dynamic> rec;
    try {
      rec = jsonDecode(entry.readAsStringSync()) as Map<String, dynamic>;
    } catch (_) {
      continue;
    }

    final plugin = rec['plugin'] as String?;
    final detect = rec['detect'] as Map<String, dynamic>?;
    final marketplace = rec['marketplace'] as String?;
    final description = rec['description'] as String?;

    if (plugin == null || detect == null) continue;

    final detectFile = detect['file'] as String?;
    final detectPattern = detect['pattern'] as String?;

    if (detectFile == null || detectPattern == null) continue;

    // Project type detection.
    final target = File(detectFile);
    if (!target.existsSync()) continue;

    final pattern = RegExp(detectPattern, multiLine: true);
    if (!pattern.hasMatch(target.readAsStringSync())) continue;

    // Already installed — skip.
    if (_isPluginInstalled(plugin, settingsFiles)) continue;

    // Collect recommendation.
    recommendations.add(
      "The '$plugin' Claude Code plugin is not installed. "
      'It provides: $description '
      'Recommend the user install it by first adding the marketplace with: '
      '/plugin marketplace add $marketplace '
      '— then installing via: /plugin install $plugin',
    );
  }

  // Emit all recommendations in a single message, then set the marker.
  if (recommendations.isNotEmpty) {
    marker.createSync();
    stdout.writeln(
      jsonEncode({
        'hookSpecificOutput': {
          'hookEventName': 'PreToolUse',
          'additionalContext': recommendations.join('\n\n'),
        },
      }),
    );
  }
}

/// Check if a plugin is referenced in any of the settings files.
bool _isPluginInstalled(String pluginName, List<String> settingsFiles) {
  for (final path in settingsFiles) {
    final file = File(path);
    if (file.existsSync()) {
      try {
        if (file.readAsStringSync().contains(pluginName)) return true;
      } catch (_) {
        continue;
      }
    }
  }
  return false;
}

/// Simple hash using dart:io's Process to call shasum, matching the shell
/// script's behavior. Falls back to a basic string hash if shasum is
/// unavailable.
String _sha1Hash(String input) {
  try {
    final result = Process.runSync('/bin/sh', [
      '-c',
      "echo '$input' | shasum | cut -d' ' -f1",
    ], stdoutEncoding: utf8);
    if (result.exitCode == 0) {
      return (result.stdout as String).trim();
    }
  } catch (_) {}
  // Fallback: simple hash.
  return input.hashCode.toRadixString(16);
}
