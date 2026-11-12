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
global `AGENTS.md` or `APPEND_SYSTEM.md`. Skills, MCP servers, extensions,
prompt templates, and `.pi` trust-gated resources stay off.

## When to use

- An independent review or second opinion, preferably by a different model,
  without carrying this session's context or tools.
- A task that needs a follow-up on the same session.

Do not use it for implementation work, parallel fan-out, or interactive
co-work. One child at a time.

## Run it

The launcher is `scripts/run.py` in this skill directory. Resolve it relative to
the skill path or use the stable path:

`~/.pi/agent/skills/subagent/scripts/run.py`

Run `~/.pi/agent/skills/subagent/scripts/run.py --help` for the launcher flags.

The launcher owns the run directory and session. It forwards the flags it does
not use to `pi`, so `--model`, `--thinking`, `--tools`, and
`--no-context-files` behave as they do for pi; it reserves session, mode,
trust, and resource-loading flags. Pass the prompt with `--prompt` or on
stdin; piped stdin is prepended, and `@file` references are expanded by pi.

The launcher defaults to read-only tools (`read,grep,find,ls`). `--dry-run`
prints the assembled command, agent-dir env, and system prompt without
launching the child. The launcher prints the run ID, run dir, session path,
prompt path, agent dir, and a manual resume command to stderr; stdout is only
the child's final text.

## Examples

Review a staged diff without giving the child bash:

```sh
git diff --cached | ~/.pi/agent/skills/subagent/scripts/run.py \
  --model glm-5.3-flash:max \
  --prompt "Review this staged diff against the repo."
```

The diff is piped on stdin and prepended to the prompt.

Use the model's default thinking level and mention the files to read:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model claude-haiku-5-5 \
  --prompt "Review the translation of @doc.ja.md into @doc.en.md per @rules.md."
```

Pass a pre-constructed task brief:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model glm-5.3-flash \
  --prompt @task.md
```

Use `--no-context-files` for a context-independent task:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model gemini-4-argon \
  --no-context-files \
  --prompt "Review the derivation of Eq.(1) in @paper.tex."
```

Follow-up:

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume <run-id> \
  --prompt "Review @/path/to/new.patch too."
```

## Rules

- Keep the launcher's read-only default (`read,grep,find,ls`). Do not add
  `write`, `edit`, or `bash`; this skill is for read-only tasks. Use
  `--no-tools` when the child needs no files.
- The child does not see this session. Make the prompt self-contained and
  name the files it may read.
- The path restriction is prompt-only: the child's tools can still read
  anything the process can. Do not treat the child as a sandbox.
- A new run needs `--model` with the bare model ID. Use either `--thinking` or
  a `:thinking` suffix, not both. If the model is unclear, ask.
- The prompt is saved in the run dir and sent to the model, so do not include
  secrets.
- `--resume` reuses the run's saved pi flags, cwd, and system prompt; start a
  new run to change them.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review; the launcher has none. A timeout kills the process group, so the
  child dies with it and leaves its run dir behind.
- Report the run ID from stderr and the child's result. Do not edit the caller's
  note or create an artifact of your own; the run dir records provenance. On a
  non-zero exit, stop and report the exit code and stderr. Do not run two
  children in parallel.
