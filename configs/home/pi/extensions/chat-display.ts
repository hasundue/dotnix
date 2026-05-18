/**
 * chat-display — Controls the main chat area UI, overriding default
 * tool renderers for a "minimal" look while keeping the built-in edit
 * tool rendering (Box + diff preview) intact.
 *
 * Based on the minimal-mode example from pi's extension library, with
 * the key difference that the edit tool omits renderCall/renderResult
 * so it falls through to the built-in renderers, preserving the colored
 * block + diff preview that tool's `renderShell: "self"` requires.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import {
  createBashTool,
  createEditTool,
  createFindTool,
  createGrepTool,
  createLsTool,
  createReadTool,
  createWriteTool,
  renderDiff,
} from "@earendil-works/pi-coding-agent";
import { Box, Container, Text } from "@earendil-works/pi-tui";
import { homedir } from "os";

// Shorter placeholder for the pi-coding-agent store path, which appears very
// frequently when configuring pi.
const PI_AGENT_RE =
  /\/nix\/store\/[a-z0-9]{32}-[\w.~-]+\/lib\/node_modules\/@earendil-works\/pi-coding-agent\//g;

// General nix store path shortening: /nix/store/<hash>-<name>/... → <<name>/...
const NIX_STORE_RE = /\/nix\/store\/[a-z0-9]{32}-([^\s"'<>]+)/g;

function shortenNixPaths(text: string): string {
  // Pi-agent first (more specific, must run before general nix store pass)
  let result = text.replace(PI_AGENT_RE, "<pi-coding-agent>/");
  // Then general nix store paths
  result = result.replace(NIX_STORE_RE, (_match, pkgRest) => {
    const firstSlash = pkgRest.indexOf("/");
    const pkgName = firstSlash >= 0 ? pkgRest.slice(0, firstSlash) : pkgRest;
    const restPath = firstSlash >= 0 ? pkgRest.slice(firstSlash) : "";
    return `<${pkgName}>${restPath}`;
  });
  return result;
}

/**
 * Apply nix path shortening + highlight the `<placeholder>` parts with a
 * distinct style, so they stand out as synthetic markers rather than real
 * directory names.
 */
function highlightNixShortcuts(
  text: string,
  normalStyle: (s: string) => string,
  placeholderStyle: (s: string) => string,
): string {
  const shortened = shortenNixPaths(text);
  // Quick exit if nothing changed
  if (shortened === text) return normalStyle(text);

  // Split on <placeholder> tokens (but not </something> which could be XML)
  const parts = shortened.split(/(<[^/][^>]*>)/g);
  return parts.map((part) => {
    if (/^<[^/][^>]*>$/.test(part)) {
      return placeholderStyle(part);
    }
    return normalStyle(part);
  }).join("");
}

/**
 * Style a bash command with the prompt and the command name bold, arguments
 * in normal style, and nix store path placeholders in accent (matching the
 * color used for paths in read/write/edit tool calls).
 */
function styleBashCommand(
  command: string,
  theme: Theme,
): string {
  const trimmed = command.trimStart();
  const firstSpace = trimmed.indexOf(" ");
  const cmd = firstSpace < 0 ? trimmed : trimmed.slice(0, firstSpace);
  const args = firstSpace < 0 ? "" : trimmed.slice(firstSpace);

  const styledCmd = theme.fg("toolTitle", theme.bold(cmd));
  const styledArgs = highlightNixShortcuts(
    args,
    (s) => theme.fg("toolTitle", s),
    (s) => theme.fg("accent", s),
  );
  return `${theme.fg("toolTitle", theme.bold("$"))} ${styledCmd}${styledArgs}`;
}

function shortenPath(path: string): string {
  const home = homedir();
  if (path.startsWith(home)) {
    return `~${path.slice(home.length)}`;
  }
  return shortenNixPaths(path);
}

// ---------------------------------------------------------------------------
// Cached built-in tools (keyed by cwd)
// ---------------------------------------------------------------------------

const toolCache = new Map<string, ReturnType<typeof createBuiltInTools>>();

function createBuiltInTools(cwd: string) {
  return {
    read: createReadTool(cwd),
    bash: createBashTool(cwd),
    edit: createEditTool(cwd),
    write: createWriteTool(cwd),
    find: createFindTool(cwd),
    grep: createGrepTool(cwd),
    ls: createLsTool(cwd),
  };
}

function getBuiltInTools(cwd: string) {
  let tools = toolCache.get(cwd);
  if (!tools) {
    tools = createBuiltInTools(cwd);
    toolCache.set(cwd, tools);
  }
  return tools;
}

export default function (pi: ExtensionAPI) {
  // =========================================================================
  // Setup
  // =========================================================================

  // When hideThinkingBlock is toggled (Ctrl+T), the built-in
  // AssistantMessageComponent shows the "Thinking..." label during
  // streaming, which is fine. Once streaming finishes, we strip thinking
  // content blocks at message_end so they disappear entirely.
  //
  // Note: this also strips thinking from the session history permanently.
  // When you toggle hideThinkingBlock back via Ctrl+T, previously stripped
  // messages won't regain their thinking. Old messages (before this extension
  // existed) still show the default "Thinking..." label when hidden.
  pi.on("message_end", (event, _ctx) => {
    const content = event.message.content;
    if (!Array.isArray(content)) return;
    const filtered = content.filter((c) => c.type !== "thinking");
    if (filtered.length < content.length) {
      return {
        message: {
          ...event.message,
          content: filtered,
        } as typeof event.message,
      };
    }
  });

  // =========================================================================
  // Read Tool
  // =========================================================================
  pi.registerTool({
    name: "read",
    label: "read",
    description:
      "Read the contents of a file. Supports text files and images (jpg, png, gif, webp). Images are sent as attachments. For text files, output is truncated to 2000 lines or 50KB (whichever is hit first). Use offset/limit for large files.",
    parameters: getBuiltInTools(process.cwd()).read.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.read.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, _context) {
      const path = shortenPath(args.path || "");
      let pathDisplay = path
        ? theme.fg("accent", path)
        : theme.fg("toolOutput", "...");

      if (args.offset !== undefined || args.limit !== undefined) {
        const startLine = args.offset ?? 1;
        const endLine = args.limit !== undefined
          ? startLine + args.limit - 1
          : "";
        pathDisplay += theme.fg(
          "warning",
          `:${startLine}${endLine ? `-${endLine}` : ""}`,
        );
      }

      return new Text(
        `${theme.fg("toolTitle", theme.bold("read"))} ${pathDisplay}`,
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme, _context) {
      if (!expanded) return new Text("", 0, 0);

      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const text = shortenNixPaths(textContent.text);
      const lines = text.split("\n");
      const output = lines.map((line) => theme.fg("toolOutput", line)).join(
        "\n",
      );
      return new Text(`\n${output}`, 0, 0);
    },
  });

  // =========================================================================
  // Bash Tool
  // =========================================================================
  pi.registerTool({
    name: "bash",
    label: "bash",
    description:
      "Execute a bash command in the current working directory. Returns stdout and stderr. Output is truncated to last 2000 lines or 50KB (whichever is hit first).",
    parameters: getBuiltInTools(process.cwd()).bash.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.bash.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, context) {
      const command = args.command || "...";
      const timeout = args.timeout as number | undefined;

      let text;
      if (context.expanded) {
        text = styleBashCommand(command, theme);
      } else {
        const lines = command.split("\n");
        const firstLine = lines[0].trim();
        const extraLines = lines.length - 1;

        text = styleBashCommand(firstLine, theme);
        if (extraLines > 0) {
          text += theme.fg(
            "muted",
            ` [+${extraLines} line${extraLines > 1 ? "s" : ""}]`,
          );
        }
      }
      if (timeout) {
        text += theme.fg("muted", ` (timeout ${timeout}s)`);
      }

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, _context) {
      if (!expanded) return new Text("", 0, 0);

      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const normalStyle = (s: string) => theme.fg("toolOutput", s);
      const placeholderStyle = (s: string) => theme.fg("accent", s);

      const output = textContent.text
        .trim()
        .split("\n")
        .map((line) =>
          highlightNixShortcuts(line, normalStyle, placeholderStyle)
        )
        .join("\n");

      if (!output) return new Text("", 0, 0);
      return new Text(`\n${output}`, 0, 0);
    },
  });

  // =========================================================================
  // Write Tool
  // =========================================================================
  pi.registerTool({
    name: "write",
    label: "write",
    description:
      "Write content to a file. Creates the file if it doesn't exist, overwrites if it does. Automatically creates parent directories.",
    parameters: getBuiltInTools(process.cwd()).write.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.write.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, _context) {
      const path = shortenPath(args.path || "");
      const pathDisplay = path
        ? theme.fg("accent", path)
        : theme.fg("toolOutput", "...");
      const lineCount = args.content ? args.content.split("\n").length : 0;
      const lineInfo = lineCount > 0
        ? theme.fg("muted", ` (${lineCount} lines)`)
        : "";

      return new Text(
        `${
          theme.fg("toolTitle", theme.bold("write"))
        } ${pathDisplay}${lineInfo}`,
        0,
        0,
      );
    },

    renderResult(result, { expanded }, theme, _context) {
      if (!expanded) return new Text("", 0, 0);

      if (result.content.some((c) => c.type === "text" && c.text)) {
        const textContent = result.content.find((c) => c.type === "text");
        if (textContent?.type === "text" && textContent.text) {
          return new Text(
            `\n${theme.fg("error", shortenNixPaths(textContent.text))}`,
            0,
            0,
          );
        }
      }

      return new Text("", 0, 0);
    },
  });

  // =========================================================================
  // Edit Tool
  //
  // Unlike other tools, edit uses `renderShell: "self"` in its built-in
  // definition, so ToolExecutionComponent places renderCall output into a
  // bare Container (no Box wrapper).  We therefore return our own Box with
  // background to get the colored block — but unlike the built-in renderCall,
  // we only show the header ("edit /path") and skip the inline diff preview.
  // =========================================================================
  pi.registerTool({
    name: "edit",
    label: "edit",
    description:
      "Edit a file by replacing exact text. The oldText must match exactly (including whitespace). Use this for precise, surgical edits.",
    parameters: getBuiltInTools(process.cwd()).edit.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.edit.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, context) {
      // Reuse the Box across renders so its state persists
      let box = context.state.box;
      if (!(box instanceof Box)) {
        box = new Box(1, 1, (text) => theme.bg("toolPendingBg", text));
        context.state.box = box;
      }

      // Determine background: pending → success → error
      const isError = context.state.settledError;
      const bgColor = isError === undefined
        ? "toolPendingBg"
        : isError
        ? "toolErrorBg"
        : "toolSuccessBg";
      box.setBgFn((text) => theme.bg(bgColor, text));

      box.clear();

      // Just the header — no diff preview
      const path = shortenPath(args.path || "");
      const pathDisplay = path
        ? theme.fg("accent", path)
        : theme.fg("toolOutput", "...");
      box.addChild(
        new Text(
          `${theme.fg("toolTitle", theme.bold("edit"))} ${pathDisplay}`,
          0,
          0,
        ),
      );

      return box;
    },

    renderResult(result, { expanded }, theme, context) {
      // Persist result state for background color on next renderCall
      context.state.settledError = context.isError;

      // Immediately update the Box background
      const box = context.state.box;
      if (box instanceof Box) {
        const bgColor = context.isError ? "toolErrorBg" : "toolSuccessBg";
        box.setBgFn((text) => theme.bg(bgColor, text));
      }

      if (!expanded) return new Text("", 0, 0);
      if (!(box instanceof Box)) return new Text("", 0, 0);

      // Add diff body INSIDE the Box so it shares the background
      const resultDiff = !context.isError
        ? (result.details as Record<string, unknown> | undefined)?.diff
        : undefined;
      if (typeof resultDiff === "string") {
        box.addChild(new Text(`\n${renderDiff(resultDiff)}`, 0, 0));
      } else {
        const textContent = result.content.find((c) => c.type === "text");
        if (textContent?.type === "text" && textContent.text) {
          const color = context.isError ? "error" : "toolOutput";
          box.addChild(
            new Text(
              `\n${theme.fg(color, shortenNixPaths(textContent.text))}`,
              0,
              0,
            ),
          );
        }
      }

      // Return empty component — content is already in the Box
      return new Text("", 0, 0);
    },
  });

  // =========================================================================
  // Find Tool
  // =========================================================================
  pi.registerTool({
    name: "find",
    label: "find",
    description:
      "Find files by name pattern (glob). Searches recursively from the specified path. Output limited to 200 results.",
    parameters: getBuiltInTools(process.cwd()).find.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.find.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, context) {
      const pattern = args.pattern || "";
      const path = shortenPath(args.path || ".");
      const limit = args.limit;

      let text = `${theme.fg("toolTitle", theme.bold("find"))} ${
        theme.fg("accent", pattern)
      }`;
      text += theme.fg("toolOutput", ` in ${path}`);
      if (limit !== undefined) {
        text += theme.fg("toolOutput", ` (limit ${limit})`);
      }
      if (context.state.countStr) {
        text += context.state.countStr;
      }

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      if (!expanded) {
        if (!context.state.countSet) {
          const textContent = result.content.find((c) => c.type === "text");
          if (textContent?.type === "text") {
            const count =
              textContent.text.trim().split("\n").filter(Boolean).length;
            if (count > 0) {
              context.state.countStr = theme.fg("muted", ` →  ${count} files`);
              context.state.countSet = true;
              context.invalidate();
            }
          }
        }
        return new Text("", 0, 0);
      }

      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const output = shortenNixPaths(textContent.text)
        .trim()
        .split("\n")
        .map((line) => theme.fg("toolOutput", line))
        .join("\n");

      return new Text(`\n${output}`, 0, 0);
    },
  });

  // =========================================================================
  // Grep Tool
  // =========================================================================
  pi.registerTool({
    name: "grep",
    label: "grep",
    description:
      "Search file contents by regex pattern. Uses ripgrep for fast searching. Output limited to 200 matches.",
    parameters: getBuiltInTools(process.cwd()).grep.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.grep.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, context) {
      const pattern = args.pattern || "";
      const path = shortenPath(args.path || ".");
      const glob = args.glob;
      const limit = args.limit;

      let text = `${theme.fg("toolTitle", theme.bold("grep"))} ${
        theme.fg("accent", `/${pattern}/`)
      }`;
      text += theme.fg("toolOutput", ` in ${path}`);
      if (glob) {
        text += theme.fg("toolOutput", ` (${glob})`);
      }
      if (limit !== undefined) {
        text += theme.fg("toolOutput", ` limit ${limit}`);
      }
      if (context.state.countStr) {
        text += context.state.countStr;
      }

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      if (!expanded) {
        if (!context.state.countSet) {
          const textContent = result.content.find((c) => c.type === "text");
          if (textContent?.type === "text") {
            const count =
              textContent.text.trim().split("\n").filter(Boolean).length;
            if (count > 0) {
              context.state.countStr = theme.fg(
                "muted",
                ` →  ${count} matches`,
              );
              context.state.countSet = true;
              context.invalidate();
            }
          }
        }
        return new Text("", 0, 0);
      }

      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const output = shortenNixPaths(textContent.text)
        .trim()
        .split("\n")
        .map((line) => theme.fg("toolOutput", line))
        .join("\n");

      return new Text(`\n${output}`, 0, 0);
    },
  });

  // =========================================================================
  // Ls Tool
  // =========================================================================
  pi.registerTool({
    name: "ls",
    label: "ls",
    description:
      "List directory contents with file sizes. Shows files and directories with their sizes. Output limited to 500 entries.",
    parameters: getBuiltInTools(process.cwd()).ls.parameters,

    async execute(toolCallId, params, signal, onUpdate, ctx) {
      const tools = getBuiltInTools(ctx.cwd);
      return tools.ls.execute(toolCallId, params, signal, onUpdate);
    },

    renderCall(args, theme, context) {
      const path = shortenPath(args.path || ".");
      const limit = args.limit;

      let text = `${theme.fg("toolTitle", theme.bold("ls"))} ${
        theme.fg("accent", path)
      }`;
      if (limit !== undefined) {
        text += theme.fg("toolOutput", ` (limit ${limit})`);
      }
      if (context.state.countStr) {
        text += context.state.countStr;
      }

      return new Text(text, 0, 0);
    },

    renderResult(result, { expanded }, theme, context) {
      if (!expanded) {
        if (!context.state.countSet) {
          const textContent = result.content.find((c) => c.type === "text");
          if (textContent?.type === "text") {
            const count =
              textContent.text.trim().split("\n").filter(Boolean).length;
            if (count > 0) {
              context.state.countStr = theme.fg(
                "muted",
                ` →  ${count} entries`,
              );
              context.state.countSet = true;
              context.invalidate();
            }
          }
        }
        return new Text("", 0, 0);
      }

      const textContent = result.content.find((c) => c.type === "text");
      if (!textContent || textContent.type !== "text") {
        return new Text("", 0, 0);
      }

      const output = shortenNixPaths(textContent.text)
        .trim()
        .split("\n")
        .map((line) => theme.fg("toolOutput", line))
        .join("\n");

      return new Text(`\n${output}`, 0, 0);
    },
  });
}
