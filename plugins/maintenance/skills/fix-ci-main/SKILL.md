---
name: fix-ci-main
description: "Use when CI on the main branch is failing (security scans, linters, tests, builds), when grype/trivy/megalinter report vulnerabilities, or when dependency upgrades are needed to fix CI. KEYWORDS: fix ci, main failing, grype, trivy, megalinter, security scan, vulnerability, CVE, GHSA, dependency upgrade, fix linter, broken main."
---

# Fix CI on Main

Create an isolated worktree from main, trigger CI via a draft PR, analyze failures, fix them, and iterate until green.

## Workflow

```dot
digraph fix_ci {
    rankdir=TB;
    start [label="Create worktree from main" shape=box];
    commit [label="Make trivial commit\nthat triggers CI paths" shape=box];
    pr [label="Push + create draft PR" shape=box];
    wait [label="Wait for all CI checks" shape=box];
    check [label="All checks green?" shape=diamond];
    analyze [label="Analyze failure logs" shape=box];
    fix [label="Fix, commit, push" shape=box];
    done [label="Squash commits\nUpdate PR title/description\nMark ready for review" shape=box];

    start -> commit -> pr -> wait -> check;
    check -> done [label="yes"];
    check -> analyze [label="no"];
    analyze -> fix -> wait;
}
```

### 1. Create Worktree

Fetch the latest `main` (`git fetch origin main`) and use the `superpowers:using-git-worktrees` skill to create an isolated workspace based on `origin/main`.

### 2. Trigger CI

Make a minimal change that matches CI workflow path triggers. Check `.github/workflows/` for `paths:` filters to know which files to touch.

### 3. Create Draft PR

Push the branch and create a **draft** PR to trigger all CI workflows.

### 4. Wait, Analyze, Fix, Repeat

Wait for all CI checks to complete. For each failure, read the job logs, identify the root cause, fix it, commit, push, and wait again. Repeat until all checks are green.

### 5. Finalize

Once all checks pass: squash commits into a single clean commit, update the PR title and description to reflect the actual fix, and mark the PR as ready for review.
