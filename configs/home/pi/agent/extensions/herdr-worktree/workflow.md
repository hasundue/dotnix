# Worktree workflow inside Herdr

Use this workflow when the user asks to work in a new worktree, start work
in a worktree, or move the current work into one. The request is satisfied
only when the work continues in a Herdr worktree workspace, not merely in
another directory of the current pane.

- Resolve the target worktree from the request first. Never create a
  duplicate.

  - Existing branch or path: open it with
    `herdr worktree open --cwd <repo-root> (--path <path> | --branch <branch>) --no-focus`.
  - New worktree: create it with
    `herdr worktree create --cwd <repo-root> --branch <branch> --base main --path <path> --no-focus`.

  Read the workspace, tab, and root pane IDs from the JSON. The
  `worktree.created` plugin runs the shared post-start hooks for a new
  checkout; an opened worktree keeps its existing bootstrap.
- Do not move the current Pi pane. Read the session file from
  `herdr pane get "$HERDR_PANE_ID"` (`agent_session.value`), then start the
  fork in the returned root pane with the user's request as the initial
  prompt:

  `herdr agent start <name> --kind pi --pane <root_pane_id> -- --fork <session_file> "<user request>"`

  The fork carries the conversation into a process whose cwd is the
  worktree.
- Report the old pane to the new one:

  `herdr pane report-metadata "$NEW_PANE_ID" --source herdr:pi-handoff --token old_pane_id="$HERDR_PANE_ID"`

  The new session retires the old pane on `session_start` without a chat
  instruction, then continues the requested work there.
- Start subagents with `pi --name <Role>` after `--` in `herdr agent start`,
  so the role becomes the session name and the terminal title shows it.
- For cleanup, inspect `herdr pane list --workspace <id>`; ask before closing
  a user window that has a running program. Use
  `herdr worktree remove --workspace <id>` and use `--force` only after the
  user agrees.
- Keep titles of user-created windows derived from the running program. One
  Pi pane per window is an agent convention, not an enforced rule.
- If creation, hooks, or the fork fails, stop and report instead of falling
  back to a plain directory change or `herdr workspace create`.

These commands cover the normal path. Use the Herdr skill or `herdr --help`
for edge cases.
