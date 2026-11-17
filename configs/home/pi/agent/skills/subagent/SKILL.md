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
session-local agent dir, so project and global `AGENTS.md` and
`APPEND_SYSTEM.md` are not loaded, and skill discovery, MCP servers, extensions,
prompt templates, and `.pi` trust-gated resources stay off.

## When to use

- An independent review or second opinion, preferably by a different model,
  without carrying this session's context or reasoning.
- A translation check: someone who did not translate the pair decides whether
  it is a faithful translation.
- The user wants to continue an earlier child's discussion: more questions,
  or pushback on its answer. Resume that session (see Resume).

Do not use it when the child would have to explore to answer: finding files,
following references, running the code, or checking a live system. You do that
work and attach the result. One child at a time; no parallel fan-out, no
interactive co-work, no implementation.

## Task prompts

A session is described by a task system-prompt file, which you pass with
`--system-prompt FILE`. Two generic defaults are built in:

- `~/.pi/agent/skills/subagent/references/prompts/review.md` -- an
  independent review of attached material.
- `~/.pi/agent/skills/subagent/references/prompts/translation-check.md` --
  a check of a translated text against its original.

They are defaults, not the last word: a text with its own established workflow
keeps a prompt tuned to that workflow, and you pass that path the same way.

The launcher prepends `references/prompts/common.md` (evidence, no invention,
stop when material is missing) and passes the combined text as pi's
`--system-prompt`. Pi's coding-assistant prompt is not used.

For a task a default does not cover, write the task prompt for this session: a
markdown file that states the purpose, the criteria to decide by, and the
output you need. Keep it in a temp file, or in the vault when it outlives the
session, and pass its path. There is no task registry and no task name to
resolve; the path is the interface.

## Run it

```sh
~/.pi/agent/skills/subagent/scripts/run.py \
  --system-prompt ~/.pi/agent/skills/subagent/references/prompts/review.md \
  @/tmp/review.diff @/tmp/note.md "Review this diff against the note."
```

The launcher takes pi's shape: options, then `--` when you need it, then
`@FILE` attachments and message words.

- `@FILE` attaches one file, in the order given, and repeats per file. Pi
  reads each file and puts its contents in the same user message as the words,
  so name each file in the message by path and role. A glob is not a file:
  select the files yourself. Front or back, the attachments are the same.
- Bare words are the message. Piped input follows it in the same user message.
  `--` ends option parsing as in pi, so a message that starts with a dash goes
  after it: `... -- "--flag-like words"`.
- A new session uses the parent session's provider and model unless `--model`
  is given. Pass `--model` only when the user names another model. It takes the
  bare model ID, provider-qualified (`PROVIDER/MODEL_ID`) when the ID is
  ambiguous. `--thinking` sets the level, and pi also accepts a `:thinking`
  suffix on `--model`; when both are given, pi decides.
- Nothing is forwarded to pi. A flag the launcher does not know is an error,
  because the child's tool policy is fixed at `--no-tools` and its resource
  loading is off, so no pi flag is left that a caller needs.
- `--dry-run` prints the refs, the agent dir, the command, the message, and the
  composed system prompt without launching. Use it when the prompt files are
  the thing you are checking, and when you are unsure what was attached.
- stdout is the child's answer alone. stderr carries the `session:` line, a
  blank line before the answer when there is one, any error, and `--info`'s
  provenance; nothing else on success.
- The stable launcher path is `~/.pi/agent/skills/subagent/scripts/run.py`. Its
  `--help` lists the flags and the stream contract, and its docstring records
  what a session dir holds.

After each run, check the result before you use it:

1. Non-zero exit code: stop and report the exit code and stderr.
2. Session ID: confirm the `session: ID (new)` or `session: ID (resumed)` line
   appeared, and write the ID in your reply.

## Resume

```sh
~/.pi/agent/skills/subagent/scripts/run.py --session-id liquid-metal-impurity \
  @/tmp/new.patch "Check whether the fix in the attached patch answers the finding."
```

- Every run prints `session: ID (new)` or `session: ID (resumed)` to stderr.
  That ID is the only way back: there is no "most recent" shortcut, so write it
  in your reply, and name the session with `--session-id` (for example
  `--session-id liquid-metal-impurity`) when you expect follow-ups.
- `--session-id ID` resumes that session, and creates it with that ID when it
  does not exist yet; creating one still needs `--system-prompt`, like any new
  session. It takes a new message and `@FILE` list as one new user message.
- Resuming keeps the session's composed system prompt and its model. `--model`
  and `--thinking` change the model for this turn and for every later turn;
  `--system-prompt` is refused, because a new task definition means a new
  session.
- A new session does not see the earlier child's context. A follow-up sent as a
  new session repeats the work and loses the thread.
- A session in the legacy launcher format is refused. Start a new session.

## Rules

- Do not delegate exploration. The child has no tools and cannot be given any.
- Do not put secrets in the message or an attachment. Both are saved in the
  session dir and sent to the model.
- Set the caller's bash tool timeout to at least 300 seconds, longer for a
  review.
- Redirect stdin from `/dev/null` when it might stay open with no writer.
- Leave no artifact of your own in the project. The session dir records
  provenance.

## Gotchas

- An argument that begins with `@` is an attachment, wherever it sits among the
  message words. Only the argument's first character counts, so
  `user@example.com` is text while `please check @bob` fails: quote the whole
  message (`"please check @bob"`) to keep the `@` inside one argument. A
  message cannot begin with an `@` word.
- The launcher reads piped input whenever stdin is not a TTY, so an open pipe
  with no writer waits instead of proceeding.
- The launcher has no timeout of its own. A caller's timeout kills the process
  group, so the child dies with it and leaves its session dir behind.
- A diff is not the files. `git diff` gives the hunks and three lines around
  them, so an unused helper, an import nothing needs any more, a paragraph a
  deletion left behind, or a file the diff does not touch cannot be judged.
  Attach the whole file when the review depends on it, or say in the message
  that the diff is all there is.
- A misspelled `--session-id` is not an error: it creates a new session. Only
  the `(new)` / `(resumed)` tag on the session line says which happened.
