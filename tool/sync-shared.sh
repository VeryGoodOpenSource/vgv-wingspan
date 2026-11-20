#!/bin/bash
# Copies every shared reference and script into the skills that use it.
#
# The plugin folder holds no symbolic links, so each skill carries a real copy
# of the shared files it links. tool/shared-copies.txt lists every copy.
#
# Usage:
#   bash tool/sync-shared.sh          # rewrite every copy from its source
#   bash tool/sync-shared.sh --check  # fail when a copy differs from its source

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SKILLS="$ROOT/plugin/skills"
MANIFEST="$ROOT/tool/shared-copies.txt"

check=false
if [ "${1:-}" = "--check" ]; then
  check=true
elif [ $# -gt 0 ]; then
  echo "Usage: bash tool/sync-shared.sh [--check]" >&2
  exit 2
fi

status=0
while read -r source copy; do
  case "$source" in '' | '#'*) continue ;; esac
  src="$SKILLS/shared/$source"
  dst="$SKILLS/$copy"
  if [ ! -f "$src" ]; then
    echo "error: source plugin/skills/shared/$source does not exist" >&2
    status=1
    continue
  fi
  if $check; then
    if ! cmp -s "$src" "$dst"; then
      echo "error: plugin/skills/$copy differs from plugin/skills/shared/$source." \
        "Run bash tool/sync-shared.sh" >&2
      status=1
    fi
  else
    mkdir -p "$(dirname "$dst")"
    cp "$src" "$dst"
  fi
done < "$MANIFEST"

exit $status
