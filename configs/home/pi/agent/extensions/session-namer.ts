/**
 * Session namer — Names a session from its first prompt.
 *
 * Pi only assigns a session name on `/name`, `--name`, or `pi.setSessionName()`,
 * so a session started by a client that sets none keeps an empty name. Waku
 * then falls back to the truncated first prompt for its sidebar, which is how a
 * task ends up labelled with a 54-character sentence for its whole life — and
 * with a full-width Japanese sentence when the prompt is Japanese.
 *
 * Naming here covers both surfaces: Pi exposes the name on the RPC stream
 * (`session_info_changed`) and in `get_state` (`sessionName`), which is exactly
 * where Waku's pi driver reads `auto_title` from, and Pi's own `/resume`
 * selector shows it instead of the first message. A rename in Waku always
 * beats it.
 *
 * One background model call per session, on the prompt alone: the call never
 * enters the transcript and never delays the turn. A name the user set always
 * wins — `/name` before the first prompt, or a rename while the call is in
 * flight, both suppress the write.
 */

import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/** Waku's sidebar truncates anyway; a name longer than this is not an answer. */
const MAX_LENGTH = 48;

/** Titles come from the start of a prompt; the rest only costs tokens. */
const MAX_PROMPT_CHARS = 4_000;

const REQUEST_TIMEOUT_MS = 20_000;

/**
 * Fixed, not configurable: the cheapest model that answered reliably at flash
 * latency, and the same price for every session. When it is unavailable the
 * feature stays off — riding the session model would make the cost depend on
 * whatever the session runs, which is the property this extension is avoiding.
 */
const MODEL: readonly [provider: string, modelId: string] = ["opencode-go", "glm-5.3-flash"];

const INSTRUCTIONS =
  "Name the coding task described by the prompt. Reply with the name only: " +
  "3-6 words, sentence case, always in English whatever the prompt's language, " +
  "no quotes, no markdown, no labels, no trailing punctuation. Name the " +
  "concrete work, not the request ('Fix CJK font weight', not 'Ask about " +
  "fonts').";

export default function (pi: ExtensionAPI) {
  // ── State ────────────────────────────────────────────────────────────────

  /** One attempt per session runtime, including a failed one. */
  let attempted = false;

  pi.on("session_start", () => {
    attempted = false;
  });

  // ── Trigger ──────────────────────────────────────────────────────────────

  pi.on("before_agent_start", (event, ctx) => {
    // `--mode print`/`json` runs have no session list to fill, and a resumed
    // session that already has a name keeps it.
    if (event.messageType !== "user") return;
    if (ctx.mode === "print" || ctx.mode === "json") return;
    if (attempted || pi.getSessionName()) return;

    const prompt = event.prompt.trim();
    if (prompt === "") return;

    attempted = true;
    // Deliberately not awaited: the name lands while the agent works.
    void name(prompt, ctx);
  });

  // ── Naming ───────────────────────────────────────────────────────────────

  async function name(prompt: string, ctx: ExtensionContext): Promise<void> {
    try {
      const [provider, modelId] = MODEL;
      const model = ctx.modelRegistry.find(provider, modelId);
      if (model === undefined || !ctx.modelRegistry.hasConfiguredAuth(model)) {
        return;
      }

      const response = await ctx.modelRegistry.complete(
        model,
        {
          messages: [
            {
              role: "user",
              content: `${INSTRUCTIONS}\n\nPrompt:\n${prompt.slice(0, MAX_PROMPT_CHARS)}`,
              timestamp: Date.now(),
            },
          ],
        },
        {
          cacheRetention: "none",
          sessionId: uuidv7(),
          signal: AbortSignal.timeout(REQUEST_TIMEOUT_MS),
          reasoningEffort: "none",
        },
      );

      const raw = response.content
        .filter((block) => block.type === "text")
        .map((block) => block.text)
        .join(" ");
      const title = normalize(raw);
      // The user may have run `/name` while the request was in flight.
      if (title !== null && !pi.getSessionName()) pi.setSessionName(title);
    } catch {
      // A missing name is cosmetic; never fail or delay the turn over it.
    }
  }

  /** Strip the wrappers a model adds even when told not to. */
  function normalize(raw: string): string | null {
    let title = raw
      .replace(/```[\s\S]*?```/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    title = title.replace(/^(?:title|name)\s*:\s*/i, "");
    title = title.replace(/^["'“”‘’`]+|["'“”‘’`]+$/g, "").trim();
    title = title.replace(/[.,;:!?。、]+$/u, "").trim();
    if (title === "") return null;
    if ([...title].length > MAX_LENGTH) {
      title = `${[...title].slice(0, MAX_LENGTH - 1).join("")}…`;
    }
    return title;
  }
}
