/**
 * Herdr worktree — Supplies the Herdr-only worktree workflow and completes the
 * handoff from the pane that created a worktree.
 *
 * The package is loaded in every session, but every path here returns unless
 * HERDR_ENV=1. AGENTS.md stays free of environment-specific worktree rules.
 */

import { resolve, sep } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SOURCE = "herdr:pi-handoff";
const TOKEN = "old_pane_id";

/**
 * Static text: changing it must not depend on the old pane or the request,
 * so Pi can patch a single context-files section instead of the whole prompt.
 */
const WORKFLOW = `Worktree workflow inside Herdr:

- Create the worktree with \`herdr worktree create --cwd <root> --branch <branch> --base main --path <path> --no-focus\`. Read the workspace, tab, and root pane IDs from the JSON. The worktree.created plugin runs the shared post-start hooks in the new checkout.
- Do not move the current Pi pane. Read the current session file from the \`agent_session.value\` field of \`herdr pane get "$HERDR_PANE_ID"\`.
- Start Pi in the returned root pane with \`herdr agent start <name> --kind pi --pane <root_pane_id> -- --fork <session_file> "<user request>"\`. Repeat the user's request as the initial prompt; the fork carries the conversation into a process whose cwd is the worktree.
- Report the old pane to the new one with \`herdr pane report-metadata "$NEW_PANE_ID" --source herdr:pi-handoff --token old_pane_id="$HERDR_PANE_ID"\`. The new session closes the old pane without a chat instruction.
- Start subagents with \`pi --name <Role>\` after \`--\` in \`herdr agent start\`, so the role becomes the session name and the terminal title shows it.
- For cleanup, inspect \`herdr pane list --workspace <id>\`; ask before closing a user window that has a running program. Use \`herdr worktree remove --workspace <id>\` and use \`--force\` only after the user agrees.
- Keep titles of user-created windows derived from the running program. One Pi pane per window is an agent convention, not an enforced rule.`;

const sleep = (ms: number) => new Promise<void>((done) => setTimeout(done, ms));

export default function (pi: ExtensionAPI) {
  const inHerdr = process.env.HERDR_ENV === "1";
  const paneId = process.env.HERDR_PANE_ID;

  if (!inHerdr) return;

  pi.on("before_agent_start", (event, ctx) => {
    const files = event.systemPromptOptions.contextFiles;
    if (files.some((file) => file.path === "herdr-worktree")) return;

    const cwd = resolve(ctx.cwd);
    const project = files.findIndex((file) => {
      const path = resolve(file.path);
      return path === cwd || path.startsWith(`${cwd}${sep}`);
    });
    files.splice(project === -1 ? files.length : project, 0, {
      path: "herdr-worktree",
      content: WORKFLOW,
    });
  });

  pi.on("session_start", () => {
    if (!paneId) return;
    void finishHandoff(paneId);
  });

  async function herdrJson(args: string[]): Promise<any | null> {
    try {
      const result = await pi.exec("herdr", args, { timeout: 5000 });
      if (result.code !== 0) return null;
      return JSON.parse(result.stdout);
    } catch {
      return null;
    }
  }

  async function finishHandoff(newPane: string): Promise<void> {
    const pane = await herdrJson(["pane", "get", newPane]);
    const oldPane = pane?.result?.pane?.tokens?.[TOKEN];
    if (typeof oldPane !== "string" || oldPane === "") return;

    for (let attempt = 0; attempt < 60; attempt += 1) {
      const agent = await herdrJson(["agent", "get", oldPane]);
      const state = agent?.result?.agent?.agent_status;
      if (state === undefined || state === "idle" || state === "done") break;
      await sleep(500);
    }

    const old = await herdrJson(["pane", "get", oldPane]);
    const workspaceId = old?.result?.pane?.workspace_id;
    const workspace = workspaceId ? await herdrJson(["workspace", "get", workspaceId]) : null;
    const paneCount = workspace?.result?.workspace?.pane_count ?? 0;
    if (paneCount > 1) {
      await pi.exec("herdr", ["pane", "close", oldPane], { timeout: 5000 }).catch(() => undefined);
    }

    await pi
      .exec(
        "herdr",
        ["pane", "report-metadata", newPane, "--source", SOURCE, "--clear-token", TOKEN],
        { timeout: 5000 },
      )
      .catch(() => undefined);
  }
}
