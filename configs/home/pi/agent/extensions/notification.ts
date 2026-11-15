/**
 * Completion notification — Announces a finished run in the terminal.
 *
 * A long run takes the user away from the terminal, so the end of it needs to
 * reach them where they already look: the desktop. The terminal is asked to
 * raise the notification with the OSC 777 `notify` sequence, which Ghostty
 * turns into a desktop notification and Mako then shows.
 *
 * The boundary is `agent_settled`, not `agent_end`: a retry, a compaction
 * retry, or a queued follow-up starts another run, and notifying before the
 * last of them has finished would be a false alarm.
 *
 * Ghostty will not gate the notification on focus. Its macOS build drops one
 * sent from a focused surface, but its GTK build shows it and withdraws it three
 * seconds later (`src/apprt/gtk/desktop_notifications.zig`, added by PR #14108),
 * and neither build has a setting for it (the `unfocused-only` request is
 * discussion #10691, unimplemented). A three-second flash while the user is
 * already looking at the terminal is the thing this file avoids, so the focus
 * question is asked of the compositor instead and the OSC is skipped while this
 * Pi's own window is focused.
 *
 * Nothing here launches `notify-send` or reaches across to Windows: a terminal
 * with no notification support (or no compositor to ask) simply gets the
 * notification it always got, and the turn is unaffected.
 */

import { readFileSync } from "node:fs";
import { basename } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** OSC introducer and the string terminator the sequence ends with. */
const OSC = "\x1b]";
const BEL = "\x07";

/** A probe that cannot answer within this is a probe that failed. */
const FOCUS_PROBE_TIMEOUT_MS = 1_000;

/** The parent chain is short; this only stops a cycle from looping forever. */
const MAX_ANCESTOR_DEPTH = 16;

/**
 * OSC 777 carries `notify;title;body`, so a `;` inside the title would split
 * the field, and a control character could end the sequence early.
 */
function sanitize(text: string): string {
  return text.replace(/[\u0000-\u001f\u007f]/g, " ").replaceAll(";", ",");
}

// ── Focus ──────────────────────────────────────────────────────────────────

/**
 * Pids from this process up to init. The terminal that owns our tty is one of
 * them, whatever it calls itself, and it is also the pid Niri reports for its
 * window — one terminal process may own several windows, which is why the pid
 * alone is not enough to name ours.
 */
function ancestors(): Set<number> {
  const pids = new Set<number>();
  let pid = process.pid;

  for (let depth = 0; depth < MAX_ANCESTOR_DEPTH && pid > 1; depth++) {
    pids.add(pid);
    try {
      // The comm field is parenthesised and may contain spaces, so the ppid is
      // the second field after the closing parenthesis.
      const stat = readFileSync(`/proc/${pid}/stat`, "utf8");
      const fields = stat.slice(stat.lastIndexOf(")") + 2).split(" ");
      pid = Number(fields[1]);
    } catch {
      break;
    }
  }

  return pids;
}

/**
 * Whether the focused window is this Pi's, according to the compositor.
 *
 * Pi titles a window `${APP_TITLE} - ${sessionName} - ${cwdBasename}`
 * (`dist/modes/interactive/interactive-mode.js`), so the title is what
 * separates our surface from the other windows of the same terminal process.
 * An unnamed session drops the middle segment, and a title that does not match
 * — because Pi's format changed, or because the window is someone else's —
 * means "assume unfocused", never "stay silent".
 *
 * Fails open in every direction: no `niri` binary (WSL), a nonzero exit,
 * unparsable output, an unusable pid. A missed completion notice is worse than
 * the flash.
 */
async function isFocused(pi: ExtensionAPI, name: string): Promise<boolean> {
  // Niri sets this for every process it spawns, so its absence means there is
  // no compositor to ask — WSL, a plain SSH session, a tty. Checking it first
  // costs a property read instead of a failed spawn (~8 ms) and keeps the
  // timeout out of reach on those hosts entirely.
  if (process.env.NIRI_SOCKET === undefined) return false;

  const directory = basename(process.cwd());
  const suffix = name === "" ? ` - ${directory}` : ` - ${name} - ${directory}`;

  try {
    const result = await pi.exec("niri", ["msg", "--json", "focused-window"], {
      timeout: FOCUS_PROBE_TIMEOUT_MS,
    });
    if (result.code !== 0) return false;

    const focused: unknown = JSON.parse(result.stdout);
    if (typeof focused !== "object" || focused === null) return false;

    const window = focused as { pid?: unknown; title?: unknown };
    if (typeof window.pid !== "number" || !ancestors().has(window.pid)) return false;
    return typeof window.title === "string" && window.title.endsWith(suffix);
  } catch {
    return false;
  }
}

// ── Extension ──────────────────────────────────────────────────────────────

export default function (pi: ExtensionAPI) {
  pi.on("agent_settled", async (_event, ctx) => {
    // Print, JSON, and RPC modes drive pi from another process: a raw control
    // sequence on stdout would corrupt that stream instead of notifying.
    if (ctx.mode !== "tui") return;
    // Read now rather than waiting: automatic naming runs alongside the agent,
    // and a completion notice that waits for a title is no longer prompt.
    const name = pi.getSessionName() ?? "";

    if (await isFocused(pi, name)) return;

    try {
      // No body: the title says which session finished, and a fixed line would
      // only repeat that Pi is done.
      process.stdout.write(
        `${OSC}777;notify;${sanitize(name === "" ? "Pi" : `Pi: ${name}`)};${BEL}`,
      );
    } catch {
      // A terminal that cannot take the sequence must not affect the turn.
    }
  });
}
