#!/usr/bin/env -S deno run --allow-net --allow-env=EXA_API_KEY,EXA_API_KEY_FILE --allow-read

/**
 * Exa Search & Contents — Deno helper using the official exa-js SDK.
 *
 * Usage:
 *   ./search.ts "query"
 *   ./search.ts "query" --num-results 5 --type deep
 *   ./search.ts --urls https://example.com
 *   ./search.ts "query" --schema '{ "type": "object", ... }'
 *
 * Environment:
 *   EXA_API_KEY       — the API key directly (takes precedence)
 *   EXA_API_KEY_FILE  — path to a file containing the API key (fallback)
 */

import { Exa } from "npm:exa-js@2.12.1";

function getApiKey(): string {
  const direct = Deno.env.get("EXA_API_KEY");
  if (direct) return direct;

  const keyFile = Deno.env.get("EXA_API_KEY_FILE");
  if (keyFile) {
    try {
      return Deno.readTextFileSync(keyFile).trim();
    } catch {
      console.error(`Error: could not read EXA_API_KEY_FILE: ${keyFile}`);
      Deno.exit(1);
    }
  }

  console.error("Error: neither EXA_API_KEY nor EXA_API_KEY_FILE is set.");
  console.error(
    "Set EXA_API_KEY directly, or point EXA_API_KEY_FILE at a file containing the key.",
  );
  Deno.exit(1);
}

const API_KEY = getApiKey();
if (!API_KEY) {
  console.error("Error: API key is empty.");
  console.error(
    "Check the content of EXA_API_KEY_FILE or the value of EXA_API_KEY.",
  );
  Deno.exit(1);
}
const exa = new Exa(API_KEY);

// --- Argument parsing ---
const args = Deno.args;
const positional: string[] = [];
const flags: Record<string, unknown> = {};

for (let i = 0; i < args.length; i++) {
  const a = args[i];
  if (a.startsWith("--")) {
    const key = a.slice(2);
    if (key === "urls") {
      const urls: string[] = [];
      while (++i < args.length && !args[i].startsWith("--")) {
        urls.push(args[i]);
      }
      i--;
      flags.urls = urls;
    } else if (key === "schema") {
      const raw = args[++i];
      try {
        flags.schema = JSON.parse(raw);
      } catch {
        console.error("Error: --schema must be valid JSON.");
        Deno.exit(1);
      }
    } else if (key === "include-domains" || key === "exclude-domains") {
      const val = args[++i];
      flags[key] = val
        ? val.split(",").map((s) => s.trim()).filter(Boolean)
        : [];
    } else if (
      key === "start-published-date" || key === "end-published-date" ||
      key === "max-age-hours"
    ) {
      flags[key] = args[++i];
    } else if (key === "num-results") {
      flags.numResults = parseInt(args[++i], 10);
    } else if (key === "max-chars") {
      flags.maxChars = parseInt(args[++i], 10);
    } else if (key === "type") {
      flags.type = args[++i];
    } else if (key === "text" || key === "summary" || key === "highlights") {
      flags[key] = true;
    } else if (key === "no-highlights") {
      flags.highlights = false;
    } else if (key === "help") {
      showHelp();
      Deno.exit(0);
    } else {
      console.error(`Unknown flag: ${a}`);
      console.error("Run with --help to see available options.");
      Deno.exit(1);
    }
  } else {
    positional.push(a);
  }
}

function showHelp() {
  console.log(`
Usage:
  ./search.ts "query" [options]
  ./search.ts --urls <url>... [options]

Search options:
  --num-results <n>         Number of results (default: 10)
  --type <type>             Search type: auto, fast, instant, deep-lite, deep, deep-reasoning (default: auto)
  --highlights              Include query-relevant excerpts (default: on)
  --no-highlights           Disable highlights
  --text                    Include full page text
  --max-chars <n>           Max characters when --text is set (default: 2000)
  --summary                 Include per-result summaries
  --schema <json>           JSON Schema for structured output (outputSchema)

Filtering:
  --include-domains <list>  Comma-separated domains to include
  --exclude-domains <list>  Comma-separated domains to exclude
  --start-published-date <d> ISO date (e.g. 2024-01-01)
  --end-published-date <d>   ISO date
  --max-age-hours <n>       Max cache age in hours (0 = livecrawl, -1 = cache only)

Content extraction (from known URLs):
  --urls <url...>           Extract content from URLs (uses /contents endpoint)
`);
}

// --- Determine mode ---
const isContents = Array.isArray(flags.urls) &&
  (flags.urls as string[]).length > 0;
const query = positional.join(" ");

if (!isContents && !query) {
  console.error(
    "Error: Provide a search query or use --urls to extract content.",
  );
  console.error("Run with --help to see usage.");
  Deno.exit(1);
}

// --- Build search params ---
function buildSearchParams(): Record<string, unknown> {
  const params: Record<string, unknown> = {
    numResults: flags.numResults ?? 10,
    type: flags.type ?? "auto",
  };

  // contents block
  const contents: Record<string, unknown> = {};

  const wantHighlights = flags.highlights !== false;
  if (wantHighlights) contents.highlights = true;
  if (flags.text) {
    contents.text = {
      maxCharacters: flags.maxChars ?? 2000,
      includeHtmlTags: false,
    };
  }
  if (flags.summary) contents.summary = true;

  if (Object.keys(contents).length > 0) {
    params.contents = contents;
  }

  // outputSchema
  if (flags.schema) {
    params.outputSchema = flags.schema;
  }

  // filters
  if (flags["include-domains"]) {
    params.includeDomains = flags["include-domains"];
  }
  if (flags["exclude-domains"]) {
    params.excludeDomains = flags["exclude-domains"];
  }
  if (flags["start-published-date"]) {
    params.startPublishedDate = flags["start-published-date"];
  }
  if (flags["end-published-date"]) {
    params.endPublishedDate = flags["end-published-date"];
  }
  if (flags["max-age-hours"] !== undefined) {
    params.maxAgeHours = parseInt(flags["max-age-hours"] as string, 10);
  }

  return params;
}

// --- Execute ---
async function doSearch() {
  const params = buildSearchParams();
  const results = await exa.search(query, params);
  console.log(JSON.stringify(results, null, 2));
}

async function doContents() {
  const urls = flags.urls as string[];
  const options: Record<string, unknown> = {};

  if (flags.highlights !== false) options.highlights = true;
  if (flags.text) {
    options.text = {
      maxCharacters: flags.maxChars ?? 2000,
      includeHtmlTags: false,
    };
  }
  if (flags["max-age-hours"] !== undefined) {
    options.maxAgeHours = parseInt(flags["max-age-hours"] as string, 10);
  }

  const results = await exa.getContents(urls, options);
  console.log(JSON.stringify(results, null, 2));
}

try {
  if (isContents) {
    await doContents();
  } else {
    await doSearch();
  }
} catch (err) {
  console.error(
    "Exa API error:",
    err instanceof Error ? err.message : String(err),
  );
  Deno.exit(1);
}
