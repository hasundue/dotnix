/**
 * Herdr worktree — Registers the Herdr-only worktree move tool and completes
 * the handoff from the pane that requested it.
 *
 * The package is loaded in every session, but every path here returns unless
 * HERDR_ENV=1. AGENTS.md stays free of environment-specific worktree rules.
 */

import { existsSync, realpathSync } from "node:fs";
import { basename, dirname, resolve } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";

const SOURCE = "herdr:pi-handoff";
const TOKEN = "old_pane_id";

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
  let userRequest = "";

  pi.on("before_agent_start", (event) => {
    if (event.messageType === "user" && typeof event.prompt === "string") {
      userRequest = event.prompt;
    }
  });

  pi.on("session_start", () => {
    if (!oldPaneId) return;
    void finishHandoff(oldPaneId);
  });

  async function herdr(args: string[], signal?: AbortSignal): Promise<any> {
    const result = await pi.exec("herdr", args, { signal, timeout: 60000 });
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

  async function herdrQuiet(args: string[]): Promise<any | null> {
    try {
      return await herdr(args);
    } catch {
      return null;
    }
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
      try {
        const current = await herdr(["pane", "get", oldPaneId], signal);
        const oldWorkspaceId: string | undefined = current?.result?.pane?.workspace_id;
        const oldWorkspace = oldWorkspaceId
          ? await herdr(["workspace", "get", oldWorkspaceId], signal)
          : null;
        const repoRoot: string = oldWorkspace?.result?.workspace?.worktree?.repo_root ?? cwd;
        const listed = await herdr(["worktree", "list", "--cwd", repoRoot], signal);
        const worktrees: Worktree[] = listed?.result?.worktrees ?? [];
        const target = findTarget(worktrees, params.branch, params.path);
        const targetPath = worktreePath(target);
        const returningToMain =
          !!target &&
          target.is_linked_worktree === false &&
          !!targetPath &&
          samePath(targetPath, repoRoot);

        if (targetPath && samePath(targetPath, cwd)) {
          return textResult(
            `Already in worktree ${cwd}; no handoff needed. Continue the requested work here.`,
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
            params.path ??
            resolve(
              dirname(repoRoot),
              `${basename(repoRoot)}.${branch.replace(/[^a-zA-Z0-9._-]+/g, "-")}`,
            );
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

        const { workspaceId, tabId, rootPaneId, worktree } = placement(opened);
        if (!rootPaneId) throw new Error("Herdr response has no root pane ID");

        const sessionFile: unknown = current?.result?.pane?.agent_session?.value;
        if (typeof sessionFile !== "string" || sessionFile === "") {
          throw new Error("Current pane has no agent session file");
        }

        await herdr(
          [
            "pane",
            "report-metadata",
            rootPaneId,
            "--source",
            SOURCE,
            "--token",
            `${TOKEN}=${oldPaneId}`,
          ],
          signal,
        );

        const agent = agentName(
          worktree?.branch ?? params.branch ?? (action === "created" ? "pi-worktree" : "existing"),
        );
        const prompt =
          userRequest ||
          (returningToMain
            ? "Continue the requested work in the main checkout."
            : "Continue the requested work in this worktree.");
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
              "-a",
              "--fork",
              sessionFile,
              prompt,
            ],
            signal,
          );
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          const maybeStarted = /timeout|agent_not_ready/i.test(message);
          const rootAfter = maybeStarted ? await herdrQuiet(["pane", "get", rootPaneId]) : null;
          const newSession: unknown = rootAfter?.result?.pane?.agent_session?.value;
          if (typeof newSession !== "string" || newSession === sessionFile) {
            await herdrQuiet([
              "pane",
              "report-metadata",
              rootPaneId,
              "--source",
              SOURCE,
              "--clear-token",
              TOKEN,
            ]);
            throw error;
          }
        }

        if (returningToMain && oldWorkspaceId) {
          await herdrQuiet(["workspace", "close", oldWorkspaceId]);
        }

        const destination = worktreePath(worktree) ?? targetPath ?? "the worktree";
        const summary = returningToMain
          ? `Returned to the main checkout at ${destination}. The old Herdr workspace is being closed.`
          : `${action === "created" ? "Created" : "Opened"} worktree at ${destination}.`;
        return {
          content: [
            {
              type: "text" as const,
              text: `${summary} Forked this session into pane ${rootPaneId}; the old pane is being retired.`,
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
        };
      } catch (error) {
        return textResult(error instanceof Error ? error.message : String(error), true);
      }
    },
  });

  async function finishHandoff(newPane: string): Promise<void> {
    const pane = await herdrQuiet(["pane", "get", newPane]);
    const oldPane = pane?.result?.pane?.tokens?.[TOKEN];
    if (typeof oldPane !== "string" || oldPane === "") return;

    let sawWorking = false;
    for (let attempt = 0; attempt < 80; attempt += 1) {
      const agent = await herdrQuiet(["agent", "get", oldPane]);
      const state = agent?.result?.agent?.agent_status;
      if (state === undefined) break;
      if (state === "working" || state === "blocked") sawWorking = true;
      if (sawWorking && (state === "idle" || state === "done" || state === "unknown")) break;
      await sleep(500);
    }

    const old = await herdrQuiet(["pane", "get", oldPane]);
    const workspaceId = old?.result?.pane?.workspace_id;
    const workspace = workspaceId ? await herdrQuiet(["workspace", "get", workspaceId]) : null;
    const paneCount = workspace?.result?.workspace?.pane_count ?? 0;
    const isAgentPane = typeof old?.result?.pane?.agent === "string";
    if (paneCount > 1 && isAgentPane) {
      await herdrQuiet(["pane", "close", oldPane]);
    }

    await herdrQuiet([
      "pane",
      "report-metadata",
      newPane,
      "--source",
      SOURCE,
      "--clear-token",
      TOKEN,
    ]);
  }
}
