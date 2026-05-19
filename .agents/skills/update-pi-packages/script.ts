#!/usr/bin/env -S deno run --allow-net --allow-read

/**
 * update-pi-packages: changelog fetcher
 *
 * Reads version-change data from stdin or a file and fetches the relevant
 * CHANGELOG.md sections from GitHub, outputting a compact markdown report.
 *
 * Usage:
 *   ./script.ts                         # read TSV from stdin
 *   ./script.ts -i diff.tsv              # read from file
 *   ./script.ts --help                  # show help
 *
 * Input format (TSV):
 *   name<tab>old_version<tab>new_version
 *
 * Output: markdown report to stdout, errors to stderr.
 */

import { parseArgs } from "jsr:@std/cli@1.0.17/parse-args";

// ── Package → changelog source mapping ─────────────────────────────────────
interface Source {
  url: string;
  type?: "keep-a-changelog" | "github-releases";
}

function sourceFor(pkg: string): Source | null {
  // @juicesharp/rpiv-* — monorepo, one CHANGELOG.md per package
  const rpivMatch = pkg.match(/^@juicesharp\/(rpiv-.+)$/);
  if (rpivMatch) {
    const name = rpivMatch[1];
    return {
      url:
        `https://raw.githubusercontent.com/juicesharp/rpiv-mono/main/packages/${name}/CHANGELOG.md`,
    };
  }

  // @tintinweb/pi-subagents — standalone repo (master branch)
  if (pkg === "@tintinweb/pi-subagents") {
    return {
      url:
        "https://raw.githubusercontent.com/tintinweb/pi-subagents/master/CHANGELOG.md",
    };
  }

  // pi-mcporter — standalone repo, uses GitHub Releases, no CHANGELOG.md
  if (pkg === "pi-mcporter") {
    return {
      url: "https://api.github.com/repos/mavam/pi-mcporter/releases",
      type: "github-releases",
    };
  }

  return null;
}

// ── CHANGELOG.md parsing ───────────────────────────────────────────────────
interface ChangeEntry {
  version: string;
  date: string;
  body: string;
}

function parseChangelog(markdown: string): ChangeEntry[] {
  const entries: ChangeEntry[] = [];

  const sections = markdown.split(/(?=^##\s+\[)/m);
  for (const section of sections) {
    const headerMatch = section.match(
      /^##\s+\[([^\]]+)\]\s*-\s*(\d{4}-\d{2}-\d{2})/m,
    );
    if (!headerMatch) continue;

    const version = headerMatch[1];
    const date = headerMatch[2];

    const bodyLines: string[] = [];
    const lines = section.split("\n");
    let inBody = false;
    for (const line of lines) {
      if (line.startsWith("## ")) {
        if (inBody) continue;
        inBody = true;
        continue;
      }
      if (inBody) bodyLines.push(line);
    }

    const body = bodyLines.join("\n").trim();
    if (body) entries.push({ version, date, body });
  }

  return entries;
}

function extractSections(
  entries: ChangeEntry[],
  oldVersion: string,
  newVersion: string,
): ChangeEntry[] {
  const normalize = (v: string) => v.replace(/^v/, "");

  const nOld = normalize(oldVersion);
  const nNew = normalize(newVersion);

  function cmp(a: string, b: string): -1 | 0 | 1 {
    const pa = a.split(".").map(Number);
    const pb = b.split(".").map(Number);
    for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
      const na = pa[i] ?? 0;
      const nb = pb[i] ?? 0;
      if (na < nb) return -1;
      if (na > nb) return 1;
    }
    return 0;
  }

  const result: ChangeEntry[] = [];
  for (const entry of entries) {
    const v = normalize(entry.version);
    if (v === "Unreleased" || !/^\d/.test(v[0])) continue;
    const cOld = cmp(v, nOld);
    const cNew = cmp(v, nNew);
    if (cOld > 0 && cNew <= 0) result.push(entry);
  }

  return result;
}

// ── Report generation ──────────────────────────────────────────────────────

function generateReport(
  changed: Array<{ name: string; old: string; new: string; log: string }>,
): string {
  const lines: string[] = [];

  lines.push("# Pi Package Update Report");
  lines.push("");
  lines.push("| Package | Old | New |");
  lines.push("|---------|-----|-----|");
  for (const { name, old, new: n } of changed) {
    lines.push(`| \`${name}\` | \`${old}\` | \`${n}\` |`);
  }
  lines.push("");

  for (const pkg of changed) {
    lines.push(`---`);
    lines.push(`## ${pkg.name}`);
    lines.push(`\`${pkg.old}\` → \`${pkg.new}\``);
    lines.push("");
    if (pkg.log) {
      lines.push(pkg.log.trim());
      lines.push("");
    } else {
      lines.push("_No changelog entries found in range._");
      lines.push("");
    }
  }

  return lines.join("\n");
}

// ── Fetch helpers ──────────────────────────────────────────────────────────

async function fetchChangelogKeepAChangelog(
  url: string,
  oldVer: string,
  newVer: string,
): Promise<string> {
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  const md = await resp.text();
  const entries = parseChangelog(md);
  const relevant = extractSections(entries, oldVer, newVer);
  if (relevant.length === 0) return "";

  const blocks: string[] = [];
  for (const entry of relevant) {
    blocks.push(`### ${entry.version} (${entry.date})`, "", entry.body, "");
  }
  return blocks.join("\n");
}

async function fetchGitHubReleases(
  url: string,
  newVer: string,
): Promise<string> {
  const resp = await fetch(url);
  if (!resp.ok) throw new Error(`HTTP ${resp.status}`);
  const releases = await resp.json() as Array<{
    tag_name: string;
    published_at: string;
    body: string;
  }>;

  const blocks: string[] = [];
  for (const rel of releases) {
    const tag = rel.tag_name.replace(/^v/, "");
    if (tag !== newVer) continue;
    const date = rel.published_at.slice(0, 10);
    blocks.push(`### ${tag} (${date})`, "", rel.body.trim(), "");
  }
  return blocks.join("\n");
}

// ── Main ───────────────────────────────────────────────────────────────────

async function main() {
  const parsed = parseArgs(Deno.args, {
    boolean: ["help"],
    string: ["input"],
    alias: { h: "help", i: "input" },
  });

  if (parsed.help) {
    console.log(`Usage: ./script.ts [options]

Read version-change data from stdin (TSV: name<tab>old<tab>new) and output
a markdown changelog report.

Options:
  -i, --input <file>  Read TSV from a file instead of stdin
  -h, --help          Show this help`);
    Deno.exit(0);
  }

  // Read input
  let text: string;
  if (parsed.input) {
    text = await Deno.readTextFile(parsed.input);
  } else {
    const decoder = new TextDecoder();
    let buf = "";
    for await (const chunk of Deno.stdin.readable) {
      buf += decoder.decode(chunk, { stream: true });
    }
    text = buf;
  }

  text = text.trim();
  if (!text) {
    console.error(
      "Error: no input provided. Pipe from `nix run .#update-pi-packages` or pass -i <file>",
    );
    Deno.exit(1);
  }

  // Parse TSV lines
  const changed: Array<{ name: string; old: string; new: string }> = [];
  for (const line of text.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith("=== ")) continue;
    const parts = trimmed.split("\t");
    if (parts.length >= 3) {
      changed.push({ name: parts[0], old: parts[1], new: parts[2] });
    }
  }

  if (changed.length === 0) {
    console.log("No packages changed.");
    Deno.exit(0);
  }

  // Fetch and parse changelogs
  const results: Array<{
    name: string;
    old: string;
    new: string;
    log: string;
  }> = [];

  for (const pkg of changed) {
    const src = sourceFor(pkg.name);
    if (!src) {
      console.warn(`[warn] No changelog source configured for ${pkg.name}`);
      results.push({ ...pkg, log: "" });
      continue;
    }

    try {
      let log: string;
      if (src.type === "github-releases") {
        log = await fetchGitHubReleases(src.url, pkg.new);
      } else {
        log = await fetchChangelogKeepAChangelog(src.url, pkg.old, pkg.new);
      }
      results.push({ ...pkg, log });
    } catch (err) {
      console.warn(
        `[warn] Error fetching changelog for ${pkg.name}: ${
          err instanceof Error ? err.message : String(err)
        }`,
      );
      results.push({ ...pkg, log: "" });
    }
  }

  // Output report
  console.log(generateReport(results));
}

main();
