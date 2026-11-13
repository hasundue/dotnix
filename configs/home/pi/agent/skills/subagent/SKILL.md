---
name: subagent
description: >
  Run a read-only task in a separate pi process with a model of your choice.
  Use for an independent review, a second opinion, or a translation check.
  Returns the child's final text; follow-ups reuse the same session by run ID.
---

# Subagent

Launch a real `pi --print` child from this session. The child is a separate
process and does not see this session. It runs in the current directory with a
run-local agent dir, so it inherits the project's context files but not your
global `AGENTS.md` or `APPEND_SYSTEM.md`. Skill discovery, MCP servers,
extensions, prompt templates, and `.pi` trust-gated resources stay off. One
skill can be loaded explicitly with `--skill <path>`; the run records the path
in `meta.json`, and the child still reads `SKILL.md` itself.

## When to use

- An independent review or second opinion, preferably by a different model,
  without carrying this session's context or tools.
- A task that needs a follow-up on the same session.

Do not use it for implementation work, parallel fan-out, or interactive
co-work. One child at a time.

## Run it

The launcher is `scripts/run.py` in this skill directory; the stable path is
`~/.pi/agent/skills/subagent/scripts/run.py`. Write the task as words after
`--`, like `pi` itself; with `--prompt FILE` those words become the template's
arguments (`$@`, `$1`, ...) instead. Pipe a diff or log when the child needs
to see it.
Name every path or glob the child may read with `@`; a longer brief belongs
in a vault note (or a temp file) and is referenced the same way.

If an invocation fails or you need the run's provenance, read
`references/launcher.md` (`--help` lists the flags).

The model, and optionally the thinking level, should be specified by user instructions
or project conventions. Ask if unsure.

## Examples

```sh
git diff --cached | ~/.pi/agent/skills/subagent/scripts/run.py \
  --model MODEL -- \
  "Review the following diff. You may read @src/** and @tests/**."
```

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model MODEL \
  --prompt ~/.pi/agent/skills/vault/prompts/review-translation.md -- @doc.ja.md @doc.en.md
```

A longer brief is referenced with `@`, or fed with `<`:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model MODEL < /tmp/review-brief.md
```

When the child needs both a diff and a longer brief, save the diff to a
temp file and name it from the brief with `@` (the child reads absolute
paths such as `/tmp` fine):

```sh
git diff --cached > /tmp/review.diff
```

(where `/tmp/review-brief.md` names `@/tmp/review.diff`):

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model MODEL < /tmp/review-brief.md
```

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model MODEL \
  --no-context-files -- "Review the derivation of Eq.(1) in @paper.tex."
```

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume -- \
  "Review @/path/to/new.patch too."
```

A named run needs its run ID (from `--info` output):

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume RUN_ID -- \
  "Follow-up task."
```

## Rules

- Put the task after `--`. Bare words before it never become the task; the
  launcher rejects them. With `--prompt FILE` the words after `--` are the
  template's arguments instead.
- Keep the launcher's read-only default (`read,grep,find,ls`). Do not add
  `write`, `edit`, or `bash`; this skill is for read-only tasks. Use
  `--no-tools` when the child needs no files.
- The child does not see this session. Make the prompt self-contained, and
  name every path or glob it may read; a piped diff names its own files. The
  child does not go looking on its own and reports what the set is missing.
- The path list is prompt-only: the child's tools can still read anything the
  process can. Do not treat the child as a sandbox.
- A new run needs `--model` with the bare model ID, provider-qualified
  (e.g. `opencode-go/claude-haiku-5-5`) when the ID is ambiguous across
  providers. Use either `--thinking` or a `:thinking` suffix, not both. If
  the model is unclear, ask.
- The prompt, piped input included, is saved in the run dir and
  sent to the model; do not include secrets.
- `--resume` reuses the run's saved pi flags, cwd, and system prompt; start a
  new run to change them.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review; the launcher has none. A timeout kills the process group, so the
  child dies with it and leaves its run dir behind.
- Report the child's result. A follow-up to the most recent run needs only
  `--resume`.
- Do not edit the caller's note, and leave no artifact of your own in the
  project; the run dir records provenance. On a non-zero exit, stop and
  report the exit code and stderr. Do not run two children in parallel.
