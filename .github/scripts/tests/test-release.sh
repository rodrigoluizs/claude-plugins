#!/usr/bin/env bash
set -euo pipefail

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

# --- version bump logic (extracted for testing) ---

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

echo "--- test: bump_version ---"
assert_eq "patch bump" "1.0.1" "$(bump_version "1.0.0" "patch")"
assert_eq "minor bump" "1.1.0" "$(bump_version "1.0.5" "minor")"
assert_eq "major bump" "2.0.0" "$(bump_version "1.3.2" "major")"

echo ""
echo "--- test: determine_bump ---"
assert_eq "fix → patch" "patch" "$(determine_bump "fix: correct field name")"
assert_eq "feat → minor" "minor" "$(determine_bump "feat: add new template")"
assert_eq "breaking feat → major" "major" "$(determine_bump "feat!: rename all fields")"
assert_eq "BREAKING CHANGE → major" "major" "$(determine_bump "$(printf 'fix: something\nBREAKING CHANGE: removed field')")"
assert_eq "mixed feat and fix → minor" "minor" "$(determine_bump "$(printf 'fix: patch\nfeat: new thing')")"
assert_eq "chore with ! → major" "major" "$(determine_bump "chore(release)!: bump")"

echo ""
echo "Results: $PASS passed, $FAIL failed"
[ "$FAIL" -eq 0 ]
