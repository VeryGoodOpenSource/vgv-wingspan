#!/usr/bin/env bash
# Checks that the plugin shares files through ${CLAUDE_PLUGIN_ROOT}/shared/…
# and that every path it names resolves.
#
# Usage: bash tool/check-plugin-paths.sh [plugin-dir]
#
# Fails on:
#   1. a symlink anywhere under the plugin folder;
#   2. a file under skills/ named like a file under shared/ (a leftover copy),
#      or a bare references/<name> or scripts/<name> path to a shared file;
#   3. a relative markdown link in a plugin .md file that does not resolve;
#   4. a ${CLAUDE_PLUGIN_ROOT}/<path> with no file at <plugin-dir>/<path>.
#
# Limits: rule 3 reads inline links `[text](path)` only. It does not read titled
# links, reference-style definitions, or `#anchor` targets.
#
# Portable shell: no grep -P, find -printf or awk intervals, so it runs on macOS
# and Linux.

set -euo pipefail

ROOT="${1:-"$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/plugin"}"
status=0

if [ ! -d "$ROOT" ]; then
  echo "error: $ROOT is not a directory" >&2
  exit 1
fi

fail() {
  echo "error: $*" >&2
  status=1
}

# Print a markdown file without its fenced code blocks, which hold template
# text such as `[link](raw/x.md)` that is not meant to resolve.
strip_fences() {
  awk '
    /^[ \t]*(```|~~~)/ {
      line = $0
      sub(/^[ \t]*/, "", line)
      ch = substr(line, 1, 1)
      n = 0
      while (substr(line, n + 1, 1) == ch) n++
      if (!open) { open = 1; len = n; fence_ch = ch; next }
      if (ch == fence_ch && n >= len) { open = 0; next }
    }
    !open { print }
  ' "$1"
}

# 1. Symlinks.
while IFS= read -r link; do
  fail "${link#"$ROOT"/} is a symlink. Reference the shared file through \${CLAUDE_PLUGIN_ROOT}/shared/… instead"
done < <(find "$ROOT" -type l)

# 2. Leftover copies of shared files.
if [ -d "$ROOT/shared" ] && [ -d "$ROOT/skills" ]; then
  while IFS= read -r shared_file; do
    name="$(basename "$shared_file")"
    while IFS= read -r copy; do
      fail "${copy#"$ROOT"/} copies ${shared_file#"$ROOT"/}. Delete the copy and reference the shared file"
    done < <(find "$ROOT/skills" -type f -name "$name")
    pattern="(^|[^/])(references|scripts)/$(printf '%s' "$name" | sed 's/\./\\./g')"
    while IFS= read -r hit; do
      fail "${hit#"$ROOT"/} names a shared file by a bare relative path. Use \${CLAUDE_PLUGIN_ROOT}/${shared_file#"$ROOT"/}"
    done < <(grep -rn -E "$pattern" "$ROOT/skills" "$ROOT/agents" --include='*.md' 2>/dev/null | cut -d: -f1,2 || true)
  done < <(find "$ROOT/shared" -type f)
fi

# 3. Relative markdown links that do not resolve.
while IFS= read -r file; do
  dir="$(dirname "$file")"
  while IFS= read -r target; do
    case "$target" in
      http://* | https://* | '#'*) continue ;;
    esac
    path="${target%%#*}"
    # A bare word such as (link) is template placeholder text, not a file.
    case "$path" in *.* | */*) ;; *) continue ;; esac
    if [ ! -e "$dir/$path" ]; then
      fail "${file#"$ROOT"/} links to $target, which does not exist"
    fi
  done < <(strip_fences "$file" | grep -o -E '\]\([^) ]+\)' | sed -E 's/^\]\(//; s/\)$//' || true)
done < <(find "$ROOT" -type f -name '*.md')

# 4. ${CLAUDE_PLUGIN_ROOT} paths that do not exist.
while IFS= read -r hit; do
  file="${hit%%:*}"
  ref="${hit#*:}"
  ref="$(printf '%s' "$ref" | sed -E 's/[.,]+$//')"
  rel="${ref#\$\{CLAUDE_PLUGIN_ROOT\}/}"
  if [ ! -e "$ROOT/$rel" ]; then
    fail "${file#"$ROOT"/} names ${ref}, which does not exist"
  fi
done < <(grep -r -o -E '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' "$ROOT" || true)

if [ "$status" -eq 0 ]; then
  echo "Plugin paths OK."
fi
exit "$status"
