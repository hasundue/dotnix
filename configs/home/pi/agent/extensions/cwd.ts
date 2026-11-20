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
 * The payload rewrite assumes an OpenAI-compatible `messages` array; it is
 * intended for opencode-go, which accepts a trailing system message.
 */

import { getCurrentSystemMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  pi.on("before_provider_request", (event, ctx) => {
    const payload = event.payload as { messages?: Array<{ role: string; content: unknown }> };
    if (!Array.isArray(payload.messages)) return;
    const cwd = ctx.cwd.replace(/\\/g, "/");
    payload.messages.push({ role: "system", content: `<cwd>\n${cwd}\n</cwd>` });
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
