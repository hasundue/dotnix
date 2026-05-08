---
name: SKILL_NAME
description: >-
  SHORT_DESCRIPTION
---

# SKILL_TITLE

DESCRIPTION. Powered by [API](API_URL). Uses the official SDK.

## Setup

- [Deno](https://deno.com) on `$PATH`
- API key via `API_KEY` env var (or `API_KEY_FILE` pointing to a file)

```bash
export API_KEY="..."
# or
export API_KEY_FILE="/path/to/secret"
```

Get a key at [dashboard](DASHBOARD_URL).

## Search

```bash
./script.ts "query"
./script.ts "query" --num-results 5
```

## Options

| Flag            | Default | Description       |
| --------------- | ------- | ----------------- |
| `--num-results` | `10`    | Number of results |
| `--verbose`     | `false` | Include metadata  |
| `--help`        | —       | Show help         |

Output is compact by default. Use `--verbose` for full output.

## Reference

- [API docs](API_DOCS_URL)
- [Dashboard](DASHBOARD_URL)
