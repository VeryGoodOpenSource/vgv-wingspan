#!/usr/bin/env bash
# Tests that the review agents' findings contract has not drifted.
#
# Usage: bash plugin/agents/test_review_contract.sh
#
# Each review agent carries a copy of the findings block in its
# `## Output Instructions` section, and
# skills/shared/references/review-agent-instructions.md holds the annotated
# version. This script fails when:
#   - the agents' Output Instructions sections differ beyond the block heading;
#   - an agent's block names different header or finding fields, or names them
#     in a different order, than the instructions file's block.
#
# It checks the real repository first, then runs the same check against
# mutated copies to prove it catches drift.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

AGENTS=(
  agents/codebase-review/vgv-review-agent.md
  agents/codebase-review/code-simplicity-review-agent.md
  agents/quality-review/architecture-review-agent.md
  agents/quality-review/pr-readiness-review-agent.md
  agents/quality-review/test-quality-review-agent.md
)
INSTRUCTIONS=skills/shared/references/review-agent-instructions.md

PASS=0
FAIL=0

# Print the `## Output Instructions` section, up to the next level-2 heading
# outside a code fence, with the block's `## <Agent> Findings` heading
# normalized.
output_section() {
  awk '
    /^## Output Instructions/ { on = 1; print; next }
    on && /^```/ { fence = !fence }
    on && !fence && /^## / { exit }
    on && fence && /^## .* Findings$/ { print "## <Agent Name> Findings"; next }
    on { print }
  ' "$1"
}

# Print the first ```markdown block in a file.
first_block() {
  awk '/^```markdown/ { on = 1; next } on && /^```/ { exit } on { print }' "$1"
}

# Print the field names a block declares, in order: the bold header keys, then
# the keys of its first finding item.
field_names() {
  awk '
    /^\*\*/ {
      line = $0
      while (match(line, /\*\*[A-Za-z]+\*\*:/)) {
        print "header " substr(line, RSTART + 2, RLENGTH - 5)
        line = substr(line, RSTART + RLENGTH)
      }
      next
    }
    /^- severity:/ { items++ }
    items == 1 && match($0, /^(- |  )[a-z]+:/) {
      key = substr($0, 3, RLENGTH - 3)
      print "field " key
    }
  '
}

# Check one repository root. Prints each problem; returns 1 when any is found.
check_contract() {
  local root="$1" status=0 ref_section ref_fields file

  for file in "${AGENTS[@]}" "$INSTRUCTIONS"; do
    if [[ ! -f "$root/$file" ]]; then
      echo "  missing file: $file"
      return 1
    fi
  done

  ref_section="$(output_section "$root/${AGENTS[0]}")"
  if [[ -z "$ref_section" ]]; then
    echo "  ${AGENTS[0]} has no '## Output Instructions' section"
    return 1
  fi

  for file in "${AGENTS[@]:1}"; do
    if ! diff -u --label "${AGENTS[0]}" --label "$file" \
        <(echo "$ref_section") <(output_section "$root/$file"); then
      echo "  $file: Output Instructions differ from ${AGENTS[0]}"
      status=1
    fi
  done

  ref_fields="$(first_block "$root/$INSTRUCTIONS" | field_names)"
  if [[ -z "$ref_fields" ]]; then
    echo "  $INSTRUCTIONS: no fields found in its findings block"
    return 1
  fi
  if ! diff -u --label "$INSTRUCTIONS" --label "${AGENTS[0]}" \
      <(echo "$ref_fields") \
      <(echo "$ref_section" | awk '/^```markdown/ { on = 1; next } on && /^```/ { exit } on' | field_names); then
    echo "  ${AGENTS[0]}: block fields differ from $INSTRUCTIONS"
    status=1
  fi

  return "$status"
}

# Copy the files the check reads into a temp root, so a test can mutate them.
copy_fixture() {
  local dir file
  dir="$(mktemp -d)"
  for file in "${AGENTS[@]}" "$INSTRUCTIONS"; do
    mkdir -p "$dir/$(dirname "$file")"
    cp "$REPO_ROOT/$file" "$dir/$file"
  done
  echo "$dir"
}

expect() {
  local name="$1" want="$2" root="$3" got
  if check_contract "$root" >/dev/null; then got=pass; else got=fail; fi
  if [[ "$got" == "$want" ]]; then
    echo "PASS: $name"
    PASS=$((PASS + 1))
  else
    echo "FAIL: $name (expected $want, got $got)"
    check_contract "$root" || true
    FAIL=$((FAIL + 1))
  fi
}

# Replace the first line matching a fixed string, with no sed -i portability issues.
replace_line() {
  local file="$1" old="$2" new="$3" tmp
  tmp="$(mktemp)"
  OLD="$old" NEW="$new" awk '
    !done && index($0, ENVIRON["OLD"]) { print ENVIRON["NEW"]; done = 1; next } { print }
  ' "$file" > "$tmp"
  mv "$tmp" "$file"
}

test_repository_has_no_drift() {
  expect "repository contract has no drift" pass "$REPO_ROOT"
}

test_field_added_to_one_agent_fails() {
  local dir; dir="$(copy_fixture)"
  replace_line "$dir/${AGENTS[2]}" "  fix: <one line" "  fix: <one line: the concrete action>
  confidence: <high|low>"
  expect "a field added to one agent fails" fail "$dir"
  rm -rf "$dir"
}

test_rule_text_changed_in_one_agent_fails() {
  local dir; dir="$(copy_fixture)"
  replace_line "$dir/${AGENTS[4]}" "The verdict is \`fail\`" \
    "The verdict is \`fail\` when you report any finding."
  expect "a rule change in one agent fails" fail "$dir"
  rm -rf "$dir"
}

test_field_added_to_instructions_only_fails() {
  local dir; dir="$(copy_fixture)"
  replace_line "$dir/$INSTRUCTIONS" "  missing: <only with" \
    "  missing: <only with \"quote: none\">
  confidence: <high|low>"
  expect "a field added to the instructions only fails" fail "$dir"
  rm -rf "$dir"
}

test_header_key_renamed_fails() {
  local dir; dir="$(copy_fixture)"
  replace_line "$dir/$INSTRUCTIONS" "**Verdict**:" \
    "**Result**: <pass|fail> | **Critical**: <count> | **Important**: <count> | **Suggestion**: <count>"
  expect "a renamed header key fails" fail "$dir"
  rm -rf "$dir"
}

test_different_heading_only_passes() {
  local dir; dir="$(copy_fixture)"
  replace_line "$dir/${AGENTS[1]}" " Findings" "## Some Other Agent Findings"
  expect "a different block heading alone passes" pass "$dir"
  rm -rf "$dir"
}

test_missing_agent_file_fails() {
  local dir; dir="$(copy_fixture)"
  rm "$dir/${AGENTS[3]}"
  expect "a missing agent file fails" fail "$dir"
  rm -rf "$dir"
}

echo "=== Review contract tests ==="
echo ""
test_repository_has_no_drift
test_field_added_to_one_agent_fails
test_rule_text_changed_in_one_agent_fails
test_field_added_to_instructions_only_fails
test_header_key_renamed_fails
test_different_heading_only_passes
test_missing_agent_file_fails
echo ""

echo "=== Results: $PASS passed, $FAIL failed ==="
if [[ $FAIL -gt 0 ]]; then
  exit 1
fi
