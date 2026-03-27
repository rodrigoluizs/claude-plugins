#!/usr/bin/env bash
# Usage: update-plugin-files.sh <plugin-name>
# Reads the latest tag for the plugin and updates CHANGELOG.md and plugin.json.
# marketplace.json is updated separately after all plugins are processed.
# Prints the tag to stdout.
set -euo pipefail

PLUGIN="${1:?plugin name required}"
PLUGIN_DIR="plugins/$PLUGIN"

if [ ! -d "$PLUGIN_DIR" ]; then
  echo "Error: plugin directory '$PLUGIN_DIR' does not exist" >&2
  exit 1
fi

# --- find current and previous tags ---

TAGS=$(git tag -l "${PLUGIN}/v*" | sort -V)
CURRENT_TAG=$(echo "$TAGS" | tail -1)
PREV_TAG=$(echo "$TAGS" | tail -2 | head -1)

if [ -z "$CURRENT_TAG" ]; then
  echo "Error: no tag found for plugin '$PLUGIN'" >&2
  exit 1
fi

CURRENT_VERSION="${CURRENT_TAG#"${PLUGIN}/v"}"

# If there's only one tag, PREV_TAG == CURRENT_TAG — treat as no previous tag
if [ "$PREV_TAG" = "$CURRENT_TAG" ]; then
  COMMITS=$(git log --format="%s" -- "$PLUGIN_DIR")
else
  COMMITS=$(git log "${PREV_TAG}..${CURRENT_TAG}" --format="%s" -- "$PLUGIN_DIR")
fi

# --- update CHANGELOG.md ---

CHANGELOG_FILE="$PLUGIN_DIR/CHANGELOG.md"
DATE=$(date +%Y-%m-%d)
CHANGELOG_ENTRY="## $CURRENT_VERSION ($DATE)\n\n"
while IFS= read -r commit; do
  [ -z "$commit" ] && continue
  CHANGELOG_ENTRY+="- ${commit}\n"
done <<< "$COMMITS"

if [ -f "$CHANGELOG_FILE" ]; then
  TITLE=$(head -1 "$CHANGELOG_FILE")
  REST=$(tail -n +2 "$CHANGELOG_FILE")
  printf "%s\n\n%b\n%s\n" "$TITLE" "$CHANGELOG_ENTRY" "$REST" > "$CHANGELOG_FILE"
else
  printf "# Changelog\n\n%b\n" "$CHANGELOG_ENTRY" > "$CHANGELOG_FILE"
fi

# --- update plugin.json version ---

python3 - <<PYEOF
import json
path = "$PLUGIN_DIR/plugin.json"
with open(path) as f:
    data = json.load(f)
data["version"] = "$CURRENT_VERSION"
with open(path, "w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PYEOF

echo "$CURRENT_TAG"
