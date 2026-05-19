---
name: create-deno-skill
description: >-
  Scaffold a new pi skill backed by a Deno script for any web/API use case.
  Uses @std/cli for flag parsing and produces compact JSON output.
  Output goes to .agents/skills/<name>/ by default.
---

# Create a Deno skill for pi

Use this when asked to create, scaffold, or generate a pi skill that calls a web
API, fetches data from the internet, or needs a Deno helper script. This is the
general template behind specialised skills like `exa-search`.

## Process

1. Read `script.ts` and `SKILL_TEMPLATE.md` in this directory for the pattern
2. Gather from user:
   - Skill name (directory name under `.agents/skills/`)
   - API or service it talks to (if any)
   - SDK package + version (if using an npm SDK — use pinned versions)
   - Env var name for the API key (if needed)
3. Determine destination:
   - Default: `.agents/skills/<name>/`
   - If a custom destination is specified, use that instead
4. Create `<destination>/SKILL.md` and `<destination>/script.ts`

## Patterns

### script.ts

- Pin every dependency (std lib, SDK) to the version available at creation time
  using the `@` syntax, e.g. `@std/cli@1.0.17` or `npm:sdk@2.12.1`. Use the
  official client SDK from npm (never raw `fetch()` when an SDK exists).
- API key: check `$KEY_ENV` first, then `$KEY_ENV_FILE` (read as file)
- Output: compact by default (strip `requestId`, `resolvedSearchType`,
  `costDollars`, `searchTime`, empty arrays). Use `--verbose` to opt in.
- Always include `--help` with usage info
- Handle errors with try/catch, exit 1 on failure

### SKILL.md

- Frontmatter with `name` and `description`
- Setup: Deno prerequisite, API key via env var or file
- Usage examples
- Options table
- Reference links to API docs and dashboard

## Reference

- `script.ts` and `SKILL_TEMPLATE.md` in this directory — templates to follow
