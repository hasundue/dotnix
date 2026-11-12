# Launcher mechanics

Read this only when an invocation fails or you need the run's provenance.

- `run.py` owns the run directory and session. Unknown flags (and `@file`
  words) are forwarded to `pi`; session, mode, trust, and resource-loading
  flags are reserved.
- Words after `--` are joined with spaces into the task; piped input follows
  it. The child receives exactly the prompt saved as `prompt.md` in the run
  dir.
- The child runs read-only (`read,grep,find,ls`) unless overridden.
- `--dry-run` prints the assembled command without launching. stdout is the
  child's answer alone; stderr stays empty unless the child exits non-zero.
- `--info` adds the run ID, run dir, session and prompt paths, agent dir, the
  manual resume command, and the child's stderr.
