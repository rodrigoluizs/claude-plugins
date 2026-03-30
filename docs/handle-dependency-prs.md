# handle-dependency-prs Workflow

Triage, fix, and merge open dependency bot PRs with minimal manual effort.

## Diagram

```mermaid
flowchart TD
    A[Fetch all open PRs] --> B[Filter by bot heuristics\nauthor · labels · branch · title]
    B --> C{Any bot PRs?}
    C -- No --> Z[Stop]
    C -- Yes --> D

    subgraph parallel1 [" Parallel "]
        D[analyze-dependency-pr\nPR #1]
        E[analyze-dependency-pr\nPR #2]
        F[analyze-dependency-pr\nPR #N]
    end

    D & E & F --> G[Present analysis table\n+ action plan]
    G --> H{User confirms?}
    H -- No / adjustments --> G

    H -- Yes, no CI failures --> M[Merge sequentially]

    H -- Yes, CI failures exist --> I{Fix them?}
    I -- No --> M

    subgraph parallel2 [" Parallel "]
        I -- Yes --> J[fix-dependency-pr\nPR #X]
        I -- Yes --> K[fix-dependency-pr\nPR #Y]
    end

    J & K --> L[Report fix outcomes]
    L --> M

    M --> N[Done]
```

## Steps

### 1. Fetch & Filter
Fetches all open PRs and identifies dependency bot PRs using heuristics: author login (`renovate`, `dependabot`, etc.), author type `Bot`, labels (`dependencies`), branch prefix (`dependabot/`, `renovate/`), and title patterns (`bump X from Y to Z`). Works with any Renovate or Dependabot installation, including custom bot names.

### 2. Analyse (Parallel)
Dispatches one `maintenance:analyze-dependency-pr` agent per PR. Each agent independently fetches CI status, diff, and changed files, then assigns a safety tier:

| Tier | Label | When |
|------|-------|------|
| 1 | Very Safe | Patch, lockfile-only |
| 2 | Safe | Patch, manifest/config only |
| 3 | Likely Safe | Minor version, dependency files only |
| 4 | Review Recommended | Minor version touching source, or CI failing |
| 5 | Caution | Major version, workflow changes, or conflicts |

### 3. Present & Confirm
Presents a grouped table and a proposed action plan. Waits for explicit user confirmation before proceeding.

### 4. Fix Failing PRs (Parallel, optional)
If any PRs have CI failures, dispatches one `maintenance:fix-dependency-pr` agent per PR. Each agent creates an isolated git worktree, diagnoses the failure, and iterates fixes (up to 3 attempts). Agents run in parallel.

### 5. Merge
Merges eligible PRs sequentially in the recommended order (safest first). Approves if permitted, checks mergeability before each merge.
