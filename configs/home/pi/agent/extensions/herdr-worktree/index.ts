/**
 * Herdr worktree — Supplies the Herdr-only worktree workflow and completes the
 * handoff from the pane that created a worktree.
 *
 * The package is loaded in every session, but every path here returns unless
 * HERDR_ENV=1. AGENTS.md stays free of environment-specific worktree rules.
 */

import { readFileSync } from "node:fs";
import { resolve, sep } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const SOURCE = "herdr:pi-handoff";
const TOKEN = "old_pane_id";

/**
 * Static text: changing it must not depend on the old pane or the request,
 * so Pi can patch a single context-files section instead of the whole prompt.
 */
const WORKFLOW = readFileSync(new URL("./workflow.md", import.meta.url), "utf8");

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
