/**
 * cwd — Keep the working directory out of the static prompt and give it to the
 * model as an incremental message instead.
 *
 * Pi puts cwd into the system prompt as a `<cwd>` section and patches it after
 * a session move. Providers without mid-conversation system messages then get
 * a rebuilt leading system message, which invalidates the prompt cache even
 * though the conversation is unchanged. Removing that section immediately
 * before the request keeps the prompt identical across worktrees.
 *
 * Some models rely on cwd being stated explicitly. One hidden custom message
 * carries the current directory into the conversation, appended when the
 * session first runs in that directory. Because it is added at the end of the
 * request, the cached prefix is preserved. The message is stored in the
 * session, so it survives both the fork used by pi-worktrunk and the session
 * replacement used by Teleport.
 */

import { getCurrentSystemMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const LOCATION_TYPE = "pi-cwd.location";

function locationContent(cwd: string): string {
  return `Current working directory: ${cwd}\nUse absolute paths, or run pwd if you need to confirm it.`;
}

export default function (pi: ExtensionAPI) {
  pi.on("before_agent_start", (event, ctx) => {
    if (
      event.messageType === "custom" &&
      (event.message as { customType?: string })?.customType === LOCATION_TYPE
    ) {
      return;
    }

    const content = locationContent(ctx.cwd);
    const alreadyPresent = ctx.sessionManager
      .getEntries()
      .some(
        (entry) =>
          entry.type === "custom_message" &&
          entry.customType === LOCATION_TYPE &&
          String(entry.content) === content,
      );
    if (alreadyPresent) return;

    return {
      message: { customType: LOCATION_TYPE, content, display: false },
    };
  });

  pi.on("context_with_system", (event) => {
    const head = getCurrentSystemMessage(event.messages as never);
    if (!head?.sections?.cwd) return;

    const sections = { ...(head.sections ?? {}) } as Record<string, string | null>;
    delete sections.cwd;
    const rest = event.messages.filter((message) => message.role !== "system");
    return { messages: [{ ...head, sections }, ...rest] };
  });
}
