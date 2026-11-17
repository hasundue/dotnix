---
name: subagent
description: >
  Run an analysis task in a separate pi process, on material you supply.
  Use for an independent review or a second opinion, a translation check, and
  when the user wants to keep questioning or challenging an earlier child's
  answer on the same topic.
---

# Subagent

Launch a real `pi --print` child from this session. The child is a separate
process and does not see this session or its context.

The child has no tools. It cannot read files, run commands, or search, so you
select the material and attach it: the child analyzes what you gave it and
reports when that is not enough. It runs in the current directory with a
run-local agent dir, so project and global `AGENTS.md` and `APPEND_SYSTEM.md`
are not loaded, and skill discovery, MCP servers, extensions, prompt templates,
and `.pi` trust-gated resources stay off.

## When to use

- An independent review or second opinion, preferably by a different model,
  without carrying this session's context or reasoning.
- A translation check: someone who did not translate the pair decides whether
  it is a faithful translation.
- The user wants to continue an earlier child's discussion: more questions,
  or pushback on its answer. Resume that run (see Gotchas).

Do not use it when the child would have to explore to answer: finding files,
following references, running the code, or checking a live system. You do that
work and attach the result. One child at a time; no parallel fan-out, no
interactive co-work, no implementation.

## Task prompts

A run is described by a task system-prompt file, which you pass with
`--prompt FILE`. Two generic defaults are built in:

- `~/.pi/agent/skills/subagent/references/prompts/review.md` -- an
  independent review of attached material.
- `~/.pi/agent/skills/subagent/references/prompts/translation-check.md` --
  a check of a translated text against its original.

They are defaults, not the last word: a text with its own established workflow
keeps a prompt tuned to that workflow, and you pass that path the same way.

The launcher prepends `references/prompts/common.md` (evidence, no invention,
stop when material is missing) and passes the combined text as pi's
`--system-prompt`. Pi's coding-assistant prompt is not used.

For a task a default does not cover, write the task prompt for this run: a
markdown file that states the purpose, the criteria to decide by, and the
output you need. Keep it in a temp file, or in the vault when it outlives the
run, and pass its path. There is no task registry and no task name to resolve;
the path is the interface.

## Run it

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --prompt ~/.pi/agent/skills/subagent/references/prompts/review.md \
  --ref /tmp/review.diff -- "Review this diff against the note in the brief."
```

- `--ref FILE` attaches one file, in the order given, and repeats per file.
  Pi reads each file and puts its contents in the same user message as the
  brief, so name each file in the brief by path and role. A glob is not a file:
  select the files yourself.
- The brief is the words after `--`, piped input, or both, joined into one
  message. Use `--` when the brief contains words that look like flags.
- A new run uses the parent session's provider and model unless `--model` is
  given. Pass `--model` only when the user names another model. It takes the
  bare model ID, provider-qualified (`PROVIDER/MODEL_ID`) when the ID is
  ambiguous. Use either `--thinking` or a `:thinking` suffix, not both. If the
  user names a model you cannot resolve, ask.
- `--dry-run` prints the refs, the command, the brief, and the composed system
  prompt without launching. Use it when the prompt files are the thing you are
  checking, and when you are unsure what was attached.
- The stable launcher path is `~/.pi/agent/skills/subagent/scripts/run.py`. If
  an invocation fails or you need the run's provenance, read
  `references/launcher.md` (`--help` lists the flags).

After each run, check the result before you use it:

1. Non-zero exit code: stop and report the exit code and stderr.
2. Run ID: confirm the `run: ID` line appeared, and write the ID in your reply.

## Resume

```sh
~/.pi/agent/skills/subagent/scripts/run.py --resume --ref /tmp/new.patch -- \
  "Check whether the fix in the attached patch answers the finding."
```

- Every run prints `run: ID` to stderr. Without that ID a follow-up is
  impossible. Name the run with `--run-id` (for example
  `--run-id liquid-metal-impurity`) when you expect follow-ups, and write the
  ID in your reply.
- `--resume` without an ID resumes the latest run; with an ID it resumes that
  run. It keeps the run's combined system prompt, model, cwd, and `--no-tools`,
  and takes a new brief and `--ref` list as one new user message.
- Resume does not accept `--prompt` or pi flags: to change the task prompt or
  the model, start a new run. Chasing an answer across tasks in one session is
  what resume is for, not switching tasks.
- A new run does not see the earlier child's context. A follow-up sent as a new
  run repeats the work and loses the thread.
- A run in the legacy launcher format is refused. Start a new run.

## Rules

- Do not delegate exploration. The child has no tools and cannot be given any.
- Do not put secrets in the brief or a reference. Both are saved in the run dir
  and sent to the model.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review. The launcher has no timeout of its own, and a timeout kills the
  process group, so the child dies with it and leaves its run dir behind.
- Leave no artifact of your own in the project. The run dir records provenance.
