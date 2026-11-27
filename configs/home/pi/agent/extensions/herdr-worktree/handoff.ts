/**
 * Herdr worktree handoff — loaded only in the forked destination via `-e`.
 * It reads the old pane ID from the handoff flag and closes the source pane
 * and session after the forked agent has settled.
 */

import { unlink } from "node:fs/promises";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

import {
  HANDOFF_FLAG,
  HANDOFF_MESSAGE,
  HANDOFF_MESSAGE_TYPE,
  MOVE_TOOL,
  createHerdr,
  registerHerdrNotice,
  renderMoveResult,
  samePath,
  sleep,
} from "./common.ts";

export default function (pi: ExtensionAPI) {
  if (process.env.HERDR_ENV !== "1") return;

  registerHerdrNotice(pi);
  pi.registerFlag(HANDOFF_FLAG, {
    description: "Old Herdr pane ID for a worktree handoff",
    type: "string",
  });
  pi.registerToolRenderer((toolName, next) => {
    if (toolName !== MOVE_TOOL) return next();
    return next() ?? { renderResult: renderMoveResult };
  });
  const { herdr, herdrQuiet } = createHerdr(pi);

  let handoffStarted = false;

  pi.on("session_start", (_event, ctx) => {
    const handoffFrom = pi.getFlag(HANDOFF_FLAG);
    if (handoffStarted || typeof handoffFrom !== "string" || handoffFrom === "") return;
    handoffStarted = true;
    pi.sendMessage(
      {
        customType: HANDOFF_MESSAGE_TYPE,
        content: HANDOFF_MESSAGE,
        display: false,
        details: {},
      },
      { triggerTurn: true, deliverAs: "steer" },
    );
    void finishHandoff(handoffFrom, ctx);
  });

  async function finishHandoff(oldPane: string, ctx: ExtensionContext): Promise<void> {
    const report = (message: string) => ctx.ui.notify(message, "warning");
    let sourceSession: string | undefined;
    let oldWorkspaceId: string | undefined;
    let oldWorkspace: any;
    try {
      const old = await herdr(["pane", "get", oldPane], undefined, 10000);
      sourceSession = old?.result?.pane?.agent_session?.value;
      oldWorkspaceId = old?.result?.pane?.workspace_id;
      oldWorkspace = oldWorkspaceId
        ? await herdr(["workspace", "get", oldWorkspaceId], undefined, 10000)
        : null;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const workspaceId = oldPane.split(":")[0];
      const workspaces = await herdrQuiet(["workspace", "list"]);
      const stillOpen = (workspaces?.result?.workspaces ?? []).some(
        (workspace: any) => workspace.workspace_id === workspaceId,
      );
      if (stillOpen) report(`Handoff source pane ${oldPane} is unavailable: ${message}`);
      return;
    }

    const destinationPaneId = process.env.HERDR_PANE_ID;
    if (!destinationPaneId) {
      report("Handoff destination pane ID is missing; the source pane was left open.");
      return;
    }

    let destinationWorkspace: any;
    try {
      const destinationPane = await herdr(["pane", "get", destinationPaneId], undefined, 10000);
      const destinationWorkspaceId: string | undefined =
        destinationPane?.result?.pane?.workspace_id;
      if (!destinationWorkspaceId) throw new Error("Herdr response has no workspace ID");
      destinationWorkspace = await herdr(
        ["workspace", "get", destinationWorkspaceId],
        undefined,
        10000,
      );
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      report(`Handoff destination metadata is unavailable: ${message}`);
      return;
    }

    const oldWorktree = oldWorkspace?.result?.workspace?.worktree;
    const destinationWorktree = destinationWorkspace?.result?.workspace?.worktree;
    if (
      !oldWorktree ||
      !destinationWorktree ||
      typeof oldWorktree.repo_root !== "string" ||
      typeof destinationWorktree.checkout_path !== "string"
    ) {
      report("Handoff worktree metadata is incomplete; the source pane was left open.");
      return;
    }
    const isMainReturn =
      oldWorktree.is_linked_worktree === true &&
      destinationWorktree.is_linked_worktree === false &&
      samePath(oldWorktree.repo_root, destinationWorktree.checkout_path);

    const deadline = Date.now() + 60000;
    let sawWorking = false;
    let settled = false;
    let elapsed = 0;
    while (Date.now() < deadline) {
      const agent = await herdrQuiet(["agent", "get", oldPane], 10000);
      const state = agent?.result?.agent?.agent_status;
      if (state === "working" || state === "blocked") {
        sawWorking = true;
      } else if (
        (state === "idle" || state === "done" || state === "unknown") &&
        (sawWorking || elapsed >= 2000)
      ) {
        settled = true;
        break;
      }
      await sleep(500);
      elapsed += 500;
    }

    if (!settled) {
      report(
        `Handoff from ${oldPane} is unfinished: the old pane did not settle and was left open.`,
      );
      return;
    }

    const isMainCheckout = oldWorkspace?.result?.workspace?.worktree?.is_linked_worktree === false;
    const paneCount = oldWorkspace?.result?.workspace?.pane_count ?? 0;
    if (isMainCheckout && paneCount <= 1) {
      try {
        await herdr(
          [
            "tab",
            "create",
            "--workspace",
            oldWorkspaceId!,
            "--cwd",
            oldWorkspace.result.workspace.worktree.checkout_path,
            "--no-focus",
          ],
          undefined,
          10000,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not create a replacement tab in ${oldWorkspaceId}: ${message}`);
        return;
      }
    }

    try {
      await herdr(["pane", "close", oldPane], undefined, 10000);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      report(`Could not close old pane ${oldPane}: ${message}`);
      return;
    }

    if (typeof sourceSession === "string" && sourceSession !== "") {
      try {
        await unlink(sourceSession);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not remove source session ${sourceSession}: ${message}`);
      }
    }
    if (isMainReturn && oldWorkspaceId) {
      let workspaceStillOpen = false;
      try {
        const listed = await herdr(["workspace", "list"], undefined, 10000);
        workspaceStillOpen = (listed?.result?.workspaces ?? []).some(
          (workspace: any) => workspace.workspace_id === oldWorkspaceId,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not inspect old workspace ${oldWorkspaceId}: ${message}`);
        return;
      }

      if (workspaceStillOpen) {
        try {
          await herdr(["workspace", "close", oldWorkspaceId], undefined, 10000);
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          report(`Could not close old workspace ${oldWorkspaceId}: ${message}`);
        }
      }
    }
  }
}
