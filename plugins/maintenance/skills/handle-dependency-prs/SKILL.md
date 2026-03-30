---
name: "handle-dependency-prs"
description: "Use when reviewing, triaging, or merging open PRs from dependency bots (e.g. Renovate, Dependabot), or when a dependency bot upgrade caused CI failures that may be breaking changes needing investigation and fixing."
---

# Merge Dependency Updates

Analyze open dependency bot PRs, classify each by merge risk, recommend a merge order, and batch merge upon user confirmation.

## Workflow

### Step 1: Fetch Open Dependency PRs

```bash
gh pr list --author "app/renovate" --state open --json number,title,labels,additions,deletions,mergeable,headRefName --limit 50
gh pr list --author "app/dependabot" --state open --json number,title,labels,additions,deletions,mergeable,headRefName --limit 50
```

Combine results from both bots. Only process PRs authored by `app/renovate` or `app/dependabot` — never touch PRs opened by humans, even if they bump a dependency. If no bot PRs are found, inform the user and stop.

### Step 2: Analyse and Classify PRs (Parallel)

Dispatch one subagent per PR in parallel — do not run any `gh pr checks` or `gh pr diff` commands in the main context. If more than 20 PRs are found, dispatch in batches of 10. Wait for all results before proceeding.

Each subagent receives the PR number and must:

1. Fetch CI status:
   ```bash
   gh pr checks <number>
   ```
2. Fetch changed file names:
   ```bash
   gh pr diff <number> --name-only
   ```
3. Fetch the diff content:
   ```bash
   gh pr diff <number>
   ```
4. Assign a safety tier using these rules:

   | Tier | Label | Criteria |
   |------|-------|----------|
   | 1 | **Very Safe** | Patch version, lockfile-only changes (e.g. `package-lock.json`, `Gemfile.lock`, `poetry.lock`, `go.sum`, `gradle.lockfile`); for Maven, patch-only `pom.xml` with no source files touched |
   | 2 | **Safe** | Patch version touching manifest/config files but no source code (e.g. `package.json`, `Gemfile`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`) |
   | 3 | **Likely Safe** | Minor version bump, no breaking changes expected, only dependency files changed |
   | 4 | **Review Recommended** | Minor version bump touching source/config beyond dependency files, or CI failing |
   | 5 | **Caution** | Major version bump, changes to CI/workflow files, or merge conflicts |

   Identify the ecosystem from the files changed (Node/npm, Ruby/Bundler, Python/pip or Poetry, Go modules, Java/Maven, Java/Gradle, etc.). Note that Maven has no lockfile — version pins live entirely in `pom.xml`.

   Additional risk factors — apply these after the base tier:
   - **CI failures** — escalate one tier
   - **Pending stability / minimum age checks** (e.g. "minimum-release-age", "stability-days") — mark as `stability-hold`; do not recommend merging regardless of tier
   - **Merge conflicts** (`mergeable !== "MERGEABLE"`) — escalate to tier 5
   - **Source code changes** (anything outside lockfiles, manifests, or workflow files) — escalate one tier
   - **Workflow/CI file changes** (`.github/workflows/`, `.circleci/`, etc.) — minimum tier 4

5. Return a structured summary:
   - PR number and title
   - Version change (old → new) if detectable from the diff
   - Ecosystem (Node, Java/Maven, Go, etc.)
   - Assigned tier and label
   - CI status (pass / fail / pending / stability-hold)
   - List of risk factors flagged
   - Files changed count and types

### Step 3: Present Analysis

Present a summary table grouped by tier, from safest to riskiest:

```
## Dependency PR Analysis

### 1. Very Safe (patch, lockfile-only)
| # | PR Title | Version | Files | CI | Risk Notes |
|---|----------|---------|-------|----|------------|

### 2. Safe (patch with config)
...

### Recommended Merge Order
1. #123 - reason
2. #456 - reason
...
```

After the table, present a plain-language action plan and wait for explicit user approval before proceeding:

```
## Proposed Action Plan

**CI fix attempts** (isolated worktree per PR, up to 3 iterations each, run in parallel):
- #456 jest 2→3 — CI failing, will attempt automated fix

**Ready to merge** (tiers 1–3, CI passing):
- #123 lodash patch — Very Safe
- #789 axios patch — Safe

**Skipped** (manual review required):
- (none)

Reply "go" to proceed, or tell me which PRs to skip or handle differently.
```

Do not proceed to Step 4 or Step 5 until the user confirms.

### Step 4: Fix Failing PRs (Parallel)

For every PR with a CI failure, ask the user:
> "The following PRs have CI failures: [list]. Would you like me to attempt to diagnose and fix them in isolated worktrees?"

If the user confirms, dispatch one `fix-dependency-pr` agent per failing PR in parallel. Collect all results and present a summary:

```
## CI Fix Results

| PR | Dependency | Fix Status | Details |
|----|-----------|------------|---------|
| #123 | some-lib 4→5 | ✅ Fixed (1 iteration) | Updated call sites to renamed API |
| #456 | test-framework 2→3 | ❌ Too complex | 47 files affected — manual review needed |
```

Only PRs with status ✅ Fixed are eligible for merge in Step 5.

If the user declines, skip to Step 5 and leave those PRs unmerged.

### Step 5: Merge on Confirmation

Eligible PRs: tiers 1–3 (no CI failures) + any PR marked ✅ Fixed in Step 4. PRs marked "Needs manual review" are excluded.

Wait for explicit user confirmation, then merge sequentially in the recommended order:

1. Check the PR is still mergeable (a prior merge may have introduced conflicts):
   ```bash
   gh pr view <number> --json mergeable -q .mergeable
   ```
2. Approve if permitted:
   ```bash
   gh pr review <number> --approve
   ```
3. Merge:
   ```bash
   gh pr merge <number> --squash
   ```
4. Report each result. If a merge fails, report the error and continue.

### Error Handling

- If `gh pr review --approve` fails with permission errors, inform the user they need to approve manually or switch GitHub accounts
- If merge fails due to conflicts, suggest the user re-run the skill after branch updates
- Never force merge or bypass required checks
