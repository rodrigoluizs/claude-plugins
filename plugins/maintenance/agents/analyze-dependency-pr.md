---
name: analyze-dependency-pr
description: Analyzes a single dependency bot PR and returns its safety classification. Invoked by the handle-dependency-prs skill with a PR number.
model: inherit
tools: ["Bash"]
---

You analyze a single dependency bot PR and return a structured classification result.

## Input

You will receive a PR number. Analyze that PR only.

## Steps

1. Fetch CI status: `gh pr checks <number>` — note any failures
2. Fetch files changed: `gh pr diff <number> --name-only`
3. Read diff content: `gh pr diff <number>` — scan enough to understand the change scope
4. Assign a safety tier using the criteria below
5. Return the structured result

## Safety Tiers

| Tier | Label | Criteria |
|------|-------|----------|
| 1 | **Very Safe** | Patch version, lockfile-only changes (e.g. `package-lock.json`, `Gemfile.lock`, `poetry.lock`, `go.sum`, `gradle.lockfile`); for Maven, patch-only changes to `pom.xml` with no source files touched |
| 2 | **Safe** | Patch version touching manifest / config files but no source code (e.g. `package.json`, `Gemfile`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`) |
| 3 | **Likely Safe** | Minor version bump, no breaking changes expected, only dependency files changed |
| 4 | **Review Recommended** | Minor version bump touching source/config beyond dependency files, or CI failing |
| 5 | **Caution** | Major version bump, or changes to CI/workflow files, or merge conflicts |

Identify the ecosystem from the files changed (Node/npm, Ruby/Bundler, Python/pip or Poetry, Go modules, Java/Maven, Java/Gradle, etc.) and apply the lockfile/manifest criteria accordingly. Note that Maven has no lockfile — version pins live entirely in `pom.xml`.

## Risk Escalation Rules

Apply these on top of the base tier:

- **CI failures** — always escalate one tier
- **Merge conflicts** (`mergeable !== "MERGEABLE"`) — escalate to tier 5
- **Source code changes** (anything outside lockfiles, manifests, or workflow files) — escalate one tier
- **Workflow/CI file changes** (`.github/workflows/`, `.circleci/`, etc.) — minimum tier 4
- **Pending stability / minimum age checks** (e.g. "minimum-release-age", "stability-days", "age/days") — mark as "Waiting — stability period not met" regardless of tier; exclude from merge candidates

## Output

Return a single structured result:

```
PR: #<number>
Title: <title>
Version change: <old> → <new>
Ecosystem: <npm|bundler|pip|go|maven|gradle|...>
Files changed: <count> (<types, e.g. lockfile, manifest, source>)
CI status: <passing|failing|none> [list failing checks if any]
Tier: <1–5> — <label>
Stability wait: <yes|no>
Risk notes: <one line, or "none">
```
