---
name: ketch
description: >
  Use the `ketch` CLI from `bash` for all external research — web pages, OSS
  code, and library docs. Activates when the user needs information that the
  agent cannot derive from its training data: current web pages, real-time
  search results, OSS code snippets with repository context, or library
  documentation. Also use when the user asks for research, lookups, source
  code from a specific repository, or library API details.
---

# Ketch CLI — External Research Tool

Use `ketch` CLI from `bash` for all external research — web pages, OSS code,
library docs. ketch is a fast, stateless CLI that provides three search surfaces
(web, code, docs), scraping/crawling, HTML→markdown extraction, and bookmarking
(tags) — one binary, no daemon.

## Prerequisites

The `ketch` CLI is already configured and installed. The operator has configured
the search/code/docs backends. **Do not override or reconfigure** **them**
unless you have a specific reason.

To inspect the active configuration and available backends at any time:

```bash
ketch config
```

This returns the effective configuration as JSON — search backend, code backend,
docs backend, token sources, cache TTL, etc.

When a command errors, returns nothing, or a backend looks broken, run the
read-only health check (it probes every backend concurrently and prints fix
hints; exit code 5 means a required surface is broken):

```bash
ketch doctor          # human-readable
ketch doctor --json   # structured
```

---

## Commands

### Web Search

Search the web and get titles, URLs, and snippets:

```bash
ketch search "<query>"
```

Search and fetch full content from each result in one pass:

```bash
ketch search "golang error handling" --scrape
```

**When to fetch:** the snippet from a plain `search` is often enough — prefer it
for browsing, it costs nothing extra. Only read pages you actually need: take
URLs from a plain search and batch them through `ketch scrape <url> <url> ...`
once. Reserve `search --scrape` for "give me every result's content in one pass"
— it fetches all results, so failures (403, JS shells) multiply too.

Customize the number of results:

```bash
ketch search "query" --limit 10
```

Select a specific search backend (the default is configured by the operator):

```bash
ketch search "query" --backend exa       # verified working keyless
ketch search "query" --backend parallel
# Backends: auto, brave (default), ddg, searxng, exa, firecrawl, keenable,
#           tavily, parallel, serpbase, degoog, serply, youcom
# Which are usable right now: ketch doctor
```

Federated search across several providers (rank-fused), or a random provider
with fallback. Both are mutually exclusive with `--backend`:

```bash
ketch search "query" --multi=brave,exa      # or --multi for every usable backend
ketch search "query" --random=exa,parallel,keenable   # survives one provider failing
```

Compact output for agent parsing:

```bash
ketch search "query" --minimal   # one result per line: url \t title \t snippet
ketch search "query" --trim      # strip markdown formatting from scraped content
ketch search "query" --max-chars 4000   # truncate scraped markdown
```

> **Rate limits — do not call in parallel.** The default `brave` backend is
> rate-limited (~1 request/second plus a monthly quota). **Never issue multiple
> `ketch search` calls concurrently** — run them sequentially or space them out.
> If you get a `brave: rate limited` (HTTP 429) error, wait a moment and retry;
> if it persists, switch backend — verified working keyless: `exa`, `keenable`,
> `parallel`, `youcom` (e.g. `--backend exa`), or use `--random=exa,parallel`
> for automatic fallback. **Currently broken fallbacks:** `ddg` fails with "rate
> limited after retries", `firecrawl` keyless 403s (VPN/proxy IP), `searxng`
> needs a running instance at `searxng_url`. Health check: `ketch doctor`.

---

### Scrape a URL

Fetch a single URL and return clean markdown:

```bash
ketch scrape https://go.dev/doc/effective_go
```

**Batch scrape** — fetch multiple URLs concurrently:

```bash
ketch scrape https://example.com https://go.dev
```

Input is auto-detected — args, a JSON array, a file of URLs, or stdin all work:

```bash
ketch scrape urls.txt
ketch scrape '["https://example.com","https://go.dev"]'
printf 'https://example.com\nhttps://go.dev\n' | ketch scrape
```

Useful flags:

```bash
ketch scrape https://example.com --raw            # raw HTML instead of markdown
ketch scrape https://example.com --no-cache       # bypass the page cache
ketch scrape https://example.com --select "article"  # CSS selector, skips readability
ketch scrape https://example.com --trim           # keep content text only
ketch scrape https://example.com --max-chars 4000 # truncate output
ketch scrape https://example.com --force-browser  # always render via the browser
```

If a site blocks the default fetch, `--user-agent <ua>` and
`--cookie-file <cookies.txt>` override the configured values per call. Some
sites hard-fail regardless (e.g. Medium returns HTTP 403) — report it and fall
back to the search snippet instead of retrying; JS shells need a browser (see
below).

---

### Crawl a Website

Crawl entire sites via BFS (breadth-first) link discovery or sitemaps:

```bash
# BFS crawl from a seed URL, default depth 3
ketch crawl https://example.com --depth 3
```

```bash
# Sitemap-based crawl (discovers pages from the sitemap)
ketch crawl https://example.com/sitemap.xml --sitemap
```

```bash
# Run in background with status tracking
ketch crawl https://example.com/sitemap.xml --sitemap --background
```

Control the crawl with additional options:

```bash
# Path substring filters (any match passes)
ketch crawl https://example.com --allow /docs,/api

# Regex deny patterns
ketch crawl https://example.com --deny "\.pdf$" --deny "/private/"

# Worker pool size
ketch crawl https://example.com --concurrency 8
```

Check crawl status or stop a running crawl:

```bash
ketch crawl status              # list all crawls
ketch crawl status c_a1b2c3d4   # check a specific crawl
ketch crawl stop c_a1b2c3d4     # stop a running crawl
```

Crawled pages are cached — re-running the same crawl returns instantly from
cache. Use `--no-cache` to force re-fetch.

---

### Code Search

Search real source code across open-source repositories with line numbers, repo
info, and star counts. Three backends are available (default chosen by
`ketch config set code_backend <name>`):

**Sourcegraph** (default) — zero config, anonymous streaming API, no auth and no
separate quota for star counts. Archived repos and forks are excluded by default
(add `archived:yes` / `fork:yes` to the query to include them):

```bash
ketch code "http.NewRequestWithContext" --lang go
ketch code "rate.?limit" --lang go --regex
```

Very common patterns may be truncated by Sourcegraph's match limit regardless of
`--limit` (the response reports `shard-match-limit`) — narrow the query instead.

**Grep.app** — zero config alternative (literal/regex over 1M+ public repos),
but it intermittently returns HTTP 504 (~half of calls). On failure, wait a
second, retry once, then fall back:

```bash
ketch code "rate limit middleware" --lang python -b grepapp
```

**GitHub Code Search** — authenticated, reliable fallback; uses the GitHub REST
API with batched GraphQL stargazer lookups. Authentication is resolved from (in
order): explicit config → `$GITHUB_TOKEN` → `$GH_TOKEN` → `gh auth token` (if
`gh` CLI is installed):

```bash
ketch code "http.NewRequestWithContext" --lang go -b github
ketch code "rate limit middleware" --lang go -b github --limit 10
```

Caveats: 30 req/min cap, index covers the **default branch only**, `--regex` is
not supported (Sourcegraph/Grep.app only). Results carry no line numbers on this
backend.

Each result shows: matched line, repository, file path, star count, and a
permalink. Add `--minimal` for one tab-separated result per line. If all
backends fail, run `ketch doctor`.

---

### Library Docs

Fetch curated, version-aware documentation snippets via Context7:

```bash
# Auto-resolve the library from the query
ketch docs "middleware authentication"

# Fetch directly from a known library ID (skips resolution)
ketch docs "how to render with word wrap" --library /charmbracelet/glamour

# List matching library IDs without fetching docs
ketch docs --resolve "glamour"

# Control the token budget for results
ketch docs "middleware authentication" --tokens 6000
```

The operator has already configured the Context7 API key. Do not override it.

---

### Extract HTML → Markdown (no fetching)

`extract` never fetches, caches, or renders — it only converts HTML on stdin
with the same pipeline `scrape` uses (useful with `curl`/`xclip`):

```bash
curl -L https://example.com | ketch extract
curl -L https://example.com | ketch extract --url https://example.com
cat page.html | ketch extract --select article --max-chars 4000
```

---

### Tags (bookmark research sources)

Any of `search`, `code`, `docs`, `scrape`, `crawl` accepts `--tag <name>` to
record results under a label. Bookmarks keep their URL, title, and description
after the page cache expires or is cleared — ideal for cross-session research:

```bash
ketch scrape https://example.com/docs --tag my-project
ketch tag add my-project https://another.example/page   # no fetch required
ketch tag show my-project --limit 20                    # llms.txt-shaped index
ketch tag list
ketch tag remove my-project https://example.com/docs
```

---

## JavaScript-Rendered Pages (Browser)

JS-rendered pages (React SPAs, Salesforce Lightning, etc.) are automatically
detected and re-fetched via headless Chrome **when a browser is configured**. No
special action is needed when scraping or crawling — if a page returns a loading
shell, ketch transparently uses the browser.

Browser rendering is optional — check before relying on it:

```bash
ketch browser status
ketch doctor          # reports browser as "skipped" when not configured
```

If browser management is needed (e.g., to install Chromium or check status):

```bash
# Value = a PATH-resolvable executable name or an absolute path
# ("chrome" fails with exec: "chrome": executable file not found — use:)
ketch config set browser google-chrome    # or chromium, or /abs/path/to/chrome

# Or install Chromium to ketch's cache dir
ketch browser install
```

Static pages always use the plain-HTTP fast path (~0.2s) — the browser only runs
when a JS shell is detected (or `--force-browser`).

### What a browser does NOT fix (verified 2026-10)

- **Bot walls / WAF**: Reddit rendered, but served "Prove your humanity" — a
  challenge page, not the article. Headless Chrome is detectable.
- **HTTP 403 / IP-geo blocks**: Medium still 403s with a browser (same IP).
- **Login / paywall content**: needs cookies — `--cookie-file <cookies.txt>`; a
  browser alone shows the login page.
- **Interaction-only content**: infinite scroll, tab/accordion clicks, form
  input — a single page load never performs them.
- **PDFs**: with a text layer they are read natively (an arXiv paper came back
  fully extracted) — but layout reconstruction is naive, so words/columns jam
  together; grep the output rather than reading it verbatim. **Scanned /
  image-only PDFs return garbage** (measured: 6 tokens of noise, no error) —
  those need an OCR-capable `external_pdf_to_md_converter_command`, which is
  unset here (persist any change in dotnix's ketch generator — `config set`
  won't survive a login). And never hand a PDF to the `read` tool: it treats it
  as text and dumps the raw bytes (measured) — extract via ketch or render to
  PNG first.

A browser only solves the "page is a loading shell" class. When it returns a
challenge/login page instead of content, say so rather than treating it as
content.

When no browser is configured, JS-heavy pages return their loading shell —
report that instead of guessing, or use `ketch scrape --force-browser` after the
operator has configured one.

Note: for bare domains ketch automatically prefers `/llms.txt` when the site
offers one (often better than rendering); disable with `--no-llms-txt`.

---

## Structured Output

All commands support `--json` for structured JSON output suitable for piping:

```bash
ketch search "<query>" --json
ketch code "<query>" --lang go --json
ketch scrape https://example.com --json
ketch config --json
```

`--minimal` gives one tab-separated record per line when you only need
URLs/snippets — cheaper to parse than full JSON.

---

## MCP

`ketch mcp serve` exposes the same search/code/docs/scrape/crawl/tag
capabilities as MCP tools over stdio. Prefer the CLI from `bash` unless an MCP
client is explicitly requested.

---

## Configuration

The operator has already configured ketch. The configuration is stored at
`~/.config/ketch/config.json`. Flags always override config values.

> **`config set` is temporary.** `ketch-config.service` (agenix + dotnix
> `configs/home/ketch.nix`) rewrites `config.json` from scratch at every login
> and home-manager switch — only the keys in that jq template survive. To make a
> setting permanent, add it there; otherwise `ketch config set <key> <value>`
> lasts only until the next login.

To view the effective config and available backends:

```bash
ketch config
ketch config path      # print the config file path
ketch config set <key> <value>
```

Abridged example output (see `ketch config` for the full payload, including
per-backend `*_api_key_set` flags):

```json
{
  "config_path": "/home/user/.config/ketch/config.json",
  "backend": "brave",
  "code_backend": "sourcegraph",
  "docs_backend": "context7",
  "limit": 5,
  "cache_ttl": "72h",
  "extract_mode": "clean",
  "available_backends": [
    "auto",
    "brave",
    "ddg",
    "searxng",
    "exa",
    "firecrawl",
    "keenable",
    "tavily",
    "parallel",
    "serpbase",
    "degoog",
    "serply",
    "youcom"
  ],
  "available_code_backends": ["grepapp", "sourcegraph", "github"],
  "available_doc_backends": ["context7"]
}
```

### Search Backends

| Backend                                 | Setup                | Notes                                                                                                                |
| --------------------------------------- | -------------------- | -------------------------------------------------------------------------------------------------------------------- |
| `auto`                                  | —                    | Let ketch pick the first usable backend                                                                              |
| `brave`                                 | Free API key         | Default. Rate-limited (~1 req/s + monthly quota) — avoid parallel calls; on 429 retry or switch to `exa`/`parallel`. |
| `ddg`                                   | Zero config          | **Currently broken as a fallback** — fails with "rate limited after retries"                                         |
| `searxng`                               | Self-hosted instance | Needs a running instance at `searxng_url` (currently unreachable — localhost:8081 not running)                       |
| `exa`, `keenable`, `parallel`, `youcom` | API key / service    | **Verified working keyless (2026-10)** — first choices when `brave` 429s                                             |
| `firecrawl`                             | API key              | Keyless tier 403s from this IP (VPN/proxy block) — unusable without a key                                            |
| `tavily`, `serpbase`, `serply`          | Free API key         | Report `no_key` until you `ketch config set <name>_api_key <key>` (operator task — do not do this unprompted)        |
| `degoog`                                | Self-hosted URL      | Needs `degoog_url`                                                                                                   |

### Code Backends

| Backend       | Setup                                                    | Notes                                                                                        |
| ------------- | -------------------------------------------------------- | -------------------------------------------------------------------------------------------- |
| `sourcegraph` | Zero config                                              | **Default.** Anonymous stream API, line numbers + stars, archived/forks excluded by default  |
| `grepapp`     | Zero config                                              | mcp.grep.app, literal/regex over 1M+ public repos. Intermittent 504 — retry, then fall back  |
| `github`      | `gh auth login` or `ketch config set github_token <tok>` | REST `/search/code` + GraphQL stars batch, 30 req/min cap, default branch only, no `--regex` |

### Docs Backends

| Backend    | Setup                                     | Notes                                             |
| ---------- | ----------------------------------------- | ------------------------------------------------- |
| `context7` | `ketch config set context7_api_key <key>` | Curated snippets + prose, version-aware (default) |
| `local`    | `ketch docs index <source>`               | FTS5 SQLite, offline/private docs (planned)       |

---

## Cache

ketch caches fetched pages and search results. Cache TTL defaults to 72h.

```bash
# Show cache stats
ketch cache

# Clear cached pages
ketch cache clear
```
