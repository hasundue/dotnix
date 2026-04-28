# General Rules and Guidelines

## Response Formatting

- Use fenced code blocks for all multi-line code/output (e.g. `...`).
- Always include a language tag when possible (e.g., `ts,`sh, `json,`diff).

## Repository Access and Code Inspection Workflow

When analyzing code from GitHub or similar sources, **do not use WebFetch for
individual files**.

1. **Clone the repository locally with `ghq`** (reuse the clone if it already
   exists).
2. **Use the Read tool** to inspect all files from the local clone.
3. Use WebFetch **only** for resources outside the repository.

Always operate on the local `ghq` clone for code analysis.

## Web Research Workflow

- For extensive web research (multiple pages, synthesis needed, uncertain
  scope), use the Task tool with the web-research subagent instead of WebFetch
  directly.
- For targeted lookups (specific fact, known concise page, user-provided URL),
  direct WebFetch is acceptable.

## GitHub Operations

- **Simple/one-shot operations** (checking issues, listing PRs, single `gh`
  commands) — use `gh` CLI directly in the main agent
- **Complex workflows** (PR reviews, multi-step issues with labels/assignees,
  searching across repos) — delegate to the `github` subagent via Task tool
