---
name: "dep-review"
description: "This skill should be used when the user wants to review, triage, or merge open dependency update PRs from Renovate or Dependabot. It classifies each PR by merge safety, recommends a merge order, and batch merges on confirmation. Triggers include: 'merge renovate PRs', 'review dependency updates', 'triage dependabot PRs', 'batch approve dependency bumps', 'merge deps', 'upgrade dependencies', 'update deps'."
---

# Merge Dependency Updates

Analyze open dependency bot PRs, classify each by merge risk, recommend a merge order, and batch merge upon user confirmation.

## Workflow

### Step 1: Fetch Open Dependency PRs

```bash
gh pr list --author "app/renovate" --state open --json number,title,labels,additions,deletions,mergeable,headRefName --limit 50
gh pr list --author "app/dependabot" --state open --json number,title,labels,additions,deletions,mergeable,headRefName --limit 50
```

Combine results from both bots. If no PRs are found, inform the user and stop.

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
| 1 | **Very Safe** | Patch version, lockfile-only changes (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`) |
| 2 | **Safe** | Patch version touching `package.json` / config files but no source code |
| 3 | **Likely Safe** | Minor version bump, no breaking changes expected, only dependency files changed |
| 4 | **Review Recommended** | Minor version bump touching source/config beyond dependency files, or CI failing |
| 5 | **Caution** | Major version bump, or changes to CI/workflow files, or merge conflicts |

Additional risk factors to flag:

- **CI failures** — always escalate one tier
- **Merge conflicts** (`mergeable !== "MERGEABLE"`) — escalate to tier 5
- **Source code changes** (anything outside lockfiles, `package.json`, workflow files) — escalate one tier
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

### Step 5: Merge on Confirmation

Wait for explicit user confirmation before merging. When confirmed:

1. If approval is required and the current `gh` auth user has permission, approve first:
   ```bash
   gh pr review <number> --approve
   ```
2. Merge sequentially in the recommended order:
   ```bash
   gh pr merge <number> --squash
   ```
3. If merge fails with "clean status" error (auto-merge not needed), retry without `--auto`:
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
