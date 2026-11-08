/**
 * Sleep inhibitor — Keeps the machine awake while a pi run is in flight.
 *
 * A run holds a logind `sleep` block inhibitor through `systemd-inhibit`, so
 * an idle timer (swayidle) cannot suspend the machine mid-turn. The lock is
 * released after the run settles, and the desktop idle timer is restarted so
 * its full countdown begins at the end of the run.
 *
 * Waiting at the prompt holds no lock: only `agent_start` acquires it, and
 * `agent_settled` is the final-idle signal (`agent_end` is not).
 *
 * Everything is best-effort. A host without systemd, `systemd-inhibit`, or
 * swayidle behaves exactly as before: no throw, no transcript noise.
 */

import { spawn, type ChildProcess } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

/** Retries, recovery, and queued work can start another run; avoid flapping. */
const RELEASE_DEBOUNCE_MS = 2_000;

export default function (pi: ExtensionAPI) {
  // ── State ────────────────────────────────────────────────────────────────

  let inhibitor: ChildProcess | null = null;
  let releaseTimer: ReturnType<typeof setTimeout> | null = null;

  // ── Inhibitor ────────────────────────────────────────────────────────────

  function acquire(): void {
    if (inhibitor !== null) return;

    try {
      // `cat` keeps stdin open only so the wrapped command exits when pi
      // does: after a SIGKILL the pipe reaches EOF, systemd-inhibit exits,
      // and logind drops the lock. Detached makes the child a process-group
      // leader so a normal release can kill the whole tree at once.
      const child = spawn(
        "systemd-inhibit",
        [
          "--what=sleep",
          "--mode=block",
          "--who=pi",
          "--why=pi is working",
          "--",
          "bash",
          "-c",
          "cat >/dev/null",
        ],
        { stdio: ["pipe", "ignore", "ignore"], detached: true },
      );

      child.on("error", () => {
        if (inhibitor === child) inhibitor = null;
      });
      child.on("exit", () => {
        if (inhibitor === child) inhibitor = null;
      });

      inhibitor = child;
    } catch {
      inhibitor = null;
    }
  }

  async function release(): Promise<void> {
    cancelPendingRelease();

    const child = inhibitor;
    inhibitor = null;
    if (child !== null) {
      killTree(child, "SIGTERM");
      await waitForExit(child);
    }

    await restartIdleTimer();
  }

  function killTree(child: ChildProcess, signal: NodeJS.Signals): void {
    const pid = child.pid;
    if (pid === undefined) return;

    try {
      // Negative pid targets the process group created by `detached`.
      process.kill(-pid, signal);
    } catch {
      try {
        child.kill(signal);
      } catch {
        // Already gone.
      }
    }
  }

  function waitForExit(child: ChildProcess): Promise<void> {
    if (child.exitCode !== null || child.signalCode !== null) {
      return Promise.resolve();
    }

    return new Promise((resolve) => {
      const timer = setTimeout(() => {
        killTree(child, "SIGKILL");
        resolve();
      }, 2_000);

      child.once("exit", () => {
        clearTimeout(timer);
        resolve();
      });
    });
  }

  // ── Desktop idle timer ───────────────────────────────────────────────────

  function cancelPendingRelease(): void {
    if (releaseTimer !== null) {
      clearTimeout(releaseTimer);
      releaseTimer = null;
    }
  }

  async function restartIdleTimer(): Promise<void> {
    try {
      const active = await pi.exec(
        "systemctl",
        ["--user", "is-active", "--quiet", "swayidle.service"],
        { timeout: 3_000 },
      );
      if (active.code !== 0) return;

      await pi.exec("systemctl", ["--user", "restart", "swayidle.service"], {
        timeout: 5_000,
      });
    } catch {
      // A missing or failing systemctl must not affect the turn.
    }
  }

  // ── Session lifecycle ────────────────────────────────────────────────────

  pi.on("agent_start", () => {
    cancelPendingRelease();
    acquire();
  });

  pi.on("agent_settled", () => {
    cancelPendingRelease();
    releaseTimer = setTimeout(() => {
      releaseTimer = null;
      void release();
    }, RELEASE_DEBOUNCE_MS);
  });

  pi.on("session_shutdown", async () => {
    await release();
  });
}
