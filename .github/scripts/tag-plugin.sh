#!/usr/bin/env bash
# Usage: tag-plugin.sh <plugin-name>
# Computes the next version from conventional commits, creates and pushes the git tag.
# Prints the new tag to stdout.
set -euo pipefail

PLUGIN="${1:?plugin name required}"
PLUGIN_DIR="plugins/$PLUGIN"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: plugin directory '$PLUGIN_DIR' does not exist" >&2
  exit 1
fi

# --- helpers ---

bump_version() {
  local current="$1" bump_type="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$current"
  case "$bump_type" in
    major) echo "$((major + 1)).0.0" ;;
    minor) echo "${major}.$((minor + 1)).0" ;;
    patch) echo "${major}.${minor}.$((patch + 1))" ;;
  esac
}

determine_bump() {
  local commits="$1"
  local bump="patch"
  while IFS= read -r commit; do
    [ -z "$commit" ] && continue
    if echo "$commit" | grep -qE "^(feat|fix|chore)(\(.+\))?!:|^BREAKING CHANGE"; then
      bump="major"; break
    elif echo "$commit" | grep -qE "^feat(\(.+\))?:"; then
      [ "$bump" != "major" ] && bump="minor"
    fi
  done <<< "$commits"
  echo "$bump"
}

# --- find last tag and commits since then ---

LAST_TAG=$(git tag -l "${PLUGIN}/v*" | sort -V | tail -1)

if [ -z "$LAST_TAG" ]; then
  COMMITS=$(git log --format="%s" -- "$PLUGIN_DIR")
  CURRENT_VERSION="0.0.0"
else
  COMMITS=$(git log "${LAST_TAG}..HEAD" --format="%s" -- "$PLUGIN_DIR")
  CURRENT_VERSION="${LAST_TAG#"${PLUGIN}/v"}"
fi

if [ -z "$COMMITS" ]; then
  echo "No new commits for plugin '$PLUGIN' since ${LAST_TAG:-beginning}. Skipping." >&2
  exit 0
fi

# --- determine next version and tag ---

BUMP=$(determine_bump "$COMMITS")
NEXT_VERSION=$(bump_version "$CURRENT_VERSION" "$BUMP")
TAG="${PLUGIN}/v${NEXT_VERSION}"

git tag "$TAG"
git push origin "$TAG"

echo "$TAG"
