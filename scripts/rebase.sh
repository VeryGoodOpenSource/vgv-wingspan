#!/bin/bash
# SessionStart hook: rebase current feature branch onto the base branch.
#
# Keeps feature branches up-to-date with main/master/develop to prevent
# merge conflicts from accumulating. Runs silently when the branch is
# already up-to-date or when conditions aren't right (e.g., on the base
# branch itself, uncommitted changes, or rebase conflicts).

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

# Don't rebase if we're already on the base branch.
if [[ "$CURRENT_BRANCH" == "$BASE_BRANCH" ]]; then
  exit 0
fi

# Don't rebase if there are uncommitted changes.
if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
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

# Attempt rebase — abort on conflicts.
if ! git rebase "origin/$BASE_BRANCH" --quiet 2>/dev/null; then
  git rebase --abort 2>/dev/null

  jq -n '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: "Automatic rebase of this branch onto the base branch failed due to conflicts. Consider resolving them manually with: git rebase origin/'"$BASE_BRANCH"'"
    }
  }'
  exit 0
fi

# Rebase succeeded — notify the model.
AHEAD=$(git rev-list --count "origin/$BASE_BRANCH"..HEAD 2>/dev/null || echo "?")
jq -n \
  --arg base "$BASE_BRANCH" \
  --arg ahead "$AHEAD" \
  '{
    hookSpecificOutput: {
      hookEventName: "SessionStart",
      additionalContext: ("Branch rebased onto origin/" + $base + ". " + $ahead + " commit(s) ahead.")
    }
  }'