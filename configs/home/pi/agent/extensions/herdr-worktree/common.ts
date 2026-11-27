/**
 * Herdr worktree — constants, types, and helpers shared by the always-loaded
 * tool extension and the destination-only handoff extension.
 */

import { existsSync, realpathSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";

import type { ExtensionAPI, ToolRenderers } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

export const MOVE_TOOL = "herdr_worktree_move";
export const HANDOFF_FLAG = "herdr-worktree-handoff";
export const HANDOFF_ACTION = "handoff";
export const HANDOFF_PLUGIN = "local.worktree-handoff";
export const HANDOFF_MESSAGE_TYPE = "herdr-worktree-handoff";
export const HERDR_NOTICE =
  "You are running inside Herdr, a terminal multiplexer designed for coding agents, which manages workspaces, tabs, panes, and agent status.";
export const HANDOFF_MESSAGE =
  "The worktree move is already complete. Do not perform another move. Report that it is done if the move was the request; otherwise continue the remaining task.";

export const EXTENSION_DIR = dirname(fileURLToPath(import.meta.url));
const IS_DEV_EXTENSION = process.env.HERDR_WORKTREE_DEV === "1";

export type Worktree = {
  branch?: string;
  path?: string;
  checkout_path?: string;
  is_linked_worktree?: boolean;
  open_workspace_id?: string;
};

export type Placement = {
  workspaceId?: string;
  tabId?: string;
  rootPaneId?: string;
  worktree?: Worktree;
};

type MoveDetails = {
  destination?: string;
  rootPaneId?: string;
  oldPaneId?: string;
};

export const renderMoveResult: NonNullable<ToolRenderers["renderResult"]> = (
  result,
  { expanded, isPartial },
  theme,
  _context,
) => {
  if (isPartial) return new Text(theme.fg("warning", "Moving..."), 0, 0);

  const firstText = result.content.find((part) => part.type === "text");
  const message = firstText?.type === "text" ? firstText.text : "";
  if (result.isError) {
    return new Text(theme.fg("error", `${MOVE_TOOL}: ${message.split("\n")[0]}`), 0, 0);
  }

  if (!expanded) return new Text("", 0, 0);

  const details = result.details as MoveDetails | undefined;
  const destination = details?.destination ?? "the worktree";
  const pane = details?.rootPaneId ?? "unknown";
  const from = details?.oldPaneId ?? "unknown";
  const sentence = `Queued move to ${destination} in pane ${pane} from ${from}.`;
  return new Text(`\n${theme.fg("muted", sentence)}`, 0, 0);
};

export const sleep = (ms: number) => new Promise<void>((done) => setTimeout(done, ms));

export function samePath(left: string, right: string): boolean {
  if (!existsSync(left) || !existsSync(right)) return resolve(left) === resolve(right);
  try {
    return realpathSync(left) === realpathSync(right);
  } catch {
    return resolve(left) === resolve(right);
  }
}

export function hookCompletionPath(stdout: unknown): string | undefined {
  if (typeof stdout !== "string") return undefined;
  const lines = stdout.trim().split("\n");
  const line = lines[lines.length - 1];
  try {
    const marker = JSON.parse(line);
    if (marker.event === "worktree.created" && typeof marker.worktree === "string") {
      return marker.worktree;
    }
  } catch {
    // Hook commands may write non-JSON output before the completion marker.
  }
  return undefined;
}

export function textResult(text: string, isError = false) {
  return { content: [{ type: "text" as const, text }], details: {}, isError };
}

/** Arguments for the Pi that receives the handoff, after `--` in the plugin action. */
export function handoffArgs(): string[] {
  const args = ["-e", join(EXTENSION_DIR, "handoff.ts")];
  return IS_DEV_EXTENSION
    ? [
        "--no-extensions",
        "-e",
        join(homedir(), ".pi/agent/extensions/herdr-agent-state.ts"),
        ...args,
      ]
    : args;
}

export function registerHerdrNotice(pi: ExtensionAPI): void {
  pi.on("before_agent_start", (event) => {
    event.systemPromptOptions.sections.herdr = HERDR_NOTICE;
  });
}

export function createHerdr(pi: ExtensionAPI) {
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

  return { herdr, herdrQuiet };
}
