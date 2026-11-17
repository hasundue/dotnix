# Launcher mechanics

Read this only when an invocation fails or you need the run's provenance.

- `run.py` owns the run directory and session. Unknown flags are forwarded
  to `pi`, except session, mode, trust, prompt, tool, and resource-loading
  flags, which run.py manages and rejects. Bare words and `@file` words before
  `--` are rejected; use `--ref FILE` for a file.
- A new run needs `--prompt FILE`, the task system prompt. The launcher
  prepends `references/prompts/common.md`, saves the combined text as
  `system-prompt.md` in the run dir, and passes that text as pi's
  `--system-prompt`. Pi's standard prompt is not used.
- `--ref FILE` is repeatable and ordered. Each becomes a pi `@FILE` positional
  argument, so pi reads the file and puts its contents in the same user message
  as the brief. It must exist when the launcher runs; a glob is not a file.
- The brief is the words after `--` and piped input, in that order, as one
  user message. run.py reads piped input whenever it is not a TTY; if stdin
  might stay open with no writer, redirect from `/dev/null`. The brief is saved
  as `prompt.md` (`followups/*.md` for a resumed run).
- The child always runs with `--no-tools`, on a new run and on resume. It also
  runs without context files, skills, extensions, MCP, and prompt templates.
- `meta.json` records the run format, the task prompt's path, the pi flags, and
  one entry per turn with its brief file and ordered refs. Resume rejects a run
  without the current format: start a new run instead.
- `--resume` reuses the saved system prompt and pi flags. It takes a new brief
  and `--ref` list and rejects `--prompt`, `--run-id`, and pi flags.
- `--dry-run` prints the refs, the assembled command, a brief preview, and the
  composed system prompt without launching. The command shows
  `<composed-system-prompt>` where the prompt text goes. stdout is the child's
  answer alone; stderr stays empty on success without `--info` (errors and
  `--info` also write there).
- `--info` adds the run ID, run dir, session and prompt paths, agent dir, the
  manual resume command, and the child's stderr.
