/**
 * Toggle Bash Executions Visibility
 *
 * Shows or hides bash command executions in the TUI, similar to built-in
 * toggles for thinking blocks (`ctrl+t`) and tool output (`ctrl+o`).
 *
 * When hidden: bash commands render as dim one-liners with a brief status
 * (✓ done / ⚠ failed / running…).
 * When shown: normal bash rendering with full output, respecting the
 * built-in collapse/expand toggle (`ctrl+o`).
 *
 * Features:
 * - `/toggle-bash` command (alias `/tb`) to toggle visibility
 * - `Ctrl+Shift+B` keyboard shortcut to toggle
 * - `toggle_bash_executions` tool for the LLM to control
 * - State persists across sessions
 *
 * Usage:
 *   Place in ~/.pi/agent/extensions/toggle-bash/ or configure via
 *   home-manager, then run home-manager switch.
 */

import type {
  BashToolDetails,
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { createBashTool } from "@earendil-works/pi-coding-agent";
import { Key, Text } from "@earendil-works/pi-tui";
import { Type } from "typebox";

export default function (pi: ExtensionAPI) {
  let bashHidden = false;

  // ---------------------------------------------------------------------------
  // State management
  // ---------------------------------------------------------------------------

  function updateStatus(ctx: ExtensionContext): void {
    if (bashHidden) {
      ctx.ui.setWidget("toggle-bash", [
        ctx.ui.theme.fg("warning", "bash hidden"),
      ], {
        placement: "belowEditor",
      });
    } else {
      ctx.ui.setWidget("toggle-bash", undefined);
    }
  }

  function toggleBash(ctx: ExtensionContext): void {
    bashHidden = !bashHidden;
    updateStatus(ctx);
    persistState();
  }

  function persistState(): void {
    pi.appendEntry("toggle-bash-state", { hidden: bashHidden });
  }

  // ---------------------------------------------------------------------------
  // Command
  // ---------------------------------------------------------------------------

  pi.registerCommand("toggle-bash", {
    description: "Toggle showing/hiding of bash command executions",
    aliases: ["tb"],
    handler: async (_args, ctx) => toggleBash(ctx),
  });

  // ---------------------------------------------------------------------------
  // Keyboard shortcut
  // ---------------------------------------------------------------------------

  pi.registerShortcut(Key.ctrlShift("b"), {
    description: "Toggle bash command execution visibility",
    handler: async (ctx) => toggleBash(ctx),
  });

  // ---------------------------------------------------------------------------
  // Tool for the LLM to control visibility
  // ---------------------------------------------------------------------------

  pi.registerTool({
    name: "toggle_bash_executions",
    label: "Toggle Bash Executions",
    description:
      "Toggle showing or hiding bash command executions in the UI. When hidden, only a brief one-line summary of each bash command is shown.",
    promptSnippet: "Toggle bash execution visibility in the UI",
    promptGuidelines: [
      "Use toggle_bash_executions when the user asks to show or hide bash command executions.",
    ],
    parameters: Type.Object({
      hidden: Type.Optional(
        Type.Boolean({
          description:
            "If provided, set to specific visibility state (true = hidden, false = visible). Omit to toggle.",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, ctx) {
      if (params.hidden !== undefined) {
        bashHidden = params.hidden;
      } else {
        bashHidden = !bashHidden;
      }
      updateStatus(ctx);
      persistState();
      return {
        content: [
          {
            type: "text" as const,
            text: `Bash command executions are now ${
              bashHidden ? "hidden" : "visible"
            }.`,
          },
        ],
        details: {},
      };
    },
  });

  // ---------------------------------------------------------------------------
  // Override the built-in bash tool with custom rendering
  // ---------------------------------------------------------------------------

  // Create a cache of bash tools keyed by cwd so we delegate execution
  // to the correct working directory dynamically.
  const bashToolCache = new Map<string, ReturnType<typeof createBashTool>>();

  function getBashTool(cwd: string) {
    let tool = bashToolCache.get(cwd);
    if (!tool) {
      tool = createBashTool(cwd);
      bashToolCache.set(cwd, tool);
    }
    return tool;
  }

  const defaultBash = getBashTool(process.cwd());

  pi.registerTool({
    name: "bash",
    label: "bash",
    description: defaultBash.description,
    parameters: defaultBash.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tool = getBashTool(ctx.cwd);
      return tool.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, _context) {
      const command = args.command || "";
      if (bashHidden) {
        const truncated = command.length > 60
          ? command.slice(0, 57) + "..."
          : command;
        return new Text(theme.fg("dim", `$ ${truncated}`), 0, 0);
      }
      const timeout = args.timeout;
      const timeoutSuffix = timeout
        ? theme.fg("muted", ` (timeout ${timeout}s)`)
        : "";
      return new Text(
        theme.fg("toolTitle", theme.bold(`$ ${command}`)) + timeoutSuffix,
        0,
        0,
      );
    },

    renderResult(result, { expanded, isPartial }, theme, _context) {
      // --- Hidden mode: minimal one-liner ---
      if (bashHidden) {
        if (isPartial) return new Text(theme.fg("dim", "running…"), 0, 0);
        if (result.isError) {
          return new Text(theme.fg("error", "⚠ failed"), 0, 0);
        }
        return new Text(theme.fg("dim", "✓ done"), 0, 0);
      }

      // --- Visible mode: normal rendering ---
      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const output = textContent.text.trim();
      if (!output) return new Text("", 0, 0);

      // Collapsed (default ctrl+o state): show summary
      if (!expanded) {
        const exitMatch = output.match(/exit code: (\d+)/);
        const exitCode = exitMatch ? parseInt(exitMatch[1], 10) : null;
        const lineCount = output.split("\n").filter((l) => l.trim()).length;
        let status: string;
        if (exitCode === null || exitCode === 0) {
          status = theme.fg("success", "done");
        } else {
          status = theme.fg("error", `exit ${exitCode}`);
        }
        const details = result.details as BashToolDetails | undefined;
        const trunc = details?.truncation?.truncated
          ? theme.fg("warning", " [truncated]")
          : "";
        return new Text(
          `${status}${theme.fg("dim", ` (${lineCount} lines)`)}${trunc}`,
          0,
          0,
        );
      }

      // Expanded: show full output
      const lines = output
        .split("\n")
        .map((line) => theme.fg("toolOutput", line))
        .join("\n");
      return new Text(`\n${lines}`, 0, 0);
    },
  });

  // ---------------------------------------------------------------------------
  // Session lifecycle: restore state
  // ---------------------------------------------------------------------------

  pi.on("session_start", async (_event, ctx) => {
    const entries = ctx.sessionManager.getEntries();
    const stateEntry = entries
      .filter((e) =>
        e.type === "custom" && e.customType === "toggle-bash-state"
      )
      .pop() as { data?: { hidden: boolean } } | undefined;

    if (stateEntry?.data) {
      bashHidden = stateEntry.data.hidden ?? false;
    }

    updateStatus(ctx);
  });
}
