/**
 * Read-only Mode Extension
 *
 * Read-only exploration mode for safe code analysis, brainstorming,
 * discussion, and research. When enabled, write/edit tools are disabled
 * and bash is restricted to an allowlist of safe commands.
 *
 * Features:
 * - /readonly command or Ctrl+R to toggle
 * - Bash restricted to allowlisted read-only commands
 * - System prompt modification enforcing read-only mode
 * - disable_readonly_mode tool to auto-exit when user wants changes
 */

import type { AgentMessage } from "@earendil-works/pi-agent-core";
import type { AssistantMessage, TextContent } from "@earendil-works/pi-ai";
import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";
import { Key } from "@earendil-works/pi-tui";
import { Type } from "typebox";

const READONLY_TOOLS = [
  "read",
  "bash",
  "grep",
  "find",
  "ls",
  "questionnaire",
  "disable_readonly_mode",
];
const NORMAL_TOOLS = ["read", "bash", "edit", "write"];

// Destructive commands blocked in readonly mode
const DESTRUCTIVE_PATTERNS = [
  /\brm\b/i,
  /\brmdir\b/i,
  /\bmv\b/i,
  /\bcp\b/i,
  /\bmkdir\b/i,
  /\btouch\b/i,
  /\bchmod\b/i,
  /\bchown\b/i,
  /\bchgrp\b/i,
  /\bln\b/i,
  /\btee\b/i,
  /\btruncate\b/i,
  /\bdd\b/i,
  /\bshred\b/i,
  /(^|[^<])>(?!>)/,
  />>/,
  /\bnpm\s+(install|uninstall|update|ci|link|publish)/i,
  /\byarn\s+(add|remove|install|publish)/i,
  /\bpnpm\s+(add|remove|install|publish)/i,
  /\bpip\s+(install|uninstall)/i,
  /\bapt(-get)?\s+(install|remove|purge|update|upgrade)/i,
  /\bbrew\s+(install|uninstall|upgrade)/i,
  /\bgit\s+(add|commit|push|pull|merge|rebase|reset|checkout|branch\s+-[dD]|stash|cherry-pick|revert|tag|init|clone)/i,
  /\bsudo\b/i,
  /\bsu\b/i,
  /\bkill\b/i,
  /\bpkill\b/i,
  /\bkillall\b/i,
  /\breboot\b/i,
  /\bshutdown\b/i,
  /\bsystemctl\s+(start|stop|restart|enable|disable)/i,
  /\bservice\s+\S+\s+(start|stop|restart)/i,
  /\b(vim?|nano|emacs|code|subl)\b/i,
];

// Safe read-only commands allowed in readonly mode
const SAFE_PATTERNS = [
  /^\s*cat\b/,
  /^\s*head\b/,
  /^\s*tail\b/,
  /^\s*less\b/,
  /^\s*more\b/,
  /^\s*grep\b/,
  /^\s*find\b/,
  /^\s*ls\b/,
  /^\s*pwd\b/,
  /^\s*echo\b/,
  /^\s*printf\b/,
  /^\s*wc\b/,
  /^\s*sort\b/,
  /^\s*uniq\b/,
  /^\s*diff\b/,
  /^\s*file\b/,
  /^\s*stat\b/,
  /^\s*du\b/,
  /^\s*df\b/,
  /^\s*tree\b/,
  /^\s*which\b/,
  /^\s*whereis\b/,
  /^\s*type\b/,
  /^\s*env\b/,
  /^\s*printenv\b/,
  /^\s*uname\b/,
  /^\s*whoami\b/,
  /^\s*id\b/,
  /^\s*date\b/,
  /^\s*cal\b/,
  /^\s*uptime\b/,
  /^\s*ps\b/,
  /^\s*top\b/,
  /^\s*htop\b/,
  /^\s*free\b/,
  /^\s*git\s+(status|log|diff|show|branch|remote|config\s+--get)/i,
  /^\s*git\s+ls-/i,
  /^\s*npm\s+(list|ls|view|info|search|outdated|audit)/i,
  /^\s*yarn\s+(list|info|why|audit)/i,
  /^\s*node\s+--version/i,
  /^\s*python\s+--version/i,
  /^\s*curl\s/i,
  /^\s*wget\s+-O\s*-/i,
  /^\s*jq\b/,
  /^\s*sed\s+-n/i,
  /^\s*awk\b/,
  /^\s*rg\b/,
  /^\s*fd\b/,
  /^\s*bat\b/,
  /^\s*eza\b/,
];

function isSafeCommand(command: string): boolean {
  const isDestructive = DESTRUCTIVE_PATTERNS.some((p) => p.test(command));
  const isSafe = SAFE_PATTERNS.some((p) => p.test(command));
  return !isDestructive && isSafe;
}

export default function readonlyModeExtension(pi: ExtensionAPI): void {
  let readonlyModeEnabled = false;

  pi.registerFlag("readonly", {
    description:
      "Start in read-only mode (exploration, brainstorming, research)",
    type: "boolean",
    default: false,
  });

  function updateStatus(ctx: ExtensionContext): void {
    if (readonlyModeEnabled) {
      ctx.ui.setWidget("readonly-mode", [
        ctx.ui.theme.fg("warning", "read-only"),
      ], {
        placement: "belowEditor",
      });
    } else {
      ctx.ui.setWidget("readonly-mode", undefined);
    }
  }

  function toggleReadonlyMode(ctx: ExtensionContext): void {
    readonlyModeEnabled = !readonlyModeEnabled;

    if (readonlyModeEnabled) {
      pi.setActiveTools(READONLY_TOOLS);
    } else {
      pi.setActiveTools(NORMAL_TOOLS);
    }
    updateStatus(ctx);
  }

  pi.registerCommand("readonly", {
    description: "Toggle read-only mode (exploration, brainstorming, research)",
    aliases: ["ro"],
    handler: async (_args, ctx) => {
      toggleReadonlyMode(ctx);
      persistState();
    },
  });

  pi.registerShortcut(Key.ctrl("r"), {
    description: "Toggle read-only mode",
    handler: async (ctx) => toggleReadonlyMode(ctx),
  });

  // Register a tool that the LLM can call to disable readonly mode
  pi.registerTool({
    name: "disable_readonly_mode",
    label: "Disable Read-only Mode",
    description:
      "Disable read-only mode and restore full tool access (edit, write). Only call this when the user gives a clear, unambiguous instruction to make actual changes. Do NOT call this for theoretical or hypothetical questions.",
    promptSnippet:
      "Disable read-only mode. Use when the user clearly wants to make changes.",
    promptGuidelines: [
      "Use disable_readonly_mode when the user gives a direct instruction to edit, write, or modify files — do not ask them to do it manually.",
    ],
    parameters: Type.Object({
      reason: Type.String({
        description:
          "Brief reason for disabling read-only mode (e.g., 'user requested file edit')",
      }),
    }),
    execute: async (_toolCallId, params, _signal, _onUpdate, ctx) => {
      readonlyModeEnabled = false;
      pi.setActiveTools(NORMAL_TOOLS);
      updateStatus(ctx);
      persistState();
      ctx.ui.notify(
        "Read-only mode disabled (LLM detected explicit edit request).",
        "info",
      );
      return {
        content: [{
          type: "text",
          text:
            `Read-only mode disabled. Reason: ${params.reason}. Full access restored.`,
        }],
        details: {},
      };
    },
  });

  // Block destructive bash commands in readonly mode
  pi.on("tool_call", async (event) => {
    if (!readonlyModeEnabled || event.toolName !== "bash") return;

    const command = event.input.command as string;
    if (!isSafeCommand(command)) {
      return {
        block: true,
        reason:
          `Read-only mode: command blocked (not allowlisted).\nCommand: ${command}`,
      };
    }
  });

  // Filter out stale readonly mode context when not in readonly mode
  pi.on("context", async (event) => {
    if (readonlyModeEnabled) return;

    return {
      messages: event.messages.filter((m) => {
        const msg = m as AgentMessage & { customType?: string };
        if (msg.customType === "readonly-mode-context") return false;
        if (msg.role !== "user") return true;

        const content = msg.content;
        if (typeof content === "string") {
          return !content.includes("[READ-ONLY MODE ACTIVE]");
        }
        if (Array.isArray(content)) {
          return !content.some(
            (c) =>
              c.type === "text" &&
              (c as TextContent).text?.includes("[READ-ONLY MODE ACTIVE]"),
          );
        }
        return true;
      }),
    };
  });

  // Append read-only instructions to the system prompt
  pi.on("before_agent_start", async (event) => {
    if (!readonlyModeEnabled) return;

    return {
      systemPrompt: event.systemPrompt + `

[READ-ONLY MODE ACTIVE]
You are in read-only mode. You must NOT use edit or write tools.
Bash is restricted to an allowlist of read-only commands.
Do NOT make any changes — explore, discuss, and describe what could be done.

User questions about edit/write operations in read-only mode are THEORETICAL.
Answer them by explaining feasibility, approach, and trade-offs — do NOT execute.

If the user gives a clear instruction to make actual changes (e.g. "edit this file",
"write the fix", "go ahead"), call the disable_readonly_mode tool to automatically
switch to normal mode. Do NOT ask the user to disable readonly mode manually.`,
    };
  });

  // Persist state
  function persistState(): void {
    pi.appendEntry("readonly-mode", {
      enabled: readonlyModeEnabled,
    });
  }

  // Restore state on session start/resume
  pi.on("session_start", async (_event, ctx) => {
    if (pi.getFlag("readonly") === true) {
      readonlyModeEnabled = true;
    }

    const entries = ctx.sessionManager.getEntries();
    const readonlyEntry = entries
      .filter((e: { type: string; customType?: string }) =>
        e.type === "custom" && e.customType === "readonly-mode"
      )
      .pop() as { data?: { enabled: boolean } } | undefined;

    if (readonlyEntry?.data) {
      readonlyModeEnabled = readonlyEntry.data.enabled ?? readonlyModeEnabled;
    }

    if (readonlyModeEnabled) {
      pi.setActiveTools(READONLY_TOOLS);
    }
    updateStatus(ctx);
  });
}
