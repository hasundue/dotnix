---
name: agent-skills
description: >
  Agent Skills documentation and best practices. Use when the user asks to
  create, edit, review, or debug a "skill" — including the SKILL.md format,
  activation mechanism, description optimization, test cases, context
  efficiency, and bundling scripts. Also use when the user asks about the
  Agent Skills specification or skill creation workflow.
---

# Agent Skills

This skill documents the Agent Skills system — the standardized mechanism by
which coding agents load structured, domain-specific instructions. The spec
comes first, our own conventions last.

## Upstream documentation (authoritative)

The docs live in `agentskills/agentskills` (Apache-2.0) and are not vendored
here, so the skill cannot drift from the spec. Fetch them with `curl` — they are
already markdown, and running them through an HTML extractor escapes them:

```bash
curl -s https://agentskills.io/skill-creation/best-practices.md
curl -s https://raw.githubusercontent.com/agentskills/agentskills/main/docs/skill-creation/best-practices.mdx
```

Either source works; `gh repo clone agentskills/agentskills` gives a local copy
for offline use. Avoid GitHub `blob/` URLs, which return HTML.

- **General**: `docs/`
  - `home.mdx` — overview of Agent Skills
  - `specification.mdx` — complete SKILL.md format
- **Skill Creation**: `docs/skill-creation/`
  - `quickstart.mdx` — Create your first skill, overview of format and
    activation
  - `best-practices.mdx` — Scoping, context efficiency, prescriptiveness,
    gotchas
  - `evaluating-skills.mdx` — Eval-driven iteration with test cases and grading
  - `optimizing-descriptions.mdx` — Testing and improving description triggering
  - `using-scripts.mdx` — Running commands and bundling scripts in skills

Read the most relevant docs for your current task first, and refer to the others
as needed.

## Local conventions (ours)

Not part of the spec; preferences we can change freely.

### Maturity banner

Skills that can be silently wrong (parsers, extractors, tools with a moving API)
open with a `> **Status: work in progress.**` blockquote naming 2–3 concrete
failure modes and telling the agent to stop, report, and fix the skill before
resuming. Skip it for procedure skills. Keep line 1 verbatim so
`grep -rl 'Status: work in progress' skills/` finds unfinished ones, and swap
the banner for `## Known limits` once N clean tasks accumulate. Example:
`pdf-tools`.
