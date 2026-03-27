#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PASS=0
FAIL=0

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    echo "  PASS: $desc"
    PASS=$((PASS + 1))
  else
    echo "  FAIL: $desc"
    echo "    expected: '$expected'"
    echo "    actual:   '$actual'"
    FAIL=$((FAIL + 1))
  fi
}

echo "--- test: extract plugin names from changed file list ---"

extract_plugins() {
  echo "$1" | grep "^plugins/" | cut -d'/' -f2 | sort -u
}

assert_eq "single plugin change" \
  "product" \
  "$(extract_plugins "plugins/product/skills/deployment-config/SKILL.md")"

assert_eq "multiple plugins, deduplicated" \
  "$(printf 'foo\nproduct')" \
  "$(extract_plugins "$(printf 'plugins/product/SKILL.md\nplugins/foo/agent.md\nplugins/product/plugin.json')")"

assert_eq "non-plugin changes excluded" \
  "" \
  "$(extract_plugins "marketplace.json")"

assert_eq "mixed: plugin and non-plugin" \
  "product" \
  "$(extract_plugins "$(printf 'marketplace.json\nplugins/product/plugin.json')")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
