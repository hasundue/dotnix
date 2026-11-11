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

import { readFileSync } from "node:fs";

import { uuidv7 } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/** Waku's sidebar truncates anyway; a name longer than this is not an answer. */
const MAX_LENGTH = 48;

/** A request is a title, not a document; its head is what names the work. */
const MAX_REQUEST_CHARS = 1_500;

/** A skill description is a routing hint; only its first sentence is the work. */
const MAX_WORKFLOW_CHARS = 240;

const REQUEST_TIMEOUT_MS = 20_000;

/**
 * Fixed, not configurable: the cheapest model that answered reliably at flash
 * latency, and the same price for every session. When it is unavailable the
 * feature stays off — riding the session model would make the cost depend on
 * whatever the session runs, which is the property this extension is avoiding.
 */
const MODEL: readonly [provider: string, modelId: string] = ["opencode-go", "glm-5.3-flash"];

const INSTRUCTIONS =
  "Name the coding task the user asked for. Reply with the name only: " +
  "3-6 words, sentence case, always in English whatever the prompt's language, " +
  "no quotes, no markdown, no labels, no trailing punctuation. Name the " +
  "concrete work, not the request ('Fix CJK font weight', not 'Ask about " +
  "fonts'). A workflow, when given, is the procedure the session follows, not " +
  "its subject: take the verb from it and the subject from the request.";

/**
 * `/skill:name args` reaches `before_agent_start` already expanded — the whole
 * SKILL.md body inside a `<skill>` block, the user's arguments after it, and no
 * other marker of the invocation. The body is a manual, so a window over the
 * prompt names the procedure instead of the task: `sail` alone is 7.9 KB, and
 * the 4 KB that fit left `foobar.md` — the only word about this session —
 * outside. The block is therefore split rather than truncated: `location` is
 * read for the skill's description, the text after `</skill>` is the request,
 * and the body is dropped.
 */
const SKILL_BLOCK =
  /^<skill name="[^"]+" location="([^"]*)">\r?\n[\s\S]*?\r?\n<\/skill>(?:\r?\n\r?\n?([\s\S]*))?$/;

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

    const { request, workflow } = split(event.prompt);
    if (request === "" && workflow === null) return;

    attempted = true;
    // Deliberately not awaited: the name lands while the agent works.
    void name(request, workflow, ctx);
  });

  // ── Prompt ───────────────────────────────────────────────────────────────

  /**
   * Reduce a prompt to what names the session: the request in the user's own
   * words, and a skill's workflow when the session was started by one.
   */
  function split(prompt: string): { request: string; workflow: string | null } {
    const block = prompt.trim().match(SKILL_BLOCK);
    if (block === null) {
      return { request: clamp(collapse(prompt), MAX_REQUEST_CHARS), workflow: null };
    }
    return {
      request: clamp(collapse(block[2] ?? ""), MAX_REQUEST_CHARS),
      workflow: describe(block[1] ?? ""),
    };
  }

  /**
   * The skill's own description, which states what the skill does and when it
   * applies — everything the codename (`sail`, `keel`, `ketch`) does not say,
   * and nothing that would become a session name on its own.
   *
   * Read from the file rather than the system prompt: `<available_skills>`
   * omits skills with `disable-model-invocation`, which still expand here.
   */
  function describe(location: string): string | null {
    let raw: string;
    try {
      raw = readFileSync(location, "utf-8");
    } catch {
      return null;
    }

    const frontmatter = raw.match(/^---\r?\n([\s\S]*?)\r?\n---(?:\r?\n|$)/)?.[1];
    if (frontmatter === undefined) return null;

    const lines = frontmatter.split(/\r?\n/);
    const start = lines.findIndex((line) => /^description\s*:/.test(line));
    if (start === -1) return null;

    // A description is a YAML scalar: folded (`>`), literal (`|`), plain, or
    // quoted, continuing over an indented block and ending at the next key.
    const value = [lines[start]!.replace(/^description\s*:/, "")];
    for (const line of lines.slice(start + 1)) {
      if (/^\S/.test(line)) break;
      value.push(line);
    }
    const text = value
      .join(" ")
      .replace(/\s+/g, " ")
      .trim()
      .replace(/^[>|][-+]?\s*/, "")
      .replace(/^["']|["']$/g, "");
    if (text === "") return null;

    const sentence = text.match(/^.*?[.。](?=\s|$)/)?.[0] ?? text;
    return clamp(sentence, MAX_WORKFLOW_CHARS);
  }

  // ── Naming ───────────────────────────────────────────────────────────────

  async function name(
    request: string,
    workflow: string | null,
    ctx: ExtensionContext,
  ): Promise<void> {
    try {
      const [provider, modelId] = MODEL;
      const model = ctx.modelRegistry.find(provider, modelId);
      if (model === undefined || !ctx.modelRegistry.hasConfiguredAuth(model)) {
        return;
      }

      const parts = [
        INSTRUCTIONS,
        ...(workflow === null ? [] : [`Workflow this session follows: ${workflow}`]),
        `Request the user made: ${request === "" ? "(none -- invoked bare)" : request}`,
      ];

      const response = await ctx.modelRegistry.complete(
        model,
        {
          messages: [
            {
              role: "user",
              content: parts.join("\n\n"),
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
    return clamp(title, MAX_LENGTH);
  }

  function collapse(text: string): string {
    return text.replace(/\s+/g, " ").trim();
  }

  /** Cut to `max` characters, counting code points, and say that it was cut. */
  function clamp(text: string, max: number): string {
    const characters = [...text];
    if (characters.length <= max) return text;
    return `${characters.slice(0, max - 1).join("")}…`;
  }
}
