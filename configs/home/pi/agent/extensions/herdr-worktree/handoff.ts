/**
 * Herdr worktree handoff — loaded only in the forked destination via `-e`.
 * It reads handoff metadata from the forked session, focuses this pane at
 * session start when that pane still has focus, and closes the source pane
 * and session after the forked agent has settled.
 */

import { unlink } from "node:fs/promises";

import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

import {
  HANDOFF_DONE_TYPE,
  HANDOFF_MESSAGE,
  HANDOFF_MESSAGE_TYPE,
  HANDOFF_METADATA_TYPE,
  MOVE_TOOL,
  createHerdr,
  customEntryData,
  isHandoffDone,
  isHandoffMetadata,
  registerHerdrNotice,
  renderMoveResult,
  samePath,
  sleep,
} from "./common.ts";

export default function (pi: ExtensionAPI) {
  if (process.env.HERDR_ENV !== "1") return;

  registerHerdrNotice(pi);
  pi.registerToolRenderer((toolName, next) => {
    if (toolName !== MOVE_TOOL) return next();
    return next() ?? { renderResult: renderMoveResult };
  });
  const { herdr, herdrQuiet } = createHerdr(pi);

  let handoffStarted = false;

  pi.on("session_start", async (event, ctx) => {
    if (event.reason !== "startup" || handoffStarted) return;
    const destinationPaneId = process.env.HERDR_PANE_ID;
    if (!destinationPaneId) return;

    const entries = ctx.sessionManager.getBranch();
    const done = new Set(
      customEntryData(entries, HANDOFF_DONE_TYPE, isHandoffDone).map((entry) => entry.handoffId),
    );
    const pending = customEntryData(entries, HANDOFF_METADATA_TYPE, isHandoffMetadata).filter(
      (entry) => entry.destinationPaneId === destinationPaneId && !done.has(entry.handoffId),
    );
    if (pending.length === 0) return;
    if (pending.length > 1) {
      ctx.ui.notify(
        `Multiple handoffs target pane ${destinationPaneId}; none was processed.`,
        "warning",
      );
      return;
    }

    handoffStarted = true;
    const { handoffId, sourcePaneId } = pending[0];
    pi.appendEntry(HANDOFF_DONE_TYPE, { handoffId });
    // Keep this non-blocking so Herdr's own session_start handlers can register the pane.
    // Cleanup starts after the focus attempt settles.
    void focusDestination(sourcePaneId, ctx).finally(() => void finishHandoff(sourcePaneId, ctx));
    pi.sendMessage(
      {
        customType: HANDOFF_MESSAGE_TYPE,
        content: HANDOFF_MESSAGE,
        display: false,
        details: {},
      },
      { triggerTurn: true, deliverAs: "steer" },
    );
  });

  async function focusDestination(sourcePaneId: string, ctx: ExtensionContext): Promise<void> {
    const pane = process.env.HERDR_PANE_ID;
    if (!pane) {
      ctx.ui.notify("Handoff destination pane ID is missing; focus was not moved.", "warning");
      return;
    }
    const deadline = Date.now() + 5000;
    const expired = () => Date.now() >= deadline;
    const remaining = () => Math.max(1, deadline - Date.now());
    const fail = (message: string) =>
      ctx.ui.notify(
        `Could not hand off focus from ${sourcePaneId} to ${pane}: ${message}`,
        "warning",
      );
    for (;;) {
      if (expired()) return fail("timed out");
      try {
        const source = await herdr(["pane", "get", sourcePaneId], undefined, remaining());
        const focused = source?.result?.pane?.focused;
        if (focused === false) return;
        if (focused !== true) {
          if (expired()) return fail("source focus state missing");
          await sleep(100);
          continue;
        }
        if (expired()) return fail("timed out");
        await herdr(["agent", "focus", pane], undefined, remaining());
        return;
      } catch (error) {
        if (expired()) return fail(error instanceof Error ? error.message : String(error));
        await sleep(100);
      }
    }
  }

  async function finishHandoff(sourcePaneId: string, ctx: ExtensionContext): Promise<void> {
    const report = (message: string) => ctx.ui.notify(message, "warning");
    let sourceSession: string | undefined;
    let oldWorkspaceId: string | undefined;
    let oldWorkspace: any;
    try {
      const old = await herdr(["pane", "get", sourcePaneId], undefined, 10000);
      sourceSession = old?.result?.pane?.agent_session?.value;
      oldWorkspaceId = old?.result?.pane?.workspace_id;
      oldWorkspace = oldWorkspaceId
        ? await herdr(["workspace", "get", oldWorkspaceId], undefined, 10000)
        : null;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      const workspaceId = sourcePaneId.split(":")[0];
      const workspaces = await herdrQuiet(["workspace", "list"]);
      const stillOpen = (workspaces?.result?.workspaces ?? []).some(
        (workspace: any) => workspace.workspace_id === workspaceId,
      );
      if (stillOpen) report(`Handoff source pane ${sourcePaneId} is unavailable: ${message}`);
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
      const agent = await herdrQuiet(["agent", "get", sourcePaneId], 10000);
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
        `Handoff from ${sourcePaneId} is unfinished: the old pane did not settle and was left open.`,
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
      await herdr(["pane", "close", sourcePaneId], undefined, 10000);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      report(`Could not close old pane ${sourcePaneId}: ${message}`);
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
