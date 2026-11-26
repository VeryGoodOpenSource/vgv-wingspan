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

# The fixtures below need these files, so fail with a clear message if they move.
for needed in skills/build/SKILL.md shared/references/push.md shared/scripts/detect-base-branch.sh; do
  if [ ! -f "$PLUGIN/$needed" ]; then
    echo "error: test fixture plugin/$needed is missing; update this test" >&2
    exit 1
  fi
done

# append <dir> <text>: add text to the end of a copy's build SKILL.md.
append() {
  printf '%s\n' "$2" >>"$1/skills/build/SKILL.md"
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
  ln -s ../../../shared/references/push.md "$dir/skills/build/references/push-link.md"
  expect "symlink fails" fail "$dir" "push-link.md is a symlink"
}

test_leftover_copy_fails() {
  local dir
  dir="$(fresh_copy copy)"
  cp "$dir/shared/references/push.md" "$dir/skills/build/references/push.md"
  expect "leftover copy fails" fail "$dir" "skills/build/references/push.md copies"
}

test_leftover_script_copy_fails() {
  local dir
  dir="$(fresh_copy script)"
  mkdir -p "$dir/skills/build/scripts"
  cp "$dir/shared/scripts/detect-base-branch.sh" "$dir/skills/build/scripts/detect-base-branch.sh"
  expect "leftover script copy fails" fail "$dir" "skills/build/scripts/detect-base-branch.sh copies"
}

test_dead_link_fails() {
  local dir
  dir="$(fresh_copy link)"
  append "$dir" 'See [gone](references/gone.md).'
  expect "dead relative link fails" fail "$dir" "references/gone.md"
}

test_missing_plugin_root_path_fails() {
  local dir
  dir="$(fresh_copy root)"
  append "$dir" 'Read `${CLAUDE_PLUGIN_ROOT}/shared/references/missing.md`.'
  expect "missing CLAUDE_PLUGIN_ROOT path fails" fail "$dir" "shared/references/missing.md"
}

test_placeholder_links_are_ignored() {
  local dir
  dir="$(fresh_copy placeholder)"
  append "$dir" '[a](#anchor) [b](link) [c](https://example.com/x.md)'
  expect "anchor, bare-word and web links are ignored" pass "$dir"
}

test_tilde_and_nested_fences_are_ignored() {
  local dir
  dir="$(fresh_copy fences)"
  append "$dir" $'```md\n[gone](references/gone.md)\n```'
  append "$dir" $'~~~md\n[gone](references/gone.md)\n~~~'
  append "$dir" $'````md\n```bash\n[gone](references/gone.md)\n```\n[gone](references/gone.md)\n````'
  expect "backtick, tilde and nested fences are ignored" pass "$dir"
}

test_link_after_a_fence_is_still_checked() {
  local dir
  dir="$(fresh_copy after-fence)"
  append "$dir" $'```md\nexample\n```\n[gone](references/gone.md)'
  expect "a link after a closed fence is still checked" fail "$dir" "references/gone.md"
}

test_trailing_period_is_stripped() {
  local dir
  dir="$(fresh_copy period)"
  append "$dir" 'Read ${CLAUDE_PLUGIN_ROOT}/shared/references/push.md. Then stop.'
  expect "a valid path at the end of a sentence passes" pass "$dir"
}

test_missing_path_before_period_fails() {
  local dir
  dir="$(fresh_copy period-missing)"
  append "$dir" 'Read ${CLAUDE_PLUGIN_ROOT}/shared/references/missing.md. Then stop.'
  # The message must name the path without its period, which proves the strip ran.
  expect "a missing path at the end of a sentence fails" fail "$dir" "shared/references/missing.md, which does not exist"
}

test_missing_plugin_dir_fails() {
  expect "a missing plugin directory fails" fail "$WORK/does-not-exist" "is not a directory"
}

test_real_plugin_passes
test_symlink_fails
test_leftover_copy_fails
test_leftover_script_copy_fails
test_dead_link_fails
test_tilde_and_nested_fences_are_ignored
test_link_after_a_fence_is_still_checked
test_placeholder_links_are_ignored
test_missing_plugin_root_path_fails
test_trailing_period_is_stripped
test_missing_path_before_period_fails
test_missing_plugin_dir_fails

echo
echo "$PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
