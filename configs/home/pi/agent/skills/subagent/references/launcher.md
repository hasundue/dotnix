# Launcher mechanics

Read this only when an invocation fails or you need the run's provenance.

- `run.py` owns the run directory and session. Unknown flags are forwarded
  to `pi`; session, mode, trust, and resource-loading flags are reserved,
  except `--skill`, which loads one named skill and is recorded in the run's
  `pi_flags`. Bare words and `@file` words before `--` are rejected.
- Words after `--` are joined with spaces into the task; piped input follows
  it. The child receives exactly the prompt saved as `prompt.md` in the run
  dir (`followups/*.md` for a resumed run). Auth, models, and settings are
  re-read from the current global config on every run, including resumes.
  run.py reads piped input whenever it is not a TTY; if stdin might stay
  open with no writer, redirect from `/dev/null`.
- The child runs read-only (`read,grep,find,ls`) unless overridden.
- `--dry-run` prints the assembled command and a prompt preview without
  launching. stdout is the child's answer alone; stderr stays empty on
  success without `--info` (errors and `--info` also write there).
- `--info` adds the run ID, run dir, session and prompt paths, agent dir, the
  manual resume command, and the child's stderr.
