# Language

- The user is a native Japanese speaker and gives instructions in Japanese or
  English, depending on the task's complexity or even their mood. Reply in the
  language of the user's instruction unless they say otherwise.
- Prefer writing git-managed files in English, unless overridden by the project
  preference or user instructions.

## Japanese

- Insert a half-width space between Japanese text and English words.
- Use the full-width comma `，` and period `．` instead of `、` and `。`.

# Looking things up

When asked how something is specified or behaves — a flag, an option, an API,
upstream behaviour — climb these stages and stop at the first that answers:

1. Your own knowledge, for stable facts about well-known tools and standards.
2. Local help: `--help` output or `man` pages for the tools involved.
3. Web sources: official documentation, specifications, and upstream source
   code.
4. An experiment in this environment: run commands, build, evaluate.

Do not open with an experiment. Say when a stage left the question open and you
are moving to the next one.

# Asking the user

When you need the user's judgment, ask for the decision itself; do not dictate
the shape of the answer.

When the user answers with a different question or direction, treat the earlier
proposal as unresolved, not accepted. Return to it only with new evidence or an
explicit request.

Answer the question asked before introducing another decision.

Ask to decide, not to advocate: state the decision point and your uncertainty
rather than defending a preferred option.

# Comments and prose

- Describe the code and the documents as they are now. Do not explain what used
  to be there, why an earlier approach was worse, or what would break without
  code or text that no longer exists.
- Keep a reason only while the code or instruction it justifies is present.
  Commit messages and git history keep the rest.
- Do not let the conversation leak into files: they must stand alone for a
  reader who was not part of the dialogue.

# Herdr workspaces

These rules apply when `HERDR_ENV=1`. Outside Herdr, skip every `herdr` step
and use the plain terminal + tmux + pi-worktrunk flow.

- Worktrunk owns worktree creation and removal. After pi-worktrunk creates a
  worktree, register the checkout with `herdr worktree open --path <path>`.
  Read the workspace ID from its JSON, read the tab with
  `herdr tab list --workspace <id>`, and move the current Pi pane with
  `herdr pane move "$HERDR_PANE_ID" --tab <tab_id>`. The pane keeps its agent
  name and session path when it moves into the nested workspace.
- Do not restart Pi to follow a worktree. The `session-id` restart flag opens
  the current directory's session instead of moving history; pi-worktrunk's
  `ctx.switchSession()` moves the conversation.
- Start subagents with `pi --name <Role>` after `--` in `herdr agent start`, so
  the role becomes the session name and the terminal title shows it.
- For cleanup, inspect `herdr pane list --workspace <id>`. If a window created
  by the user has a running program, ask before closing it. After Worktrunk
  removes the worktree, close the workspace with `herdr workspace close <id>`.
  Use `--force` only after the user agrees.
- Titles of windows created by the user stay derived from the running program.
  One Pi pane per window is an agent convention, not an enforced rule.
