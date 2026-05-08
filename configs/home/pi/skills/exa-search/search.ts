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
import { parseArgs } from "jsr:@std/cli@1.0.17/parse-args";

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

// --- Argument parsing using Deno std lib ---
const parsed = parseArgs(Deno.args, {
  boolean: ["verbose", "text", "summary", "highlights", "no-highlights"],
  string: [
    "type",
    "num-results",
    "max-chars",
    "max-age-hours",
    "start-published-date",
    "end-published-date",
    "include-domains",
    "exclude-domains",
  ],
});

// Extract positional args (query)
const query = parsed._.join(" ");

// Extract flags - handle highlights resolution manually
const flags: Record<string, unknown> = {
  verbose: parsed.verbose ?? false,
  text: parsed.text ?? false,
  summary: parsed.summary ?? false,
  type: parsed.type,
  numResults: parsed["num-results"]
    ? parseInt(parsed["num-results"] as string, 10)
    : undefined,
  maxChars: parsed["max-chars"]
    ? parseInt(parsed["max-chars"] as string, 10)
    : undefined,
  "max-age-hours": parsed["max-age-hours"],
  "start-published-date": parsed["start-published-date"],
  "end-published-date": parsed["end-published-date"],
  "include-domains": parsed["include-domains"]
    ? (parsed["include-domains"] as string).split(",").map((s: string) =>
      s.trim()
    ).filter(Boolean)
    : undefined,
  "exclude-domains": parsed["exclude-domains"]
    ? (parsed["exclude-domains"] as string).split(",").map((s: string) =>
      s.trim()
    ).filter(Boolean)
    : undefined,
};

// Resolve highlights: --no-highlights overrides --highlights
// parseArgs treats --highlights false as setting highlights to false
// but we also handle --no-highlights as explicit negation
flags.highlights = parsed["no-highlights"]
  ? false
  : (parsed.highlights ?? true);

// Handle --schema manually (needs JSON parse)
const schemaArg = Deno.args.find((a) => a.startsWith("--schema"));
if (schemaArg) {
  const schemaIdx = Deno.args.indexOf(schemaArg);
  if (schemaIdx >= 0 && Deno.args[schemaIdx + 1]) {
    try {
      flags.schema = JSON.parse(Deno.args[schemaIdx + 1]);
    } catch {
      console.error("Error: --schema must be valid JSON.");
      Deno.exit(1);
    }
  }
}

// Handle --urls manually (collect all args after --urls until next --)
const urlsIdx = Deno.args.indexOf("--urls");
if (urlsIdx >= 0) {
  const urls: string[] = [];
  for (let i = urlsIdx + 1; i < Deno.args.length; i++) {
    if (Deno.args[i].startsWith("--")) break;
    urls.push(Deno.args[i]);
  }
  if (urls.length > 0) flags.urls = urls;
}

// Handle --help
if (Deno.args.includes("--help") || Deno.args.includes("-h")) {
  console.log(`
Usage:
  ./search.ts "query" [options]
  ./search.ts --urls <url>... [options]

Search options:
  --num-results <n>         Number of results (default: 10)
  --type <type>             Search type: auto, fast, instant, deep-lite, deep, deep-reasoning (default: auto)
  --highlights [true|false] Include query-relevant excerpts (default: on)
  --no-highlights           Disable highlights
  --text                    Include full page text
  --max-chars <n>           Max characters when --text is set (default: 2000)
  --summary                 Include per-result summaries
  --verbose                 Include verbose fields (requestId, resolvedSearchType)
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
  Deno.exit(0);
}

// --- Determine mode ---
const isContents = Array.isArray(flags.urls) &&
  (flags.urls as string[]).length > 0;

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

  if (flags.highlights) contents.highlights = true;
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

function minifyResponse(data: unknown): unknown {
  if (Array.isArray(data)) {
    return data.map(minifyResponse);
  }
  if (data && typeof data === "object") {
    const obj = data as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(obj)) {
      if (k === "highlightScores" && Array.isArray(v) && v.length === 0) {
        continue;
      }
      if (!flags.verbose && (k === "requestId" || k === "resolvedSearchType")) {
        continue;
      }
      out[k] = minifyResponse(v);
    }
    return out;
  }
  return data;
}

// --- Execute ---
async function doSearch() {
  const params = buildSearchParams();
  const results = await exa.search(query, params);
  console.log(JSON.stringify(minifyResponse(results), null, 2));
}

async function doContents() {
  const urls = flags.urls as string[];
  const options: Record<string, unknown> = {};

  if (flags.highlights) options.highlights = true;
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
  console.log(JSON.stringify(minifyResponse(results), null, 2));
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
