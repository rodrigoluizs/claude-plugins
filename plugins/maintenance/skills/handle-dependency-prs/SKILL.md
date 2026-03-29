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

### Step 2: Gather Details for Each PR

For each PR, collect in parallel:

1. **CI status**: `gh pr checks <number>` — note any failures
2. **Files changed**: `gh pr diff <number> --name-only`
3. **Diff content**: `gh pr diff <number>` — scan enough to understand the change scope

If more than 20 PRs are found, gather details in batches of 10 to avoid API rate limits.

### Step 3: Classify Each PR

Assign a safety tier based on these criteria:

| Tier | Label | Criteria |
|------|-------|----------|
| 1 | **Very Safe** | Patch version, lockfile-only changes (e.g. `package-lock.json`, `Gemfile.lock`, `poetry.lock`, `go.sum`, `gradle.lockfile`); for Maven, patch-only changes to `pom.xml` with no source files touched |
| 2 | **Safe** | Patch version touching manifest / config files but no source code (e.g. `package.json`, `Gemfile`, `pyproject.toml`, `go.mod`, `pom.xml`, `build.gradle`) |
| 3 | **Likely Safe** | Minor version bump, no breaking changes expected, only dependency files changed |
| 4 | **Review Recommended** | Minor version bump touching source/config beyond dependency files, or CI failing |
| 5 | **Caution** | Major version bump, or changes to CI/workflow files, or merge conflicts |

Identify the ecosystem from the files changed (Node/npm, Ruby/Bundler, Python/pip or Poetry, Go modules, Java/Maven, Java/Gradle, etc.) and apply the lockfile/manifest criteria accordingly. Note that Maven has no lockfile — version pins live entirely in `pom.xml`.

Additional risk factors to flag:

- **CI failures** — always escalate one tier
- **Merge conflicts** (`mergeable !== "MERGEABLE"`) — escalate to tier 5
- **Source code changes** (anything outside lockfiles, manifests, or workflow files) — escalate one tier
- **Workflow/CI file changes** (`.github/workflows/`, `.circleci/`, etc.) — minimum tier 4

### Step 4: Present Analysis

Present a summary table grouped by tier, from safest to riskiest:

```
## Dependency PR Analysis

### 1. Very Safe (patch, lockfile-only)
| # | PR Title | Files | Risk Notes |
|---|----------|-------|------------|

### 2. Safe (patch with config)
...

### Recommended Merge Order
1. #123 - reason
2. #456 - reason
...
```

Include for each PR:
- PR number and title
- Version change (old → new)
- Files changed count and types
- CI status (pass/fail/none)
- Specific risk notes if any

After the table, present a plain-language action plan summarising exactly what will happen next and wait for explicit user approval before proceeding:

```
## Proposed Action Plan

**CI fix attempts** (worktree per PR, up to 3 iterations each):
- #456 jest 2→3 — CI failing, will attempt automated fix

**Ready to merge** (tiers 1–3, CI passing):
- #123 lodash patch — Very Safe
- #789 axios patch — Safe

**Skipped** (manual review required):
- (none)

Reply "go" to proceed, or tell me which PRs to skip or handle differently.
```

Do not proceed to Step 5 or Step 6 until the user confirms.

### Step 5: Attempt CI Fix for Failing PRs (Any Tier with CI Failures)

Before merging, for every PR with a CI failure (regardless of tier), offer to investigate and attempt an automated fix in an isolated worktree. Process each failing PR sequentially — do not run fix loops in parallel, as worktrees share the same git object store.

#### 5a: Ask the user

Present the list of CI-failing PRs and ask:
> "The following PRs have CI failures: [list]. Would you like me to attempt to diagnose and fix them in isolated worktrees?"

If the user declines, skip to Step 6 and leave those PRs unmerged.

#### 5b: Create a worktree per failing PR

For each failing PR, check it out into a temporary worktree:

```bash
gh pr checkout <number>
BRANCH=$(gh pr view <number> --json headRefName -q .headRefName)
WORKTREE="dep-fix-${number}"
git worktree add "$WORKTREE" "$BRANCH"
cd "$WORKTREE"
```

All subsequent commands for this PR run inside `$WORKTREE`.

#### 5c: Diagnose the CI failure

Fetch the detailed CI failure output for the PR:

```bash
gh pr checks <number> --watch=false
# For each failing check, get the run logs:
gh run view <run-id> --log-failed
```

Classify the failure type:

| Type | Signals | Likely fix |
|------|---------|------------|
| **Compilation / type error** | Type mismatch, missing export, renamed API | Update call sites to new API |
| **Test failure** | Snapshot mismatch, assertion value changed | Update snapshots / assertions |
| **Runtime breaking change** | Method removed, signature changed | Adapt usage to new API |
| **Config/schema change** | Invalid config key, deprecated option | Update config files |
| **Transitive conflict** | Two deps requiring incompatible peer | Pin or exclude conflicting version |

If the failure type cannot be determined or looks overly complex (many files across unrelated modules, no clear root cause after reading logs), **do not attempt a fix**. Report: "Could not determine root cause — manual review required" and skip to Step 5e.

#### 5d: Fix and iterate (max 3 iterations)

Apply the minimal fix to the affected files. Then commit and push:

```bash
# ... make changes inside the worktree ...
git add <affected files>
git commit -m "fix(<scope>): adapt to breaking change in <dependency> <new-version>"
git push
```

Wait for CI to re-run and check the result:

```bash
# Poll until checks complete (up to 10 minutes)
gh pr checks <number> --watch
```

If CI passes → done, mark this PR as "Fixed — ready to merge".

If CI still fails → re-read the new failure logs and apply another fix, up to **3 iterations total**.

After 3 failed iterations: stop, mark PR as "Needs manual review", and comment on the PR summarising what was attempted:
```bash
gh pr comment <number> --body "Automated fix attempted (3 iterations) but CI is still failing. Changes were reverted. Manual intervention needed."
```
Do **not** keep iterating blindly.

#### 5e: Clean up worktrees

After finishing each PR (success or giving up):

```bash
git worktree remove "dep-fix-${number}" --force
```

#### 5f: Report fix outcomes

Present a summary before proceeding to merge:

```
## CI Fix Results

| PR | Dependency | Fix Status | Details |
|----|-----------|------------|---------|
| #123 | some-lib 4→5 | ✅ Fixed (1 iteration) | Updated call sites to renamed API |
| #456 | test-framework 2→3 | ❌ Too complex | 47 files affected — manual review needed |
```

Only PRs with status ✅ Fixed are eligible for merge in Step 6.

---

### Step 6: Merge on Confirmation

Eligible PRs for merging: tiers 1–3 (no CI failures) + any PR marked ✅ Fixed in Step 5. PRs marked "Needs manual review" are excluded — inform the user they require manual intervention.

Wait for explicit user confirmation before merging. When confirmed:

1. Before merging each PR, check if its branch is still up to date with the base branch. If a prior merge has advanced the base, rebase first:
   ```bash
   gh pr view <number> --json mergeable -q .mergeable
   # if "CONFLICTING", ask the bot to rebase or do it manually before proceeding
   ```
2. If approval is required and the current `gh` auth user has permission, approve first:
   ```bash
   gh pr review <number> --approve
   ```
3. Merge sequentially in the recommended order:
   ```bash
   gh pr merge <number> --squash
   ```
4. Report the result of each merge (success/failure)
5. If any merge fails, report the error and continue with remaining PRs

### Error Handling

- If `gh pr review --approve` fails with permission errors, inform the user they need to approve manually or switch GitHub accounts
- If merge fails due to conflicts (base branch updated from prior merges), suggest the user re-run the skill after branch updates
- Never force merge or bypass required checks

## Output Format

Always present the analysis as a markdown table for quick scanning. Keep risk assessments concise — one line per PR with the key facts. Let the user make the final call on anything in tier 4-5.
