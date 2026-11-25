---
status: agreed
session_lang: ja
---

# Make Herdr workspaces follow worktree moves

## Problem

When a Pi session inside Herdr moves into a worktree, Herdr's workspaces and pane placement do not follow. Herdr cannot show which worktree the work is in, and features such as workspace status rollups, pane moves, and cleanup go unused.

## Design

- Herdr is the only supported worktree environment. Use `herdr worktree create` and `herdr worktree remove`; remove the pi-worktrunk package declaration from `configs/home/pi/default.nix` and its project-level enablement from `.pi/settings.json`. A Worktrunk directory directive would switch the session without changing its process cwd.
- Create the worktree with `herdr worktree create --cwd <root> --branch <branch> --base main --path <path> --no-focus`. The response carries the workspace, tab, and root pane IDs. The `local.worktree-hooks` plugin runs the shared post-start hooks on `worktree.created`.
- Do not move the existing Pi pane. Start Pi in the new root pane with `herdr agent start <name> --kind pi --pane <root_pane_id> -- --fork <current session file> "<initial prompt>"`. The fork keeps the conversation and starts with the destination cwd.
- Add `herdr-worktree.ts`, which does nothing unless `HERDR_ENV=1`. Inside Herdr it injects the worktree steps into the agent context and, on `session_start`, reads an `old_pane_id` token from its own pane, waits for that agent to settle, closes the old pane unless it is the last in its workspace or was created by the user, then clears the token. The old pane reports the token before the fork. `AGENTS.md` contains no worktree-tool instructions.
- session-namer asks for a long session name and a short border label. Keep the long name with `pi.setSessionName()` and report the label with `herdr pane report-metadata "$HERDR_PANE_ID" --source herdr:pi-short-title --agent pi --title <label>`.
- Make the label one English word by default; use two only when it would collide with another window, decided from `herdr pane list` at naming time. Do not label outside Herdr.
- Start subagents with `pi --name <Role>` after `--` in `herdr agent start`; session-namer does not overwrite an existing name.
- Keep titles of user-created windows derived from the running program. One Pi pane per window is an agent convention, not enforced.
- For cleanup, inspect `herdr pane list --workspace <id>`; ask before closing a user window with a running program. Use `herdr worktree remove --workspace <id>` and use `--force` only after the user agrees.
- These files are store-backed links, so apply the edits with `home-switch`; `.pi/settings.json` is a local mutable file.

## Out of scope

- Other Pi extensions, Herdr plugins, or worktree hooks beyond the changes listed in Design
- Changes to the keel and sail skill documents
- Migrating to `pi-agent-teleport`
- Automatic one-Pi-pane enforcement or program-derived titles
- Automatic cleanup detection or a confirmation UI
- Editing `~/vault/fragments/software/herdr-pi-workflow.md` or existing vault notes

## Acceptance criteria

- Herdr worktree creation, hooks, fork, and handoff work end to end
  - [ ] Manual: in Herdr, create the worktree through `herdr worktree create` and inspect `herdr workspace list` and `herdr pane list`. The worktree workspace has `worktree.repo_key` equal to the root's and `is_linked_worktree: true`; the Pi pane's `cwd` is that worktree path and `agent_session` points at the forked session. Ask the agent for a title discussed before the move and get the same answer.
  - [ ] Manual: after `herdr worktree create`, the `local.worktree-hooks` plugin has run the shared post-start hooks in the new checkout.
  - [ ] Manual: start Pi in the new root pane with `--fork <current session>` and the user's request as the initial prompt. The extension closes the old pane without a chat instruction.
  - unmet: this route has not been carried out yet.
- session-namer emits a long session name and a short label separately, and the short label appears on the Herdr border
  - [ ] Manual: start two Pi sessions with different topics in the same Herdr session; the terminal titles in `herdr pane list` keep the long session names and each pane border shows a one-word label. Start a third session with a topic whose natural one-word label matches an existing window; the border label has two words.
    - Observed long titles with separate one-word labels: `Create herdr-follow-test worktree`/`worktree`, `Fix CJK font weight regression`/`review`, and two `Compare terminal markdown viewers`/`compare`,`comparison`.
    - unmet: no two-word border label was observed; the collision fallback was implemented but not verified.
- pi-worktrunk is gone and the new extension is Herdr-only
  - [ ] `rg -n 'HERDR_ENV' configs/home/pi/agent/extensions/herdr-worktree.ts` contains the guard, `rg -n 'pi-worktrunk' configs/home/pi/default.nix .pi/settings.json` prints nothing, and `AGENTS.md` contains no worktree-tool instructions. unmet: the extension and removals do not exist yet.
- A subagent's session name is its role name
  - [ ] Manual: start one with `herdr agent start reviewer --kind pi --pane <pane_id> -- --name Review`; the terminal title in `herdr pane list` is `π - Review - <repo>`. session-namer does not overwrite it.
    - unmet: this case was not started.
- Cleanup of a worktree with a user window asks for confirmation
  - [ ] Manual: create a user pane running `top` in the worktree workspace and ask for cleanup. A question appears before closing; declining leaves the workspace in place.
    - unmet: this case was not started.
- The change passes formatting and checks
  - [x] After `nix fmt`, `git diff --check` prints nothing.
    - Both `nix fmt` runs reported 0 files changed; both `git diff --check` runs exited 0.

## Stop conditions

- If `herdr worktree create` fails twice, gives no worktree metadata, or the `worktree.created` plugin did not run the shared hooks, stop before starting Pi in the new worktree; do not fall back to `herdr workspace create`
- If session-namer's model response lacks either the long name or the short label, return to the previous long-name-only behavior and retry at most once
- If the user does not answer the cleanup question, stop and leave the workspace in place
- If the handoff token is missing when the new session starts, leave the old pane open and report it
- If a needed change falls outside `configs/home/pi/agent/AGENTS.md`, `configs/home/pi/agent/extensions/session-namer.ts`, `configs/home/pi/agent/extensions/herdr-worktree.ts`, `configs/home/pi/default.nix`, and `.pi/settings.json`, stop
