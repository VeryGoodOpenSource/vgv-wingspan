#!/usr/bin/env bash
# Detect the default/base branch of the repository.
# Checks main, master, develop in order. Outputs the first one found.
# Exits 1 if none exist.

for branch in main master develop; do
  if git rev-parse --verify "$branch" &>/dev/null ||
     git rev-parse --verify "origin/$branch" &>/dev/null; then
    echo "$branch"
    exit 0
  fi
done

echo "ERROR: no base branch found (checked main, master, develop)" >&2
exit 1
