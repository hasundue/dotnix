---
status: agreed
session_lang: ja
---

# Make Herdr workspaces follow worktree moves

## Problem

When a Pi session inside Herdr creates or moves a worktree through pi-worktrunk, Herdr's workspaces and pane placement do not follow. Herdr cannot show which worktree the work is in, and features such as workspace status rollups, pane moves, and cleanup go unused.

## Design

- pi-worktrunk owns worktree creation and removal; Herdr only registers workspaces, moves panes, and closes workspaces -- keep ownership split.
- After pi-worktrunk creates a worktree, register its path with `herdr worktree open --path <path>`. In Herdr 0.9.5 a `workspace` carries `worktree.repo_key` and `is_linked_worktree`, which is what makes it appear nested under its repository in the sidebar. `herdr workspace create --cwd` does not guarantee this metadata, so do not use it.
- Move the current Pi pane into a tab of that workspace with `herdr pane move <pane_id> --tab <tab_id>`. Read the IDs from the JSON of `herdr worktree open` and `herdr tab list`. A pane move carries the agent name and session path with it.
- Do not restart with `pi --session-id`. pi-worktrunk's `ctx.switchSession()` moves the conversation to the linked session and continues the turn. `--session-id` opens the current directory's session or creates one, so it does not move history.
- Put the general rules in `configs/home/pi/agent/AGENTS.md` and add no steps to the keel or sail skills. AGENTS.md is read in every session; duplicating the same rule in two places lets it drift.
- Use Herdr CLI only when `HERDR_ENV=1`. Outside Herdr, skip those steps and fall back to plain terminal + tmux + pi-worktrunk.
- `configs/home/pi/agent/extensions/session-namer.ts` asks the model for two outputs from the first prompt. Keep the longer one as the descriptive session name as before and pass it to `pi.setSessionName()`; use the shorter one as the Herdr border label.
- Make the short label one English word by default; use two words only when it would collide with another window in the same Herdr session. Choose it by comparing labels and titles from `herdr pane list` at naming time. Do not use a label outside Herdr.
- Report the short label with `herdr pane report-metadata "$HERDR_PANE_ID" --source herdr:pi-short-title --agent pi --title <label>`. A metadata title takes display priority over a manual pane label and does not affect session identity, lifecycle state, waits, or notifications.
- Pass `pi --name <Role>` when starting a subagent. session-namer does not overwrite an existing name, so the role becomes the session name and appears in the terminal title too.
- Keep titles of windows created by a person derived from the running program. The rule of one Pi pane per window is an agent convention only and is not enforced.
- For cleanup, inspect `herdr pane list --workspace <id>`; if a window created by the user has a running program, ask before closing it. After Worktrunk removes the worktree, the agent closes the workspace with `herdr workspace close <id>`. Use `--force` only after the user agrees.
- Both files are store-backed links, so apply the edit with `home-switch`.

## Out of scope

- Adding or changing new Pi extensions, Herdr plugins, or worktree hooks
- Changes to the keel and sail skill documents
- Migrating to `pi-agent-teleport` or a restart route using `--session-id`
- Automatic enforcement of one Pi pane per window, and automatic generation of program-derived titles
- Automatic detection for cleanup or a dedicated confirmation UI
- Editing `~/vault/fragments/software/herdr-pi-workflow.md` or existing vault notes

## Acceptance criteria

- Entering implementation from a project workspace inside Herdr creates a linked worktree and leaves the Pi pane in a workspace nested under the repository
  - [ ] Manual: in Herdr, go from the gate into implementation and inspect `herdr workspace list` and `herdr pane list`. The worktree workspace has `worktree.repo_key` equal to the root's and `is_linked_worktree: true`; the Pi pane's `cwd` is that worktree path and `agent_session` points at the destination session. Ask the agent for the title discussed before the move and get the same answer.
- The procedure contains no restart that loses conversation history
  - [ ] `rg -n -- '--session-id' configs/home/pi/agent/AGENTS.md configs/home/pi/agent/extensions/session-namer.ts` prints nothing
- session-namer emits a long session name and a short label separately, and the short label appears on the Herdr border
  - [ ] Manual: start two Pi sessions with different topics in the same Herdr session; the terminal titles in `herdr pane list` keep the long session names and each pane border shows a one-word label. Start a third session with a topic whose natural one-word label matches an existing window; the border label has two words.
- No Herdr CLI is used outside Herdr
  - [ ] `rg -n 'HERDR_ENV' configs/home/pi/agent/AGENTS.md configs/home/pi/agent/extensions/session-namer.ts` contains the check. Manual: with `HERDR_ENV` unset in a plain terminal, have Pi create a worktree; no herdr command is issued and the existing flow continues.
- A subagent's session name is its role name
  - [ ] Manual: start one with `herdr agent start reviewer --kind pi --pane <pane_id> -- --name Review`; the terminal title in `herdr pane list` is `π - Review - <repo>`. session-namer does not overwrite it.
- Cleanup of a worktree with a user window asks for confirmation
  - [ ] Manual: create a user pane running `top` in the worktree workspace and ask for cleanup. A question appears before closing; declining leaves the workspace in place.
- The change passes formatting and checks
  - [ ] After `nix fmt`, `git diff --check` prints nothing

## Stop conditions

- `herdr worktree open --path` fails twice in a row, or the workspace gets no worktree metadata: stop with the reason written down; do not fall back to `herdr workspace create`
- If session-namer's model response lacks either the long name or the short label, return to the previous long-name-only behavior and retry at most once
- If the user does not answer the cleanup question, stop and leave the workspace in place
- If a needed change falls outside `configs/home/pi/agent/AGENTS.md` and `configs/home/pi/agent/extensions/session-namer.ts`, stop
