/**
 * cwd — Keep the working directory out of the static prompt and send it as a
 * trailing system message instead.
 *
 * Pi puts cwd into the system prompt as a `<cwd>` section and patches it after
 * a session move. Providers without mid-conversation system messages then get
 * a rebuilt leading system message, which invalidates the prompt cache even
 * though the conversation is unchanged. Removing the section from the head and
 * appending the same rendered text at the end keeps the cached prefix intact.
 *
 * The payload rewrite assumes an OpenAI-compatible `messages` array. If that
 * shape is missing, the extension skips that request and notifies once;
 * two consecutive 4xx provider responses stop appending for the session.
 * Response counting needs no request correlation because it does not depend
 * on which request carried the injection.
 */

import { getCurrentSystemMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const MARKER = "pi-cwd";

type Payload = { messages?: Array<{ role: string; content: unknown }> };

export default function (pi: ExtensionAPI) {
  let shapeWarned = false;
  let failureWarned = false;
  let consecutiveClientErrors = 0;

  const stop = (ctx: ExtensionContext, message: string) => {
    ctx.ui.notify(`${MARKER}: ${message}`, "warning");
  };

  pi.on("before_provider_request", (event, ctx) => {
    if (failureWarned) return;
    const payload = event.payload as Payload | null | undefined;
    if (!payload || typeof payload !== "object" || !Array.isArray(payload.messages)) {
      if (!shapeWarned) {
        shapeWarned = true;
        stop(ctx, "unsupported provider payload; cwd not appended");
      }
      return;
    }
    const cwd = ctx.cwd.replace(/\\/g, "/");
    payload.messages.push({ role: "system", content: `<cwd>\n${cwd}\n</cwd>` });
  });

  pi.on("after_provider_response", (event, ctx) => {
    if (failureWarned) return;
    if (event.status >= 400 && event.status < 500) {
      consecutiveClientErrors += 1;
      if (consecutiveClientErrors === 2 && !failureWarned) {
        failureWarned = true;
        stop(ctx, "two consecutive 4xx responses; cwd injection stopped");
      }
    } else {
      consecutiveClientErrors = 0;
    }
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
