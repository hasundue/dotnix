#!/usr/bin/env -S deno run --allow-net --allow-env=API_KEY,API_KEY_FILE --allow-read

/**
 * Skill script template for external API skills.
 * Customize: import, API key name, parseArgs options, SDK call.
 * Reference: exa-search skill at skills/exa-search/
 */

import { parseArgs } from "jsr:@std/cli/parse-args";
// CUSTOMIZE: pin the latest version with @version, e.g. "jsr:@std/cli@1.0.17/parse-args"
// CUSTOMIZE: import SDK client, e.g.:
// import { Client } from "npm:package-name@1.0.0";

// --- API key (env var or file) ---
function getApiKey(): string {
  // CUSTOMIZE: replace env var names with actual ones
  const direct = Deno.env.get("API_KEY");
  if (direct) return direct;
  const f = Deno.env.get("API_KEY_FILE");
  if (f) {
    try {
      return Deno.readTextFileSync(f).trim();
    } catch {
      console.error(`Error reading ${f}`);
      Deno.exit(1);
    }
  }
  console.error("Error: set $API_KEY or $API_KEY_FILE");
  Deno.exit(1);
}
const KEY = getApiKey();
if (!KEY) {
  console.error("Error: empty key");
  Deno.exit(1);
}
// CUSTOMIZE: init client, e.g.:
// const client = new Client({ apiKey: KEY });

// --- Flags (use @std/cli, prefer over manual parsing) ---
const parsed = parseArgs(Deno.args, {
  boolean: ["verbose", "help"],
  // CUSTOMIZE: add your flag definitions here
  string: ["num-results", "type"],
  alias: { h: "help" },
});

if (parsed.help) {
  console.log(`Usage: ./script.ts "query" [options]
Options:
  --num-results <n>  Number of results (default: 10)
  --verbose          Include metadata in output
  -h, --help         Show help`);
  Deno.exit(0);
}

const query = parsed._.join(" ");
if (!query) {
  console.error("Error: provide a query or use a flag");
  Deno.exit(1);
}

// --- Compact output by default (strip noisy fields) ---
function minify(data: unknown): unknown {
  if (Array.isArray(data)) return data.map(minify);
  if (data && typeof data === "object") {
    const o = data as Record<string, unknown>;
    const out: Record<string, unknown> = {};
    for (const [k, v] of Object.entries(o)) {
      if (Array.isArray(v) && v.length === 0) continue;
      if (
        !parsed.verbose && (
          k === "requestId" || k === "resolvedSearchType" ||
          k === "costDollars" || k === "searchTime"
        )
      ) continue;
      out[k] = minify(v);
    }
    return out;
  }
  return data;
}

// --- Execute ---
try {
  // CUSTOMIZE: replace with actual SDK call
  const response = {
    results: [{ id: "1", title: "Example", url: "https://example.com" }],
  };
  // const response = await client.search(query, { ... });
  console.log(JSON.stringify(minify(response), null, 2));
} catch (err) {
  console.error("API error:", err instanceof Error ? err.message : String(err));
  Deno.exit(1);
}
