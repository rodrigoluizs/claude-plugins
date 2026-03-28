#!/usr/bin/env bash
# Usage: detect-changed-plugins.sh <base-sha> <head-sha>
# Prints one plugin name per line for each plugin directory touched between the two commits.
set -euo pipefail

BASE_SHA="${1:?base SHA required}"
HEAD_SHA="${2:?head SHA required}"

git diff --name-only "$BASE_SHA" "$HEAD_SHA" \
  | grep "^plugins/" \
  | cut -d'/' -f2 \
  | sort -u \
  || true
