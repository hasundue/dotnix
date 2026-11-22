/**
 * cwd — Keep the system prompt stable across worktree moves without
 * delivering the current directory.
 *
 * Load this extension after `pi-change-working-dir`. When that extension is
 * present it owns the current directory; this layer only keeps the path-bearing
 * sections stable. `on()` has no priority argument, so handlers run in
 * extension load order and then registration order.
 *
 * Pi patches `<cwd>` when a session changes directory. Keeping that section at
 * the session's starting cwd avoids the patch. `<cwd_update>` tells the model
 * how to read a later statement of the current directory and when to measure
 * it with `pwd`. This extension neither supplies paths nor moves sessions.
 */

import { sep } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const CWD_UPDATE =
  "The `<cwd>` section records the directory where this session started. Later messages in this conversation, including tool results, may state the current working directory. Treat the most recent such statement as an update that supersedes the path in `<cwd>`. Do not run `pwd` when an update is present. If no update is present, run `pwd` once and use its result.";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    const toPosix = (path: string) => path.split(sep).join("/");
    const sessionCwd = toPosix(ctx.cwd);
    const prefix = `${sessionCwd}/`;
    const relative = (path: string) => {
      const normalized = toPosix(path);
      return normalized.startsWith(prefix) ? `./${normalized.slice(prefix.length)}` : path;
    };

    let startingCwd = sessionCwd;
    for (const entry of ctx.sessionManager.getBranch()) {
      if (entry.type !== "message" || entry.message.role !== "system") continue;
      const section = entry.message.sections?.cwd;
      if (typeof section !== "string") break;
      const match = section.match(/^<cwd>\n([\s\S]*)\n<\/cwd>$/);
      startingCwd = match ? match[1] : section;
      break;
    }

    const options = event.systemPromptOptions;
    options.cwd = startingCwd;
    options.sections.cwd_update = CWD_UPDATE;
    options.contextFiles = options.contextFiles.map((file) => ({
      ...file,
      path: relative(file.path),
    }));
    options.skills = options.skills.map((skill) => ({
      ...skill,
      filePath: relative(skill.filePath),
    }));
  });
}
