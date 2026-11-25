#!/usr/bin/env bash
# Detect review scope: current branch, base branch, and changed files.
# Output format (one section per line):
#   CURRENT_BRANCH=<branch>
#   BASE_BRANCH=<branch>
#   SCOPE=branch|default
#   FILES (one per line after the FILES header)
#
# Usage: detect-review-scope.sh

set -euo pipefail

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "CURRENT_BRANCH=$CURRENT_BRANCH"

# Detect base branch
BASE_BRANCH=""
DEFAULT_REF=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||' || true)
if [ -n "$DEFAULT_REF" ]; then
  BASE_BRANCH="$DEFAULT_REF"
else
  for branch in main master develop; do
    if git rev-parse --verify "$branch" &>/dev/null ||
       git rev-parse --verify "origin/$branch" &>/dev/null; then
      BASE_BRANCH="$branch"
      break
    fi
  done
fi
echo "BASE_BRANCH=$BASE_BRANCH"

# Determine scope
if [ "$CURRENT_BRANCH" = "$BASE_BRANCH" ] || [ -z "$BASE_BRANCH" ]; then
  echo "SCOPE=default"
else
  echo "SCOPE=branch"
  echo "FILES"
  # Combine branch diff + uncommitted + staged, deduplicate
  {
    git diff "$BASE_BRANCH"...HEAD --name-only 2>/dev/null
    git diff --name-only 2>/dev/null
    git diff --cached --name-only 2>/dev/null
  } | sort -u
fi
