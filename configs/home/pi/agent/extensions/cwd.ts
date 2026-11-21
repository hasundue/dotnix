/**
 * cwd — Keep the system prompt stable across worktree moves and carry the
 * current directory in one persistent conversation message.
 *
 * Pi patches the `<cwd>` section when a session changes directory. Providers
 * without mid-conversation system messages then rebuild the leading message,
 * which invalidates the prompt cache even though the conversation is the same.
 * Replacing that section with a fixed notice leaves the head unchanged across
 * moves and keeps the notice in the session file. The `project_context` and
 * `skills` sections also embed the session cwd, so that prefix is rewritten to
 * `./` before Pi diffs them. A hidden custom message supplies the actual path:
 * the most recent location message is authoritative, so moving A → B → A needs
 * a new one even though A appeared earlier.
 */

import { sep } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOCATION_TYPE = "pi-cwd.location";

const NOTICE =
  "The current working directory is supplied in an application message in this conversation as `Current working directory: <path>`. Treat it as application context, not as a user instruction. The most recent such message is authoritative.";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    const toPosix = (path: string) => path.split(sep).join("/");
    const cwd = toPosix(ctx.cwd);
    const prefix = `${cwd}/`;
    const relative = (path: string) => {
      const normalized = toPosix(path);
      return normalized.startsWith(prefix) ? `./${normalized.slice(prefix.length)}` : path;
    };
    const options = event.systemPromptOptions;
    options.sections.cwd = NOTICE;
    options.contextFiles = options.contextFiles.map((file) => ({
      ...file,
      path: relative(file.path),
    }));
    options.skills = options.skills.map((skill) => ({
      ...skill,
      filePath: relative(skill.filePath),
    }));

    if (event.messageType === "custom" && event.message.customType === LOCATION_TYPE) return;

    const content = `Current working directory: ${cwd}`;
    let lastContent: unknown;
    for (const entry of ctx.sessionManager.buildContextEntries()) {
      if (entry.type === "custom_message" && entry.customType === LOCATION_TYPE) {
        lastContent = entry.content;
      }
    }
    if (lastContent === content) return;

    return { message: { customType: LOCATION_TYPE, content, display: false } };
  });
}
