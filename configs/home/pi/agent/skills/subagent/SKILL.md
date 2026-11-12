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
trust, and resource-loading flags.

Match the prompt to its length. A one-line task goes in `--prompt`; anything
longer belongs in a file that you create with the `write` tool and pipe to
stdin, `run.py --prompt "<one-line task>" < /tmp/<task>.md`, so the command
stays readable, the transcript keeps one line, and the run dir records the
whole brief. Stdin is prepended to `--prompt` and is also how a diff or log
goes in.

The launcher defaults to read-only tools (`read,grep,find,ls`). `--dry-run`
prints the assembled command, agent-dir env, and system prompt without
launching the child. stdout is the child's answer alone, and stderr stays
empty unless the child exits non-zero. `--info` adds the run ID, run dir,
session and prompt paths, agent dir, the manual resume command, and the
child's stderr.

## Examples

Review a staged diff without giving the child bash:

```sh
git diff --cached | ~/.pi/agent/skills/subagent/scripts/run.py \
  --model glm-5.3-flash:max \
  --prompt "Review this staged diff. You may read src/** and tests/**."
```

The diff is piped on stdin and prepended to the prompt. Name the paths or glob
patterns the child may read; it reports anything it needed but was not given.

Use the model's default thinking level and mention the files to read:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model claude-haiku-5-5 \
  --prompt "Review the translation of @doc.ja.md into @doc.en.md per @rules.md."
```

Write a longer brief to a file first, then pipe it in:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model glm-5.3-flash \
  --prompt "Review the brief on stdin against @src/**." \
  < /tmp/review-brief.md
```

Use `--no-context-files` for a context-independent task:

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --model gemini-4-argon \
  --no-context-files \
  --prompt "Review the derivation of Eq.(1) in @paper.tex."
```

Follow-up, on the most recent run or on a named one:

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume \
  --prompt "Review @/path/to/new.patch too."
```

## Rules

- Keep the launcher's read-only default (`read,grep,find,ls`). Do not add
  `write`, `edit`, or `bash`; this skill is for read-only tasks. Use
  `--no-tools` when the child needs no files.
- The child does not see this session. Make the prompt self-contained, and
  name every path or glob it may read; a piped diff names its own files. The
  child does not go looking on its own and reports what the set is missing.
- The path list is prompt-only: the child's tools can still read anything the
  process can. Do not treat the child as a sandbox.
- A new run needs `--model` with the bare model ID. Use either `--thinking` or
  a `:thinking` suffix, not both. If the model is unclear, ask.
- The prompt, whatever is piped on stdin included, is saved in the run dir and
  sent to the model; do not include secrets.
- `--resume` reuses the run's saved pi flags, cwd, and system prompt; start a
  new run to change them.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review; the launcher has none. A timeout kills the process group, so the
  child dies with it and leaves its run dir behind.
- Report the child's result. The output is the answer alone, so reach for
  `--info` when you need the run ID or the resume command; a follow-up to the
  most recent run needs only `--resume`.
- Do not edit the caller's note, and leave no artifact of your own in the
  project; the run dir records provenance. On a non-zero exit, stop and
  report the exit code and stderr. Do not run two children in parallel.
