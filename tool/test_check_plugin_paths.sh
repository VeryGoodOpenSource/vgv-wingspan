#!/usr/bin/env bash
# Tests tool/check-plugin-paths.sh.
#
# Usage: bash tool/test_check_plugin_paths.sh
#
# Runs the check on the real plugin folder, then on temporary copies with one
# planted fault each, and expects the check to fail on every fault.

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECK="$TOOL_DIR/check-plugin-paths.sh"
PLUGIN="$(cd "$TOOL_DIR/.." && pwd)/plugin"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

PASS=0
FAIL=0

# expect <name> <pass|fail> <plugin-dir> [text the error output must contain]
expect() {
  local name="$1" want="$2" dir="$3" needle="${4:-}" out got
  if out="$(bash "$CHECK" "$dir" 2>&1)"; then got=pass; else got=fail; fi
  if [ "$got" != "$want" ]; then
    echo "FAIL: $name (expected $want, got $got)"
    echo "$out" | sed 's/^/  /'
    FAIL=$((FAIL + 1))
  elif [ -n "$needle" ] && ! printf '%s' "$out" | grep -qF "$needle"; then
    echo "FAIL: $name (output lacks '$needle')"
    echo "$out" | sed 's/^/  /'
    FAIL=$((FAIL + 1))
  else
    echo "PASS: $name"
    PASS=$((PASS + 1))
  fi
}

# fresh_copy <name>: copy the plugin to $WORK/<name> and print the path.
fresh_copy() {
  cp -R "$PLUGIN" "$WORK/$1"
  printf '%s' "$WORK/$1"
}

test_real_plugin_passes() {
  expect "real plugin passes" pass "$PLUGIN"
}

test_symlink_fails() {
  local dir
  dir="$(fresh_copy symlink)"
  ln -s ../../shared/references/push.md "$dir/skills/build/references/push-link.md"
  expect "symlink fails" fail "$dir" "push-link.md is a symlink"
}

test_leftover_copy_fails() {
  local dir
  dir="$(fresh_copy copy)"
  cp "$dir/shared/references/push.md" "$dir/skills/build/references/push.md"
  expect "leftover copy fails" fail "$dir" "skills/build/references/push.md copies"
}

test_dead_link_fails() {
  local dir
  dir="$(fresh_copy link)"
  printf '\nSee [gone](references/gone.md).\n' >>"$dir/skills/build/SKILL.md"
  expect "dead relative link fails" fail "$dir" "references/gone.md"
}

test_link_in_code_fence_is_ignored() {
  local dir
  dir="$(fresh_copy fence)"
  printf '\n```md\n[gone](references/gone.md)\n```\n' >>"$dir/skills/build/SKILL.md"
  expect "link inside a code fence is ignored" pass "$dir"
}

test_missing_plugin_root_path_fails() {
  local dir
  dir="$(fresh_copy root)"
  printf '\nRead `${CLAUDE_PLUGIN_ROOT}/shared/references/missing.md`.\n' >>"$dir/skills/build/SKILL.md"
  expect "missing CLAUDE_PLUGIN_ROOT path fails" fail "$dir" "shared/references/missing.md"
}

test_real_plugin_passes
test_symlink_fails
test_leftover_copy_fails
test_dead_link_fails
test_link_in_code_fence_is_ignored
test_missing_plugin_root_path_fails

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
