#!/usr/bin/env bash
# Inventory the diff between a base branch and a source branch.
#
# Usage: split-inventory.sh <base-branch> <source-branch>
#
# Outputs KEY=value summary lines, then a FILES section with one
# tab-separated record per changed file:
#
#   <path>\t<added>\t<deleted>\t<generated|source>
#
# Files are classified as generated when the repository marks them
# linguist-generated, or when they match a common lockfile or codegen
# pattern. Generated lines are excluded from the meaningful totals so
# size targets reflect what a reviewer actually reads.

set -euo pipefail

if [[ $# -ne 2 ]]; then
  echo "ERROR: usage: split-inventory.sh <base-branch> <source-branch>" >&2
  exit 1
fi

BASE="$1"
SOURCE="$2"

for ref in "$BASE" "$SOURCE"; do
  if ! git rev-parse --verify "$ref" &>/dev/null; then
    echo "ERROR: ref not found: $ref" >&2
    exit 1
  fi
done

MERGE_BASE="$(git merge-base "$BASE" "$SOURCE")"

is_generated() {
  local path="$1"

  local attr
  attr="$(git check-attr linguist-generated -- "$path" 2>/dev/null | sed 's/.*: //')"
  if [[ "$attr" == "set" || "$attr" == "true" ]]; then
    return 0
  fi

  case "$(basename "$path")" in
    package-lock.json | yarn.lock | pnpm-lock.yaml | Gemfile.lock | \
      Cargo.lock | poetry.lock | composer.lock | go.sum | pubspec.lock | \
      Package.resolved | uv.lock)
      return 0
      ;;
  esac

  case "$path" in
    *.g.dart | *.freezed.dart | *.gen.dart | *.mocks.dart | *.pb.go | \
      *_pb2.py | *.generated.* | *.designer.cs | *.snap | *generated/* | \
      */__generated__/* | */migrations/*)
      return 0
      ;;
  esac

  return 1
}

total_files=0
meaningful=0
generated=0
records=""

while IFS=$'\t' read -r added deleted path; do
  [[ -z "${path:-}" ]] && continue

  # Binary files report "-" instead of a line count.
  [[ "$added" == "-" ]] && added=0
  [[ "$deleted" == "-" ]] && deleted=0

  total_files=$((total_files + 1))
  churn=$((added + deleted))

  if is_generated "$path"; then
    generated=$((generated + churn))
    records+="${path}	${added}	${deleted}	generated"$'\n'
  else
    meaningful=$((meaningful + churn))
    records+="${path}	${added}	${deleted}	source"$'\n'
  fi
done < <(git diff --numstat "$MERGE_BASE" "$SOURCE")

commits="$(git rev-list --count "$MERGE_BASE".."$SOURCE")"

echo "BASE=${BASE}"
echo "SOURCE=${SOURCE}"
echo "MERGE_BASE=${MERGE_BASE}"
echo "COMMITS=${commits}"
echo "TOTAL_FILES=${total_files}"
echo "MEANINGFUL_LINES=${meaningful}"
echo "GENERATED_LINES=${generated}"
echo "FILES"
printf '%s' "$records"
