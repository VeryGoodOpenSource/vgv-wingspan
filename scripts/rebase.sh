#!/bin/bash
# SessionStart hook: check if the current feature branch is behind the base branch.
#
# Advisory only — does not rebase automatically. Emits a message suggesting
# the user run `/rebase` when the branch is behind.

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)

if [[ -z "$CURRENT_BRANCH" || "$CURRENT_BRANCH" == "HEAD" ]]; then
  exit 0
fi

# Detect the base branch.
for candidate in main master develop; do
  if git rev-parse --verify "$candidate" >/dev/null 2>&1; then
    BASE_BRANCH="$candidate"
    break
  fi
done

if [[ -z "$BASE_BRANCH" ]]; then
  exit 0
fi

# Don't check if we're already on the base branch.
if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
  exit 0
fi

# Fetch latest from remote.
git fetch origin "$BASE_BRANCH" --quiet 2>/dev/null || exit 0

# Check if rebase is needed.
LOCAL_BASE=$(git merge-base HEAD "origin/$BASE_BRANCH" 2>/dev/null)
REMOTE_BASE=$(git rev-parse "origin/$BASE_BRANCH" 2>/dev/null)

if [[ "$LOCAL_BASE" == "$REMOTE_BASE" ]]; then
  exit 0
fi

# Count how many commits behind.
BEHIND=$(git rev-list --count HEAD.."origin/$BASE_BRANCH" 2>/dev/null || echo "some")

jq -n \
  --arg base "$BASE_BRANCH" \
  --arg behind "$BEHIND" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("Your branch is " + $behind + " commit(s) behind origin/" + $base + ". Run /rebase to update.")
    }
  }'