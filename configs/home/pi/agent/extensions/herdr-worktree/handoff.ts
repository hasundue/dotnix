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
  customEntryValues,
  handoffTargetsPane,
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
    const metadataValues = customEntryValues(entries, HANDOFF_METADATA_TYPE);
    const malformed = metadataValues.filter(
      (value) => !isHandoffMetadata(value) && handoffTargetsPane(value, destinationPaneId),
    );
    if (malformed.length > 0) {
      ctx.ui.notify(
        `Malformed handoff metadata targets pane ${destinationPaneId}; none was processed.`,
        "warning",
      );
      return;
    }
    const done = new Set(
      customEntryData(entries, HANDOFF_DONE_TYPE, isHandoffDone).map((entry) => entry.handoffId),
    );
    const pending = metadataValues
      .filter(isHandoffMetadata)
      .filter(
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
    const expectedSession = ctx.sessionManager.getHeader()?.parentSession;
    let verifiedSource: { session: string; workspaceId: string; workspace: any } | undefined;
    const verifySource = async (): Promise<boolean> => {
      if (!expectedSession) return false;
      const current = await herdrQuiet(["pane", "get", sourcePaneId], 10000);
      const session = current?.result?.pane?.agent_session?.value;
      if (typeof session !== "string" || session === "" || !samePath(session, expectedSession)) {
        return false;
      }
      const workspaceId: string | undefined = current?.result?.pane?.workspace_id;
      if (!workspaceId) return false;
      const workspace = await herdrQuiet(["workspace", "get", workspaceId], 10000);
      if (!workspace?.result?.workspace) return false;
      verifiedSource = { session, workspaceId, workspace };
      return true;
    };
    if (!(await verifySource())) {
      report("Handoff source session identity is unclear; the source pane was left open.");
      return;
    }
    const initialSource = verifiedSource;

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

    const oldWorktree = initialSource?.workspace?.result?.workspace?.worktree;
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

    const isMainCheckout =
      initialSource?.workspace?.result?.workspace?.worktree?.is_linked_worktree === false;
    const paneCount = initialSource?.workspace?.result?.workspace?.pane_count ?? 0;
    if (!(await verifySource())) {
      report("Handoff source pane changed before cleanup; the pane was left open.");
      return;
    }
    const tabSource = verifiedSource!;
    if (isMainCheckout && paneCount <= 1) {
      try {
        await herdr(
          [
            "tab",
            "create",
            "--workspace",
            tabSource.workspaceId,
            "--cwd",
            tabSource.workspace.result.workspace.worktree.checkout_path,
            "--no-focus",
          ],
          undefined,
          10000,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not create a replacement tab in ${tabSource.workspaceId}: ${message}`);
        return;
      }
    }

    if (!(await verifySource())) {
      report("Handoff source pane changed before cleanup; the pane was left open.");
      return;
    }
    const finalSource = verifiedSource!;
    try {
      await herdr(["pane", "close", sourcePaneId], undefined, 10000);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      report(`Could not close old pane ${sourcePaneId}: ${message}`);
      return;
    }

    try {
      await unlink(finalSource.session);
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      report(`Could not remove source session ${finalSource.session}: ${message}`);
    }
    if (isMainReturn && finalSource.workspaceId) {
      let workspaceStillOpen = false;
      try {
        const listed = await herdr(["workspace", "list"], undefined, 10000);
        workspaceStillOpen = (listed?.result?.workspaces ?? []).some(
          (workspace: any) => workspace.workspace_id === finalSource.workspaceId,
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not inspect old workspace ${finalSource.workspaceId}: ${message}`);
        return;
      }

      if (workspaceStillOpen) {
        try {
          await herdr(["workspace", "close", finalSource.workspaceId], undefined, 10000);
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          report(`Could not close old workspace ${finalSource.workspaceId}: ${message}`);
        }
      }
    }
  }
}
