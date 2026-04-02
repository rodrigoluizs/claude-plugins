---
name: create-prd
description: This skill should be used when the user asks to "create a PRD", "write a product requirement document", "draft a PRD", "new feature PRD", "product requirements", "create product spec", "write product spec", "define a feature", "document a feature", "write feature requirements", or needs to define a feature from a product perspective and create a GitHub issue for it.
---

# Create PRD (Product Requirement Document)

## Overview

Create a non-technical Product Requirement Document by interviewing the user about all relevant product aspects, then publish it as a GitHub issue in the current repository.

## Workflow

### Phase 1: Identify the Feature

Start by asking the user what feature or product idea they want to document. If they already provided it in the initial prompt, acknowledge it and move to Phase 2.

### Phase 2: Interview

Conduct a structured interview using `AskUserQuestion`. Cover all the sections below, one or two topics per question round. Adapt follow-up questions based on previous answers. Do NOT ask obvious or redundant questions — dig deeper into what matters.

**Interview topics (in order):**

1. **Problem & Motivation** — What problem does this solve? Why now? What happens if we don't build it?
2. **Target Users** — Who are the primary users? Are there secondary users? What do they currently do to solve this problem?
3. **Desired Outcome** — What does success look like from the user's perspective? What should change for them?
4. **Key User Stories** — Walk through 2-4 concrete scenarios of how users would interact with this feature. What triggers them to use it? What do they expect to happen?
5. **Scope Boundaries** — What is explicitly IN scope? What is explicitly OUT of scope for this version?
6. **Success Metrics** — How do we measure if this feature is successful? What KPIs or signals matter?
7. **Constraints & Dependencies** — Are there business constraints, deadlines, legal requirements, or dependencies on other teams/features?
8. **Risks & Open Questions** — What could go wrong? What are we unsure about? What needs further research?
9. **Priority & Urgency** — How important is this relative to other work? Is there a deadline or event driving timing?

**Interview guidelines:**
- Use `AskUserQuestion` with concrete options when possible (e.g., priority levels, user segments).
- Ask one to two topics per round to avoid overwhelming the user.
- Use follow-up questions to clarify vague answers — don't accept surface-level responses.
- Skip topics the user has already clearly addressed.
- The interview is complete when all relevant topics have been covered or the user signals they want to wrap up.

### Phase 3: Draft the PRD

Compile the interview answers into the following markdown template. Write in clear, concise language. Do NOT include technical implementation details — focus purely on the product and user perspective.

```markdown
# [Feature Name]

## Problem Statement
[What problem does this solve and why does it matter]

## Target Users
[Who this is for, their context, and current behavior]

## Desired Outcome
[What success looks like from the user's perspective]

## User Stories
- **As a** [user type], **I want** [action] **so that** [benefit]
- ...

## Scope

### In Scope
- ...

### Out of Scope
- ...

## Success Metrics
- ...

## Constraints & Dependencies
- ...

## Risks & Open Questions
- ...

## Priority
[Priority level and reasoning]
```

### Phase 4: Review

Present the drafted PRD to the user. Ask if they want to adjust, add, or remove anything. Iterate until the user approves.

### Phase 5: Create GitHub Issue

1. Detect the current repository using `git remote get-url origin`.
2. Create a GitHub issue using `gh issue create` with:
   - **Title:** `[PRD] <Feature Name>`
   - **Body:** The full PRD markdown content
   - **Labels:** Add a `prd` label. If the label does not exist, create it first with `gh label create prd --description "Product Requirement Document" --color "5319E7"`.
3. Return the issue URL to the user.

## Important Notes

- All content must be written in English regardless of the interview language.
- Keep the language non-technical and product-focused. No architecture, APIs, or implementation details.
- If the user provides arguments when invoking the skill, treat them as the initial feature description and skip Phase 1.
- Keep the PRD concise — avoid padding or repeating information across sections.
