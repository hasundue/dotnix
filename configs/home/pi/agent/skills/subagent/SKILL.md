---
name: subagent
description: >
  Run a read-only task in a separate pi process with a model of your choice.
  Use for an independent review or a second opinion, a translation check, and
  when the user wants to keep questioning or challenging an earlier child's
  answer on the same topic.
---

# Subagent

Launch a real `pi --print` child from this session. The child is a separate
process and does not see this session. It runs in the current directory with a
run-local agent dir and without context files, so project and global
`AGENTS.md` and `APPEND_SYSTEM.md` are not loaded. Put any convention the child
needs in the prompt. Skill discovery, MCP servers, extensions, prompt templates,
and `.pi` trust-gated resources stay off.

## When to use

- An independent review or second opinion, preferably by a different model,
  without carrying this session's context or tools.
- The user wants to continue an earlier child's discussion: more questions,
  or pushback on its answer. Resume that run (see Gotchas).

Do not use it for implementation work, parallel fan-out, or interactive
co-work. One child at a time.

## Gotchas

- Every run prints `run: ID` to stderr. Without that ID a follow-up is
  impossible. Name the run with `--run-id` (for example
  `--run-id liquid-metal-impurity`) when you expect follow-ups, and write the
  ID in your reply.
- A new run does not see the earlier child's context. A follow-up sent as a
  new run repeats the work and loses the thread.
- `--resume` reuses the run's saved pi flags (model, tools, cwd, system prompt)
  and rejects new pi flags such as `--no-tools`. To change them, start a new run.
- The path list is prompt-only. The child's tools can still read anything the
  process can, so the child is not a sandbox.

## Choose new or resume

- A question or pushback on an earlier child's answer: resume it with an
  explicit ID (`--resume RUN_ID -- "..."`). Do not start a new run.
- A new run only for an independent opinion that should not see the earlier
  discussion.

## Run it

- Write the task as words after `--`, like `pi` itself. With `--prompt FILE`,
  those words become the template's arguments (`$@`, `$1`, ...) instead. Pipe a
  diff or log when the child needs to see it.
- Name every path or glob the child may read with `@`. A longer brief belongs in
  a vault note or a temp file, referenced the same way.
- The child is read-only by default (`read,grep,find,ls`). Use `--no-tools` when
  it needs no files.
- A new run uses the parent session's provider and model unless `--model` is
  given. Pass `--model` only when the user names another model. It takes the
  bare model ID, provider-qualified (`PROVIDER/MODEL_ID`) when the ID is
  ambiguous. Use either `--thinking` or a `:thinking` suffix, not both. If the
  user names a model you cannot resolve, ask.
- The launcher is `scripts/run.py` in this skill directory; the stable path is
  `~/.pi/agent/skills/subagent/scripts/run.py`. If an invocation fails or you
  need the run's provenance, read `references/launcher.md` (`--help` lists the
  flags).

After each run, check the result before you use it:

1. Non-zero exit code: stop and report the exit code and stderr.
2. Run ID: confirm the `run: ID` line appeared, and write the ID in your reply.

## Examples

```sh
git diff --cached | ~/.pi/agent/skills/subagent/scripts/run.py -- \
  "Review the following diff. You may read @src/** and @tests/**."
```

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --prompt ~/.pi/agent/skills/vault/prompts/review-translation.md -- @doc.ja.md @doc.en.md
```

A longer brief is referenced with `@`, or fed with `<`:

```sh
~/.pi/agent/skills/subagent/scripts/run.py < /tmp/review-brief.md
```

When the child needs both a diff and a longer brief, save the diff to a
temp file and name it from the brief with `@` (the child reads absolute
paths such as `/tmp` fine):

```sh
git diff --cached > /tmp/review.diff
```

(where `/tmp/review-brief.md` names `@/tmp/review.diff`):

```sh
~/.pi/agent/skills/subagent/scripts/run.py < /tmp/review-brief.md
```

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume -- \
  "Review @/path/to/new.patch too."
```

A named run needs its run ID (from the `run: ID` line on stderr):

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume RUN_ID -- \
  "Follow-up task."
```

To make specific skills available to the child, pass each `SKILL.md` with
`--skill`, repeated per skill. Skill discovery stays off, so only the named
skills are listed in the child's `<available_skills>`.

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --skill ~/.pi/agent/skills/SKILL_NAME/SKILL.md -- "TASK"
```

## Rules

- Keep the read-only default. This skill is for read-only tasks, so do not add
  `write`, `edit`, or `bash`.
- Do not put secrets in the prompt. The prompt, piped input included, is saved
  in the run dir and sent to the model.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review. The launcher has no timeout of its own, and a timeout kills the
  process group, so the child dies with it and leaves its run dir behind.
- Leave no artifact of your own in the project. The run dir records provenance.
