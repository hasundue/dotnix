/**
 * Herdr worktree — Registers the Herdr-only worktree move tool and completes
 * the handoff from the pane that requested it.
 *
 * The package is loaded in every session, but every path here returns unless
 * HERDR_ENV=1. AGENTS.md stays free of environment-specific worktree rules.
 */

import { existsSync, realpathSync } from "node:fs";
import { unlink } from "node:fs/promises";
import { basename, dirname, join, resolve } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const HANDOFF_FLAG = "herdr-worktree-handoff";
const HANDOFF_MESSAGE_TYPE = "herdr-worktree-handoff";
const HERDR_NOTICE =
  "You are running inside Herdr, a terminal multiplexer designed for coding agents, which manages workspaces, tabs, panes, and agent status.";

const moveSchema = Type.Object({
  branch: Type.Optional(
    Type.String({ description: "Branch to open or create; generated when omitted" }),
  ),
  path: Type.Optional(
    Type.String({ description: "Worktree path to open or create; generated when omitted" }),
  ),
});

type Worktree = {
  branch?: string;
  path?: string;
  checkout_path?: string;
  is_linked_worktree?: boolean;
  open_workspace_id?: string;
};

type Placement = {
  workspaceId?: string;
  tabId?: string;
  rootPaneId?: string;
  worktree?: Worktree;
};

const sleep = (ms: number) => new Promise<void>((done) => setTimeout(done, ms));

function samePath(left: string, right: string): boolean {
  if (!existsSync(left) || !existsSync(right)) return resolve(left) === resolve(right);
  try {
    return realpathSync(left) === realpathSync(right);
  } catch {
    return resolve(left) === resolve(right);
  }
}

function textResult(text: string, isError = false) {
  return { content: [{ type: "text" as const, text }], details: {}, isError };
}

export default function (pi: ExtensionAPI) {
  if (process.env.HERDR_ENV !== "1") return;

  const oldPaneId = process.env.HERDR_PANE_ID;
  let handoffStarted = false;

  pi.registerFlag(HANDOFF_FLAG, {
    description: "Old Herdr pane ID for a worktree handoff",
    type: "string",
  });

  pi.on("before_agent_start", (event) => {
    event.systemPromptOptions.sections.herdr = HERDR_NOTICE;
  });

  pi.on("session_start", (_event, ctx) => {
    const handoffFrom = pi.getFlag(HANDOFF_FLAG);
    if (handoffStarted || typeof handoffFrom !== "string" || handoffFrom === "") return;
    handoffStarted = true;
    pi.sendMessage(
      {
        customType: HANDOFF_MESSAGE_TYPE,
        content:
          "The worktree move completed in this session. Continue the original task here. Do not repeat the worktree move.",
        display: false,
        details: {},
      },
      { triggerTurn: true, deliverAs: "steer" },
    );
    void finishHandoff(handoffFrom, ctx);
  });

  async function herdr(args: string[], signal?: AbortSignal, timeout = 180000): Promise<any> {
    // `agent start` may wait 120 s for the forked agent to become ready.
    const result = await pi.exec("herdr", args, { signal, timeout });
    if (result.code !== 0) {
      throw new Error(result.stderr.trim() || `herdr ${args.join(" ")} failed`);
    }
    if (result.stdout.trim() === "") return {};
    try {
      return JSON.parse(result.stdout);
    } catch {
      throw new Error(`herdr ${args.join(" ")} returned non-JSON output`);
    }
  }

  async function herdrQuiet(args: string[], timeout = 180000): Promise<any | null> {
    try {
      return await herdr(args, undefined, timeout);
    } catch {
      return null;
    }
  }

  async function verifyWorktreeHooks(
    since: number,
    repoRoot: string,
    checkout: string,
  ): Promise<void> {
    const deadline = Date.now() + 30000;
    for (;;) {
      const logs = await herdrQuiet(["plugin", "log", "list"], 10000);
      const ran = (logs?.result?.logs ?? []).some(
        (log: any) =>
          log.plugin_id === "local.worktree-hooks" &&
          log.event === "worktree.created" &&
          log.status === "succeeded" &&
          typeof log.finished_unix_ms === "number" &&
          log.finished_unix_ms >= since - 1000,
      );
      // The log is global; check that this checkout received the copied files.
      const copied = [".envrc", ".pi/settings.json"].every(
        (relative) => !existsSync(join(repoRoot, relative)) || existsSync(join(checkout, relative)),
      );
      if (ran && copied) return;
      if (Date.now() >= deadline) break;
      await sleep(500);
    }
    throw new Error(
      `local.worktree-hooks did not run worktree.created hooks for ${checkout}; stopping before Pi starts`,
    );
  }

  function placement(payload: any): Placement {
    const result = payload?.result ?? {};
    const workspace = result.workspace ?? result.worktree?.workspace ?? {};
    const tab = result.tab ?? {};
    const rootPane = result.root_pane ?? {};
    return {
      workspaceId: workspace.workspace_id ?? result.workspace_id,
      tabId: tab.tab_id ?? result.tab_id,
      rootPaneId: rootPane.pane_id ?? result.root_pane_id,
      worktree: result.worktree,
    };
  }

  function findTarget(worktrees: Worktree[], branch?: string, path?: string): Worktree | undefined {
    if (path) {
      const wanted = resolve(path.replace(/^@/, ""));
      return worktrees.find((worktree) => worktree.path && samePath(worktree.path, wanted));
    }
    if (branch) return worktrees.find((worktree) => worktree.branch === branch);
    return undefined;
  }

  function worktreePath(worktree: Worktree | undefined): string | undefined {
    return worktree?.path ?? worktree?.checkout_path;
  }

  function agentName(branch: string): string {
    const slug = branch
      .toLowerCase()
      .replace(/[^a-z0-9_-]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 20);
    return `${slug || "worktree"}-${Date.now().toString(36).slice(-5)}`;
  }

  pi.registerTool({
    name: "herdr_worktree_move",
    label: "Move worktree",
    description:
      "Move this Pi session between the main checkout and Git worktrees in Herdr. Branch and path are optional; omitted values are generated. Use branch 'main' to return to the main checkout.",
    promptSnippet: "Move the current work between the main checkout and Git worktrees in Herdr",
    promptGuidelines: [
      "Use herdr_worktree_move for worktree requests in Herdr, with no arguments when no branch or path was named and branch 'main' when returning to main.",
    ],
    parameters: moveSchema,

    async execute(_toolCallId, params, signal, _onUpdate, ctx) {
      if (!oldPaneId) return textResult("HERDR_PANE_ID is missing; cannot hand off.", true);

      const cwd = resolve(ctx.cwd);
      const requestedPath = params.path ? resolve(params.path.replace(/^@/, "")) : undefined;
      try {
        const current = await herdr(["pane", "get", oldPaneId], signal);
        const oldWorkspaceId: string | undefined = current?.result?.pane?.workspace_id;
        const oldWorkspace = oldWorkspaceId
          ? await herdr(["workspace", "get", oldWorkspaceId], signal)
          : null;
        const repoRoot: string = oldWorkspace?.result?.workspace?.worktree?.repo_root ?? cwd;
        const listed = await herdr(["worktree", "list", "--cwd", repoRoot], signal);
        const worktrees: Worktree[] = listed?.result?.worktrees ?? [];
        const target = findTarget(worktrees, params.branch, requestedPath);
        const targetPath = worktreePath(target);
        const returningToMain =
          !!target &&
          target.is_linked_worktree !== true &&
          !!targetPath &&
          samePath(targetPath, repoRoot);

        if (targetPath && samePath(targetPath, cwd)) {
          return textResult(
            `Already at ${cwd}; no handoff needed. Continue the requested work here.`,
          );
        }
        if (
          !params.branch &&
          !params.path &&
          worktrees.some((w) => w.is_linked_worktree && w.path && samePath(w.path, cwd))
        ) {
          return textResult(
            `Already in a linked worktree at ${cwd}; no handoff needed. Continue the requested work here.`,
          );
        }

        let opened: any;
        let action: "opened" | "created";
        let createdAt: number | undefined;
        let createdPath: string | undefined;
        const leftover = () =>
          createdPath ? ` The worktree at ${createdPath} was left for manual cleanup.` : "";
        if (target) {
          opened = await herdr(
            [
              "worktree",
              "open",
              "--cwd",
              repoRoot,
              targetPath ? "--path" : "--branch",
              targetPath ?? params.branch!,
              "--no-focus",
            ],
            signal,
          );
          action = "opened";
        } else {
          const branch = params.branch ?? `pi-worktree-${Date.now().toString(36)}`;
          const path =
            requestedPath ??
            resolve(
              dirname(repoRoot),
              `${basename(repoRoot)}.${branch.replace(/[^a-zA-Z0-9._-]+/g, "-")}`,
            );
          createdAt = Date.now();
          createdPath = path;
          opened = await herdr(
            [
              "worktree",
              "create",
              "--cwd",
              repoRoot,
              "--branch",
              branch,
              "--base",
              "main",
              "--path",
              path,
              "--no-focus",
            ],
            signal,
          );
          action = "created";
        }

        const placed = placement(opened);
        const { workspaceId, worktree } = placed;
        let { tabId, rootPaneId } = placed;
        const checkout = worktreePath(worktree) ?? createdPath;
        if (returningToMain) {
          if (!workspaceId) throw new Error(`Herdr response has no workspace ID${leftover()}`);
          const createdTab = await herdr(
            ["tab", "create", "--workspace", workspaceId, "--cwd", repoRoot, "--no-focus"],
            signal,
          );
          const tabPlacement = placement(createdTab);
          tabId = tabPlacement.tabId ?? tabId;
          rootPaneId = tabPlacement.rootPaneId;
          if (!rootPaneId) {
            throw new Error(`Herdr tab create returned no root pane ID${leftover()}`);
          }
        }
        if (!rootPaneId) throw new Error(`Herdr response has no root pane ID${leftover()}`);
        if (action === "created" && !worktreePath(worktree)) {
          throw new Error(
            `Herdr did not return worktree metadata; stopping before Pi starts${leftover()}`,
          );
        }
        if (createdAt !== undefined && checkout) {
          try {
            await verifyWorktreeHooks(createdAt, repoRoot, checkout);
          } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            throw new Error(`${message}${leftover()}`);
          }
        }

        const sessionFile: unknown = current?.result?.pane?.agent_session?.value;
        if (typeof sessionFile !== "string" || sessionFile === "") {
          throw new Error(`Current pane has no agent session file${leftover()}`);
        }

        const rootBefore = await herdr(["pane", "get", rootPaneId], signal);
        const rootSessionBefore: unknown = rootBefore?.result?.pane?.agent_session?.value;
        const forkStarted = async (): Promise<boolean | undefined> => {
          try {
            const after = await herdr(["pane", "get", rootPaneId], undefined, 10000);
            const session: unknown = after?.result?.pane?.agent_session?.value;
            return (
              typeof session === "string" &&
              session !== "" &&
              session !== sessionFile &&
              session !== rootSessionBefore
            );
          } catch {
            return undefined;
          }
        };
        const waitForFork = async (ms: number): Promise<boolean | undefined> => {
          const until = Date.now() + ms;
          for (;;) {
            const started = await forkStarted();
            if (started === true || Date.now() >= until) return started;
            await sleep(500);
          }
        };

        const agent = agentName(
          worktree?.branch ?? params.branch ?? (action === "created" ? "pi-worktree" : "existing"),
        );
        try {
          await herdr(
            [
              "agent",
              "start",
              agent,
              "--kind",
              "pi",
              "--pane",
              rootPaneId,
              "--timeout",
              "120000",
              "--",
              `--${HANDOFF_FLAG}`,
              oldPaneId,
              "-a",
              "--fork",
              sessionFile,
            ],
            signal,
          );
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          const maybeStarted = /timeout|agent_not_ready/i.test(message);
          const started = await waitForFork(maybeStarted ? 10000 : 2000);
          if (started !== true) throw new Error(`${message}${leftover()}`);
        }
        const started = await waitForFork(10000);
        if (started !== true) {
          throw new Error(
            `Agent start did not yield a forked session in pane ${rootPaneId}${leftover()}`,
          );
        }
        await herdrQuiet(["agent", "focus", agent], 10000);

        const destination = worktreePath(worktree) ?? targetPath ?? "the worktree";
        const summary = returningToMain
          ? `Returned to the main checkout at ${destination} in a new tab. The old Herdr workspace will be closed by the forked session.`
          : `${action === "created" ? "Created" : "Opened"} worktree at ${destination}.`;
        return {
          content: [
            {
              type: "text" as const,
              text: `${summary} Forked this session into pane ${rootPaneId}; the old pane ID was passed to the forked session.`,
            },
          ],
          details: {
            workspaceId,
            tabId,
            rootPaneId,
            oldPaneId,
            oldWorkspaceId,
            destination,
            action,
            returningToMain,
          },
          terminate: true,
        };
      } catch (error) {
        return textResult(error instanceof Error ? error.message : String(error), true);
      }
    },
  });

  async function finishHandoff(oldPane: string, ctx: any): Promise<void> {
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
    }

    if (typeof sourceSession === "string" && sourceSession !== "") {
      try {
        await unlink(sourceSession);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        report(`Could not remove source session ${sourceSession}: ${message}`);
      }
    }
    if (oldWorkspaceId) {
      const mainPane = process.env.HERDR_PANE_ID;
      const current = mainPane ? await herdrQuiet(["pane", "get", mainPane], 10000) : null;
      const currentWorkspaceId = current?.result?.pane?.workspace_id;
      const isMainReturn = currentWorkspaceId === oldWorkspaceId;
      if (isMainReturn) {
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
