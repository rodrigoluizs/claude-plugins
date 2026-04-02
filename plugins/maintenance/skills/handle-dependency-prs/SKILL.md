---
name: "handle-dependency-prs"
description: "Use when reviewing, triaging, or merging open PRs from dependency bots (e.g. Renovate, Dependabot), or when the user asks to handle dependency updates, merge dependency PRs, or when a dependency bot upgrade caused CI failures that may be breaking changes needing investigation and fixing."
---

# Merge Dependency Updates

Analyze open dependency bot PRs, classify each by merge risk, recommend a merge order, and batch merge upon user confirmation.

## Workflow

### Step 1: Fetch Open Dependency PRs

```bash
gh pr list --state open --json number,title,author,labels,additions,deletions,mergeable,headRefName --limit 100
```

From the results, identify dependency bot PRs using these signals — any match is sufficient:

- **Author login** contains: `renovate`, `dependabot`, `depfu`, `snyk-bot`, `whitesource`, `mend`
- **Author type** is `Bot`
- **Labels** include: `dependencies`, `dependency`, `renovate`, `dependabot`
- **Branch name** starts with: `dependabot/`, `renovate/`, `deps/`
- **Title** matches patterns like: `chore(deps):`, `bump X from Y to Z`, `update dependency X`

Never include PRs opened by humans, even if they bump a dependency. If no dependency bot PRs are found, inform the user and stop.

### Step 2: Analyse and Classify PRs (Parallel)

Your only job in this step is to build the list of PR numbers from Step 1 and invoke one `maintenance:analyze-dependency-pr` agent per PR. Do nothing else — no `gh` commands, no diff reading, no classification. All of that happens inside the agent.

If more than 20 PRs are found, invoke agents in batches of 10. Wait for all results before proceeding.

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

If the user confirms, dispatch one `maintenance:fix-dependency-pr` agent per failing PR in parallel. Collect all results and present a summary:

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
