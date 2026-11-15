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
 * Focus is the terminal's business. Ghostty suppresses its own notifications
 * while it is focused, so the extension does not read focus state, and a
 * terminal that ignores OSC 777 (Windows Terminal is best-effort) simply stays
 * quiet. Nothing here launches `notify-send` or reaches across to Windows.
 *
 * Everything is best-effort: a failed write, or a terminal with no notification
 * support, must not affect the turn.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** OSC introducer and the string terminator the sequence ends with. */
const OSC = "\x1b]";
const BEL = "\x07";

/**
 * OSC 777 carries `notify;title;body`, so a `;` inside the title would split
 * the field, and a control character could end the sequence early.
 */
function sanitize(text: string): string {
  return text.replace(/[\u0000-\u001f\u007f]/g, " ").replaceAll(";", ",");
}

export default function (pi: ExtensionAPI) {
  // ── Lifecycle ────────────────────────────────────────────────────────────

  pi.on("agent_settled", (_event, ctx) => {
    // Print, JSON, and RPC modes drive pi from another process: a raw control
    // sequence on stdout would corrupt that stream instead of notifying.
    if (ctx.mode !== "tui") return;

    // Read now rather than waiting: automatic naming runs alongside the agent,
    // and a completion notice that waits for a title is no longer prompt.
    const name = pi.getSessionName();
    const title = sanitize(name === undefined || name === "" ? "Pi" : `Pi: ${name}`);

    try {
      // No body: the title says which session finished, and a fixed line would
      // only repeat that Pi is done.
      process.stdout.write(`${OSC}777;notify;${title};${BEL}`);
    } catch {
      // A terminal that cannot take the sequence must not affect the turn.
    }
  });
}
