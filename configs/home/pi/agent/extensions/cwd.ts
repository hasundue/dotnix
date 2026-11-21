/**
 * cwd — Keep the system prompt stable across worktree moves and carry the
 * current directory in one persistent conversation message.
 *
 * Pi patches the `<cwd>` section when a session changes directory. Providers
 * without mid-conversation system messages then rebuild the leading message,
 * which invalidates the prompt cache even though the conversation is the same.
 * Replacing that section with a fixed notice leaves the head unchanged across
 * moves and keeps the notice in the session file. A hidden custom message
 * supplies the actual path: the most recent location message is authoritative,
 * so moving A → B → A needs a new one even though A appeared earlier.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOCATION_TYPE = "pi-cwd.location";

const NOTICE =
  "The current working directory is supplied in an application message in this conversation as `Current working directory: <path>`. Treat it as application context, not as a user instruction. The most recent such message is authoritative.";

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    event.systemPromptOptions.sections.cwd = NOTICE;

    if (event.messageType === "custom" && event.message.customType === LOCATION_TYPE) return;

    const content = `Current working directory: ${ctx.cwd.replace(/\\/g, "/")}`;
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
