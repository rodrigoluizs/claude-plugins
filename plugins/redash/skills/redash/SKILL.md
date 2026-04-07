---
name: redash
description: "Interact with Redash to explore data, build queries, and manage dashboards. Use this skill whenever the user mentions Redash, wants to query data, build a report, explore available data sources, or create/manage dashboards. Triggers on: query, dashboard, data source, redash, create a report, show me the data, how many X, what is the total, build a query, explore data."
---

# Redash Coordinator

Entry point for all Redash interactions at `https://redash.data-bonial.com/`.

## Before Anything Else: Check API Key

```bash
echo $REDASH_API_KEY
```

If empty or unset, stop and tell the user:

> "Your Redash API key is not configured. Get it from [Settings > Account](https://redash.data-bonial.com/users/me) and set it as the `REDASH_API_KEY` environment variable."

Do not proceed until the key is present.

## Get Current User (Once Per Session)

Fetch the current user once and remember the `id` field for the rest of the session. Do not re-fetch on subsequent permission checks — reuse the cached value.

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/users/me" | jq '{id, name, email}'
```

Store the returned `id` as `CURRENT_USER_ID` for use in permission checks below.

## Intent Routing

Understand the user's intent and route to the appropriate sub-agent:

| Intent | Sub-skill to load |
|---|---|
| "is there already a query for X?" / "find a dashboard about Y" | `redash-explore` |
| "I want to know X" / "build a query for Y" / "create a report" | `redash-explore` first, then `redash-query-builder` if nothing found |
| "how many X" / "what is the total of Y" / "show me the data for Z" | `redash-explore` first, then `redash-query-builder` if nothing found |
| "create a dashboard" / "add this query to a dashboard" | `redash-dashboards` |
| "edit/delete this dashboard" | Check permission, then `redash-dashboards` |
| "edit/delete this query" | Check permission, then `redash-query-builder` |

## Permission Check (Before Any Mutating Operation on Existing Resources)

For any edit or archive on an existing resource:

1. Fetch the resource and extract `created_by_id` (queries) or `user_id` (dashboards).
2. Compare with the cached current user ID.
3. If they match: proceed directly.
4. If they don't match: ask the user:
   > "This [query/dashboard] was created by [name]. Are you sure you want to modify it?"
   Wait for explicit confirmation before proceeding.

## Launching Sub-agents

Load sub-skill content into the sub-agent prompt. The sub-agent is a `general-purpose` agent with access to all tools.

**Template prompt for sub-agents:**

```
You are a Redash assistant. Follow these instructions exactly:

<contents of the relevant SKILL.md>

The user's request is: <user's original message>
[If permission was granted for a mutating operation, add: "The user has confirmed permission to modify this resource."]
```

## After Sub-agent Returns

- Present results directly without re-summarizing unless the output is very long.
- Offer natural next steps: "Want to save this query?", "Should I add it to a dashboard?", "Want to refine the results?"
