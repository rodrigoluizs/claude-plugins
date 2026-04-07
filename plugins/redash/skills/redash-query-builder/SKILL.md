---
name: redash-query-builder
description: Intent-driven query builder for non-technical users. Translates natural language into SQL by exploring available data sources and schemas. Use this sub-skill when the user wants to build a new query and no suitable existing query was found. Not for direct user invocation.
---

# Redash Query Builder

Builds and executes Redash queries from natural language intent. Designed for users who do not know SQL or the underlying data schema.

## Configuration

- Base URL: `https://redash.data-bonial.com`
- Auth header: `Authorization: Key $REDASH_API_KEY`

## Workflow

### Step 1 — Clarify intent

Confirm what the user wants to know in one sentence. Ask for missing context (time range, filters, groupings) in plain business terms before touching the API.

### Step 2 — List available data sources

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/data_sources" | jq '.[] | {id, name, type}'
```

Present the list to the user and ask which data source to use, or infer from intent if obvious.

### Step 3 — Fetch schema

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/data_sources/<id>/schema" | jq '.schema[] | {name, columns: [.columns[]?.name]}'
```

Identify the relevant tables and columns based on the user's intent. Explain which tables and fields you plan to use in plain language (not SQL) before writing the query.

**Partition field detection (critical for performance):** After identifying the target table, inspect its columns for any that look like partition fields — common names include `partition_date`, `year`, `month`, `day`, `hour`, `dt`, `date_partition`. If any are found, note them explicitly. They MUST be used in the WHERE clause of any query on that table.

### Step 4 — Draft SQL

Write the SQL query. If the target table has partition fields, always include them as WHERE predicates — this is required to avoid expensive full table scans. For time-based queries, derive the partition values from the requested time range (e.g. `partition_date = '2026-04-07'`).

Show the query to the user with a plain-language explanation of what it does, including a note if partition fields are being used for performance. Wait for confirmation before executing.

### Step 5 — Execute the query

Execute ad-hoc via a new query object:

**Create a draft query:**
```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"Draft - <intent summary>\", \"query\": \"<sql>\", \"data_source_id\": <id>, \"options\": {}}" \
  "https://redash.data-bonial.com/api/queries" | jq '{id, name}'
```

**Trigger execution:**
```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"max_age\": 0}" \
  "https://redash.data-bonial.com/api/queries/<query_id>/results" | jq '.'
```

**If a job is returned, poll until complete:**
```bash
# Poll every 2 seconds
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/jobs/<job_id>" | jq '{status, query_result_id, error}'
```

Job status codes: 1=PENDING, 2=STARTED, 3=SUCCESS, 4=FAILURE, 5=CANCELLED.

Poll up to 30 times (60 seconds total). If status is still PENDING or STARTED after 30 attempts, stop and tell the user: "The query is taking longer than expected. You can check the result later in Redash directly."

**Fetch result:**
```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/query_results/<result_id>" | jq '.query_result.data'
```

### Step 6 — Format and present results

- ≤ 50 rows: render as a markdown table.
- > 50 rows: show row count + column names + offer to save as `.csv` or `.json`:

```bash
curl -s -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/query_results/<result_id>.csv" -o results.csv
```

### Step 7 — Iterate if needed

If the results are wrong or incomplete, ask the user what to adjust in plain language. Update the SQL, re-execute, and repeat.

### Step 8 — Save

Ask the user if they want to save the query with a descriptive name. If yes, update the draft query:

```bash
curl -s -X POST \
  -H "Authorization: Key $REDASH_API_KEY" \
  -H "Content-Type: application/json" \
  -d "{\"name\": \"<user-approved name>\", \"description\": \"<brief description>\"}" \
  "https://redash.data-bonial.com/api/queries/<query_id>"
```

## Error Handling

- **Schema not available:** Inform the user; ask them to describe the table/column names they know.
- **Job FAILURE:** Show the error message from `job.error` in plain language. Offer to adjust the query.
- **HTTP 401/403:** Tell the user the API key may be invalid; suggest checking it at `https://redash.data-bonial.com/users/me`.
- **HTTP 5xx:** Retry the request once. If it fails again, surface the error.

## Permission Guard

When editing or deleting an existing query (as opposed to creating a new one), only proceed if the coordinator prompt explicitly states: "The user has confirmed permission to modify this resource." If this statement is absent, do not modify the query and tell the user to confirm via the coordinator.

## Delete Query

To archive (soft-delete) an existing query after coordinator permission is granted:

```bash
curl -s -X DELETE \
  -H "Authorization: Key $REDASH_API_KEY" \
  "https://redash.data-bonial.com/api/queries/<query_id>"
```

Inform the user that the query has been archived and can be restored from the Redash UI if needed.

## Tone

Always explain in business/data terms, not SQL terms. Instead of "I'm adding a GROUP BY clause", say "I'm grouping the results by country so you can see totals for each one."
