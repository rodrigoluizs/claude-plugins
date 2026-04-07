---
name: redash-dashboards
description: Create, edit, and manage Redash dashboards. Use this sub-skill when the user wants to create a new dashboard, add queries to a dashboard, or modify an existing dashboard. Requires coordinator-granted permission before modifying dashboards owned by other users. Not for direct user invocation.
---

# Redash Dashboards

Manages dashboards on `https://redash.data-bonial.com/`.

## Configuration

- Base URL: `https://redash.data-bonial.com`
- Auth header: `Authorization: Key $REDASH_API_KEY`

## Operations

### Create a new dashboard

```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"<dashboard name>\"}" \
  "https://redash.data-bonial.com/api/dashboards" | jq '{id, slug, name}'
```

### Add a widget (query visualization) to a dashboard

First get the visualization ID from the query:

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/queries/<query_id>" | jq '.visualizations[] | {id, type, name}'
```

Then add the widget:

```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"dashboard_id\": <dashboard_id>, \"visualization_id\": <viz_id>, \"options\": {}, \"text\": \"\"}" \
  "https://redash.data-bonial.com/api/widgets" | jq '{id}'
```

### Edit a dashboard name

```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"<new name>\"}" \
  "https://redash.data-bonial.com/api/dashboards/<dashboard_id>" | jq '{id, name}'
```

### Archive a dashboard

```bash
curl -s -X DELETE \
  -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/dashboards/<dashboard_slug>"
```

## Permission Guard

This sub-skill only operates on resources for which the coordinator has already confirmed permission. Do not modify or archive any dashboard unless the coordinator prompt explicitly states permission was granted.

## Output

After any create/edit operation, return the dashboard URL:
`https://redash.data-bonial.com/dashboard/<slug>`
