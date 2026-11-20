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
 * Inside tmux the compositor only sees the terminal, never Pi's pane, so tmux
 * is asked about the pane too. The notice is suppressed when Pi's window is
 * active in a client and its pane is visible; it is sent when the window is
 * hidden under another one, detached from every client, or covered by a zoomed
 * sibling pane. `window_active` alone would count a detached session, so
 * `window_active_clients` is checked as well. tmux swallows a bare OSC 777, so
 * under tmux the sequence goes to the client's tty instead of stdout. tmux
 * reports that tty even while the client views another window, which is the
 * case that needs the notice; `client_session` separates it from a client
 * attached to a different session.
 *
 * Nothing here launches `notify-send` or reaches across to Windows: a terminal
 * with no notification support (or no compositor to ask) simply gets the
 * notification it always got, and the turn is unaffected. Every probe fails
 * open: a missed completion notice is worse than the flash.
 */

import { readFileSync, writeFileSync } from "node:fs";
import { basename } from "node:path";

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** OSC introducer and the string terminator the sequence ends with. */
const OSC = "\x1b]";
const BEL = "\x07";

/** A probe that cannot answer within this is a probe that failed. */
const FOCUS_PROBE_TIMEOUT_MS = 1_000;

/**
 * Stops a cycle from looping forever. TODO: 16 is a guard, not a verified
 * bound for every supported launch chain; a deeper one fails open.
 */
const MAX_ANCESTOR_DEPTH = 16;

/**
 * OSC 777 carries `notify;title;body`, so a `;` inside the title would split
 * the field, and a control character could end the sequence early.
 */
function sanitize(text: string): string {
  return text.replace(/[\u0000-\u001f\u007f]/g, " ").replaceAll(";", ",");
}

// ── Probes ────────────────────────────────────────────────────────────────

/**
 * Pids from `from` up to init. The terminal that owns our tty is one of them,
 * whatever it calls itself. Under tmux the process tree splits: Pi descends
 * from the tmux server, while the compositor reports the terminal behind the
 * tmux client, so that chain is walked from the client's pid instead. A chain
 * longer than MAX_ANCESTOR_DEPTH is not followed.
 */
function ancestors(from = process.pid): Set<number> {
  const pids = new Set<number>();
  let pid = from;

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

type NiriWindow = { pid?: unknown; title?: unknown };

/**
 * The focused window according to Niri, or null when there is no compositor
 * to ask. Niri sets NIRI_SOCKET for every process it spawns, so its absence
 * means WSL, a plain SSH session, or a bare tty: a property read instead of a
 * failed spawn (~8 ms).
 */
async function focusedWindow(pi: ExtensionAPI): Promise<NiriWindow | null> {
  if (process.env.NIRI_SOCKET === undefined) return null;

  try {
    const result = await pi.exec("niri", ["msg", "--json", "focused-window"], {
      timeout: FOCUS_PROBE_TIMEOUT_MS,
    });
    if (result.code !== 0) return null;

    const window: unknown = JSON.parse(result.stdout);
    return typeof window === "object" && window !== null ? (window as NiriWindow) : null;
  } catch {
    return null;
  }
}

/**
 * Direct (non-tmux) case. Pi titles a window
 * `${APP_TITLE} - ${sessionName} - ${cwdBasename}`
 * (`dist/modes/interactive/interactive-mode.js`), so the title is what
 * separates our surface from the other windows of the same terminal process.
 * An unnamed session drops the middle segment. A title that does not match —
 * because Pi's format changed, or because the window is someone else's —
 * means "assume unfocused", never "stay silent". TODO: this assumes no other
 * window of the same process ends with the same session and directory.
 */
function isOwnWindow(window: NiriWindow | null, name: string): boolean {
  if (window === null || typeof window.pid !== "number") return false;
  if (!ancestors().has(window.pid) || typeof window.title !== "string") return false;

  const directory = basename(process.cwd());
  const suffix = name === "" ? ` - ${directory}` : ` - ${name} - ${directory}`;
  return window.title.endsWith(suffix);
}

type TmuxState = {
  /** Pi's window is active in a client and its pane is not hidden by zoom. */
  visible: boolean;
  /** Only set when the reported client belongs to Pi's session. */
  clientTty?: string;
  clientPid?: number;
};

const TMUX_FORMAT = [
  "#{session_name}",
  "#{client_session}",
  "#{window_active}",
  "#{window_active_clients}",
  "#{window_zoomed_flag}",
  "#{pane_zoomed_flag}",
  "#{client_tty}",
  "#{client_pid}",
].join("\t");

/**
 * Ask tmux about the pane Pi is running in. `TMUX_PANE` targets this pane,
 * which matters when several clients or sessions are attached: an active
 * window in a detached session has `window_active=1` but no viewing client.
 * `client_tty` is still reported while the client views another window of the
 * same session, so delivery must not depend on `window_active_clients`;
 * `client_session` is what rules out a client attached somewhere else. TODO:
 * with several clients attached to the session, the reported client is not
 * checked against the window Niri says is focused.
 */
async function tmuxState(pi: ExtensionAPI): Promise<TmuxState | null> {
  const pane = process.env.TMUX_PANE;
  if (pane === undefined) return null;

  try {
    const result = await pi.exec("tmux", ["display-message", "-p", "-t", pane, TMUX_FORMAT], {
      timeout: FOCUS_PROBE_TIMEOUT_MS,
    });
    if (result.code !== 0) return null;

    const [session, clientSession, active, clients, windowZoomed, paneZoomed, tty, clientPid] =
      result.stdout.trim().split("\t");
    const ownClient = clientSession === session;
    const visible =
      active === "1" && Number(clients) > 0 && (windowZoomed !== "1" || paneZoomed === "1");

    return {
      visible,
      clientTty: ownClient && tty?.startsWith("/dev/") ? tty : undefined,
      clientPid: ownClient && /^\d+$/.test(clientPid ?? "") ? Number(clientPid) : undefined,
    };
  } catch {
    return null;
  }
}

/**
 * Under tmux, the compositor only names the terminal. It is ours when it
 * hosts the tmux client attached to Pi's window; the tmux probe already
 * established that such a client exists. TODO: one terminal process can own
 * several windows, and Niri reports only the owning pid. With no title check
 * here, a focused sibling window can still suppress a notice.
 */
function isOwnClientFocused(window: NiriWindow | null, tmux: TmuxState): boolean {
  return (
    window !== null &&
    typeof window.pid === "number" &&
    tmux.clientPid !== undefined &&
    ancestors(tmux.clientPid).has(window.pid)
  );
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

    const tmux = await tmuxState(pi);
    const window = await focusedWindow(pi);
    const focused =
      tmux === null ? isOwnWindow(window, name) : tmux.visible && isOwnClientFocused(window, tmux);
    if (focused) return;

    try {
      // No body: the title says which session finished, and a fixed line would
      // only repeat that Pi is done. tmux discards a bare OSC, so send it to
      // the client's tty when tmux is in play.
      const osc = `${OSC}777;notify;${sanitize(name === "" ? "Pi" : `Pi: ${name}`)};${BEL}`;
      if (tmux?.clientTty === undefined) process.stdout.write(osc);
      else writeFileSync(tmux.clientTty, osc);
    } catch {
      // A terminal that cannot take the sequence must not affect the turn.
    }
  });
}
