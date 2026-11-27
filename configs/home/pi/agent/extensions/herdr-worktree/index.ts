/**
 * Herdr worktree — the always-loaded entry point. It registers the Herdr-only
 * worktree move tool; handoff cleanup lives in handoff.ts, loaded only in the
 * destination. Both entries return unless HERDR_ENV=1, so sessions outside
 * Herdr receive no Herdr-specific instructions.
 */

import { existsSync } from "node:fs";
import { mkdir, unlink, writeFile } from "node:fs/promises";
import { homedir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

import {
  HANDOFF_ACTION,
  HANDOFF_PLUGIN,
  createHerdr,
  handoffArgs,
  registerHerdrNotice,
  samePath,
  sleep,
  textResult,
  type Placement,
  type Worktree,
} from "./common.ts";

const moveSchema = Type.Object({
  branch: Type.Optional(
    Type.String({ description: "Branch to open or create; generated when omitted" }),
  ),
  path: Type.Optional(
    Type.String({ description: "Worktree path to open or create; generated when omitted" }),
  ),
});

type MoveDetails = {
  destination?: string;
  rootPaneId?: string;
  oldPaneId?: string;
  action?: string;
};

export default function (pi: ExtensionAPI) {
  if (process.env.HERDR_ENV !== "1") return;

  registerHerdrNotice(pi);
  const { herdr, herdrQuiet } = createHerdr(pi);

  const oldPaneId = process.env.HERDR_PANE_ID;

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

    renderResult(result, { expanded, isPartial }, theme, _context) {
      if (isPartial) return new Text(theme.fg("warning", "Moving..."), 0, 0);

      const firstText = result.content.find((part) => part.type === "text");
      const message = firstText?.type === "text" ? firstText.text : "";
      if (result.isError) {
        return new Text(
          theme.fg("error", `herdr_worktree_move: ${message.split("\n")[0]}`),
          0,
          0,
        );
      }

      let display = theme.fg("toolTitle", "herdr_worktree_move");
      if (expanded) {
        const details = result.details as MoveDetails | undefined;
        const fields: Array<[string, string | undefined]> = [
          ["destination", details?.destination],
          ["pane", details?.rootPaneId],
          ["old pane", details?.oldPaneId],
          ["action", details?.action],
        ];
        for (const [label, value] of fields) {
          if (value !== undefined) {
            display += `\n${theme.fg("muted", `${label}: `)}${theme.fg("toolOutput", value)}`;
          }
        }
      }
      return new Text(display, 0, 0);
    },

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

        const agent = agentName(
          worktree?.branch ?? params.branch ?? (action === "created" ? "pi-worktree" : "existing"),
        );
        const stateDir = join(homedir(), ".local/state/herdr/plugins", HANDOFF_PLUGIN);
        await mkdir(stateDir, { recursive: true });
        const job = {
          agent,
          pane: rootPaneId,
          session: sessionFile,
          oldPane: oldPaneId,
          extraArgs: handoffArgs(),
        };
        const jobPath = join(stateDir, `handoff-${Date.now()}-${agent}.json`);
        await writeFile(jobPath, JSON.stringify(job));
        try {
          await herdr(
            ["plugin", "action", "invoke", HANDOFF_ACTION, "--plugin", HANDOFF_PLUGIN],
            signal,
          );
        } catch (error) {
          await unlink(jobPath).catch(() => undefined);
          throw error;
        }

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
}
