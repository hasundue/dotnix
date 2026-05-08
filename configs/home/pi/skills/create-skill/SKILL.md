---
name: create-skill
description: >-
  Create a new pi skill for an external API following the standard pattern:
  Deno, @std/cli parseArgs, SDK client, compact output.
  Puts skills in .agents/skills/ by default.
---

# Create a pi skill for an external API

Use this when asked to create, scaffold, or generate a skill for any external
API. Output goes to `.agents/skills/<name>/` by default.

## Process

1. Read `script.ts` and `SKILL_TEMPLATE.md` in this directory for the pattern
2. Gather from user: API name, SDK package+version, env var name for the key
3. Determine destination:
   - Default: `.agents/skills/<name>/`
   - If a custom destination is specified, use that instead
4. Create `<destination>/SKILL.md` and `<destination>/script.ts`

## Patterns

### script.ts

- Pin every dependency (std lib, SDK) to the version available at creation time
  using the `@` syntax, e.g. `@std/cli@1.0.17` or `npm:sdk@2.12.1`. Use the
  official client SDK from npm (never raw fetch()).
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
