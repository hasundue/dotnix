/**
 * Session namer — Names a session from its first prompt.
 *
 * Pi only assigns a session name on `/name`, `--name`, or `pi.setSessionName()`,
 * so a session started by a client that sets none keeps an empty name, and
 * whatever lists sessions falls back to the first user message — which is how a
 * task ends up labelled with a 54-character sentence for its whole life, and
 * with a full-width Japanese sentence when the prompt is Japanese.
 *
 * The name is written where every reader takes it from: Pi's `get_state`
 * (`sessionName`) and the `session_info` entry in the session file that a
 * session list and /resume title a session from. A rename made later beats it.
 *
 * One background model call per session, on the prompt alone: the call never
 * enters the transcript and never delays the turn. A name the user set always
 * wins — `/name` before the first prompt, or a rename while the call is in
 * flight, both suppress the write.
 *
 * Inside Herdr, the same call also returns a short window label. It is
 * reported as display-only pane metadata and never changes session identity.
 */

import { readFileSync } from "node:fs";

import { uuidv7, type AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

/**
 * A session name is a label in a list, shown truncated rather than wrapped;
 * one longer than this is not an answer.
 */
const MAX_LENGTH = 48;

/** A request is a title, not a document; its head is what names the work. */
const MAX_REQUEST_CHARS = 1_500;

/** A skill description is a routing hint; only its first sentence is the work. */
const MAX_WORKFLOW_CHARS = 240;

const REQUEST_TIMEOUT_MS = 20_000;

/** Display-only metadata source for the short label on a Herdr pane border. */
const SHORT_TITLE_SOURCE = "herdr:pi-short-title";

/**
 * Fixed, not configurable: the cheapest model that answered reliably at flash
 * latency, and the same price for every session. When it is unavailable the
 * feature stays off — riding the session model would make the cost depend on
 * whatever the session runs, which is the property this extension is avoiding.
 */
const MODEL: readonly [provider: string, modelId: string] = ["opencode-go", "glm-5.3-flash"];

const INSTRUCTIONS =
  "Name the coding task the user asked for. Reply with exactly two lines and " +
  "nothing else. Line 1: the session name — 3-6 words, sentence case, always " +
  "in English whatever the prompt's language, no quotes, no markdown, no " +
  "labels, no trailing punctuation. Name the concrete work, not the request " +
  "('Fix CJK font weight', not 'Ask about fonts'). A workflow, when given, is " +
  "the procedure the session follows, not its subject: take the verb from it " +
  "and the subject from the request. Line 2: a short English window label — " +
  "one word by default, optionally with a second word when the first alone " +
  "would be ambiguous, lowercase, no punctuation.";

/** Used when a response lacks either line: name only, as before. */
const RETRY_INSTRUCTIONS =
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
        ...(workflow === null ? [] : [`Workflow this session follows: ${workflow}`]),
        `Request the user made: ${request === "" ? "(none -- invoked bare)" : request}`,
      ];
      const ask = (instructions: string) =>
        ctx.modelRegistry.complete(
          model,
          {
            messages: [
              {
                role: "user",
                content: [instructions, ...parts].join("\n\n"),
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

      const names = parseNames(textOf(await ask(INSTRUCTIONS)));
      if (names === null) {
        // One response missing either line falls back to the long-name-only
        // prompt, once, with no border label.
        const title = normalizeName(textOf(await ask(RETRY_INSTRUCTIONS)));
        if (title !== null && !pi.getSessionName()) pi.setSessionName(title);
        return;
      }

      // The user may have run `/name` while the request was in flight.
      if (!pi.getSessionName()) pi.setSessionName(names.title);
      if (process.env.HERDR_ENV !== "1") return;

      const label = chooseLabel(names.label, await herdrPanes());
      await reportLabel(label);
    } catch {
      // A missing name or label is cosmetic; never fail or delay the turn.
    }
  }

  function textOf(response: AssistantMessage): string {
    return response.content
      .filter((block) => block.type === "text")
      .map((block) => block.text)
      .join(" ");
  }

  /** Two lines from the model: the session name and its short border label. */
  function parseNames(raw: string): { title: string; label: string } | null {
    const lines = raw
      .replace(/```[\s\S]*?```/g, " ")
      .split(/\r?\n/)
      .map((line) => line.trim())
      .filter((line) => line !== "");
    if (lines.length < 2) return null;
    const title = normalizeName(lines[0]!);
    const label = normalizeLabel(lines[1]!);
    return title === null || label === null ? null : { title, label };
  }

  /** Strip the wrappers a model adds even when told not to. */
  function normalizeName(raw: string): string | null {
    let title = raw
      .replace(/```[\s\S]*?```/g, " ")
      .replace(/\s+/g, " ")
      .trim();
    title = title.replace(/^(?:session name|title|name)\s*:\s*/i, "");
    title = title.replace(/^["'“”‘’`]+|["'“”‘’`]+$/g, "").trim();
    title = title.replace(/[.,;:!?。、]+$/u, "").trim();
    if (title === "") return null;
    return clamp(title, MAX_LENGTH);
  }

  /** A border label is one or two plain English words. */
  function normalizeLabel(raw: string): string | null {
    const label = raw
      .replace(/^(?:label|short label|border label|title)\s*:\s*/i, "")
      .replace(/^"['“”‘’`]+|["'“”‘’`]+$/g, "")
      .replace(/[.,;:!?。、]+$/u, "")
      .replace(/\s+/g, " ")
      .trim()
      .toLowerCase();
    const words = label.split(" ");
    if (!words.every((word) => /^[a-z][a-z-]*$/.test(word))) return null;
    if (words.length > 2) return null;
    return words.join(" ");
  }

  type Pane = {
    pane_id?: string;
    title?: string;
    terminal_title?: string;
    terminal_title_stripped?: string;
  };

  async function herdrPanes(): Promise<Pane[]> {
    try {
      const result = await pi.exec("herdr", ["pane", "list"], { timeout: 5000 });
      if (result.code !== 0) return [];
      const panes = JSON.parse(result.stdout)?.result?.panes;
      return Array.isArray(panes) ? (panes as Pane[]) : [];
    } catch {
      return [];
    }
  }

  /** Use one word unless another window in this Herdr session carries it. */
  function chooseLabel(label: string, panes: readonly Pane[]): string {
    const [first, second] = label.split(" ");
    if (second === undefined || first === undefined) return label;
    const texts = panes
      .filter((pane) => pane.pane_id !== process.env.HERDR_PANE_ID)
      .flatMap((pane) => [pane.title, pane.terminal_title, pane.terminal_title_stripped])
      .filter((text): text is string => typeof text === "string");
    const used = new Set(texts.flatMap((text) => text.toLowerCase().split(/[^a-z0-9]+/)));
    return used.has(first) ? label : first;
  }

  async function reportLabel(label: string): Promise<void> {
    const paneId = process.env.HERDR_PANE_ID;
    if (process.env.HERDR_ENV !== "1" || !paneId) return;
    await pi.exec(
      "herdr",
      [
        "pane",
        "report-metadata",
        paneId,
        "--source",
        SHORT_TITLE_SOURCE,
        "--agent",
        "pi",
        "--title",
        label,
      ],
      { timeout: 5000 },
    );
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
