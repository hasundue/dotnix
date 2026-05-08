---
name: exa-search
description: >-
  Web search and content extraction via the Exa AI search API. Use for real-time web
  search, documentation lookups, API reference searches, code example discovery,
  content extraction from known URLs, and structured data extraction.
---

# Exa Search

Neural web search and content extraction powered by [Exa](https://exa.ai). Uses
the official `exa-js` SDK (pinned to `2.12.1`) via a Deno helper script.

## Setup

### Prerequisites

- [Deno](https://deno.com) installed and on `$PATH`
- An Exa API key, provided through one of:
  - `EXA_API_KEY` environment variable (takes precedence)
  - `EXA_API_KEY_FILE` environment variable pointing to a file containing the
    key

```bash
# Set your Exa API key directly
export EXA_API_KEY="your-api-key-here"

# Or point at a file (e.g. an agenix-managed secret)
export EXA_API_KEY_FILE="/path/to/secret/file"
```

Get an API key at [dashboard.exa.ai](https://dashboard.exa.ai).

## Search

Basic search with highlights (token-efficient excerpts — ideal for LLM
workflows):

```bash
./search.ts "your search query"
```

Customize number of results and search type:

```bash
./search.ts "query" --num-results 5 --type auto
# Types: auto, fast, instant, deep-lite, deep, deep-reasoning
```

Get full page text content (use `maxCharacters` to control token cost):

```bash
./search.ts "query" --text --max-chars 5000
```

Summaries per result:

```bash
./search.ts "query" --summary
```

## Content Extraction

Get clean content for URLs you already have:

```bash
./search.ts --urls https://example.com/article https://example.com/blog
```

With freshness control (livecrawl if cached content is older than N hours):

```bash
./search.ts --urls https://example.com --max-age-hours 24
```

## Structured Outputs (outputSchema)

Get grounded structured JSON from search results with field-level citations:

```bash
./search.ts "query" --schema '
{
  "type": "object",
  "properties": {
    "key_points": {
      "type": "array",
      "items": { "type": "string" }
    }
  }
}'
```

The response includes `output.content` (structured JSON) and `output.grounding`
(citations per field).

## Domain Filtering

Target specific sources or exclude low-quality domains:

```bash
./search.ts "query" --include-domains arxiv.org,github.com
./search.ts "query" --exclude-domains pinterest.com,medium.com
```

## Date Filtering

```bash
./search.ts "query" --start-published-date 2025-01-01 --end-published-date 2025-12-31
```

## All Options

| Flag                     | Default | Description                                                                   |
| ------------------------ | ------- | ----------------------------------------------------------------------------- |
| `--num-results`          | `10`    | Number of results (1–100)                                                     |
| `--type`                 | `auto`  | Search type: `auto`, `fast`, `instant`, `deep-lite`, `deep`, `deep-reasoning` |
| `--text`                 | `false` | Include full page text                                                        |
| `--max-chars`            | `2000`  | Max characters per page when `--text` is set                                  |
| `--summary`              | `false` | Include per-result summaries                                                  |
| `--highlights`           | `true`  | Include query-relevant excerpts (default on)                                  |
| `--schema`               | —       | JSON Schema for structured output (outputSchema)                              |
| `--include-domains`      | —       | Comma-separated list of domains to include                                    |
| `--exclude-domains`      | —       | Comma-separated list of domains to exclude                                    |
| `--start-published-date` | —       | ISO date string (e.g. `2024-01-01`)                                           |
| `--end-published-date`   | —       | ISO date string                                                               |
| `--max-age-hours`        | —       | Max age of cached content in hours (0 = always livecrawl, -1 = cache only)    |
| `--urls`                 | —       | Space-separated list of URLs to extract content from (uses `/contents`)       |

## Reference

- [Exa API docs](https://docs.exa.ai/reference/search-api-guide-for-coding-agents)
- [Exa dashboard](https://dashboard.exa.ai)
- [API status](https://status.exa.ai)
