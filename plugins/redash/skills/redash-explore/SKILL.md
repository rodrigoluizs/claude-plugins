---
name: redash-explore
description: Browse and search existing Redash queries and dashboards. Use this sub-skill when the coordinator needs to check whether a query or dashboard already exists before building one from scratch. Not for direct user invocation.
---

# Redash Explore

Read-only skill for browsing existing queries and dashboards on `https://redash.data-bonial.com/`.

## Configuration

- Base URL: `https://redash.data-bonial.com`
- Auth header: `Authorization: Key $REDASH_API_KEY`

## Operations

### List queries

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/queries?page=1&page_size=25" | jq '.results[] | {id, name, description, updated_at}'
```

### Search queries by keyword

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/queries?q=<keyword>&page_size=10" | jq '.results[] | {id, name, description}'
```

### Get a single query

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/queries/<id>" | jq '{id, name, description, query, data_source_id, user: .user.name}'
```

### List dashboards

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/dashboards?page=1&page_size=25" | jq '.results[] | {id, slug, name}'
```

### Get a single dashboard

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/dashboards/<slug>" | jq '{id, name, widgets: [.widgets[]? | {id, options}]}'
```

## Output

- Present results as a concise list with IDs and names.
- If a result looks like a match to the user's intent, highlight it and offer to use it as a starting point.
- If no results match, return "No existing queries or dashboards found for this intent."
