/**
 * Temperature — Configures model temperature for provider requests.
 *
 * Provides a CLI flag (`--temperature <n>`) at startup, a `/temperature`
 * command for mid-session changes, and injects the configured temperature
 * into every provider request via `before_provider_request`.
 *
 * Default: 0.0 (deterministic — ideal for coding agents).
 * Range: 0.0 to 2.0.
 *
 * Usage:
 *   pi --temperature 0.5           # Start with temperature 0.5
 *   /temperature 0.7               # Change to 0.7 mid-session
 *   /temperature                   # Show current temperature
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
  // ── State ────────────────────────────────────────────────────────────────

  let temperature = 0.0;

  // ── CLI flag ─────────────────────────────────────────────────────────────

  pi.registerFlag("temperature", {
    description: "Set model temperature (0-2). Default: 0.0",
    type: "string",
  });

  // ── Commands ─────────────────────────────────────────────────────────────

  pi.registerCommand("temperature", {
    description:
      "Show or set model temperature (0-2). Usage: /temperature [<n>]",
    handler: async (args: string, ctx) => {
      const trimmed = args.trim();

      if (trimmed === "") {
        ctx.ui.notify(`Temperature: ${temperature}`, "info");
        return;
      }

      const val = parseFloat(trimmed);
      if (isNaN(val) || val < 0 || val > 2) {
        ctx.ui.notify("Temperature must be a number between 0 and 2", "error");
        return;
      }

      temperature = val;
      updateStatus(ctx);
      ctx.ui.notify(`Temperature set to ${temperature}`, "info");
    },
  });

  /** Update footer status to reflect current temperature. */
  function updateStatus(ctx: {
    ui: { setStatus: (key: string, text: string | undefined) => void };
  }): void {
    if (temperature === 0.0) {
      ctx.ui.setStatus("temperature", undefined);
    } else {
      ctx.ui.setStatus("temperature", `${temperature}`);
    }
  }

  // ── Session lifecycle ────────────────────────────────────────────────────

  pi.on("session_start", (_event, ctx) => {
    // Read CLI flag — pi caches flag values from the CLI invocation
    const flagVal = pi.getFlag("temperature");
    if (typeof flagVal === "string") {
      const parsed = parseFloat(flagVal);
      if (!isNaN(parsed) && parsed >= 0 && parsed <= 2) {
        temperature = parsed;
      }
    }
    updateStatus(ctx);
  });

  // ── Hook: stamp temperature onto every provider request ──────────────────

  pi.on("before_provider_request", (event) => {
    const payload = event.payload as Record<string, unknown>;
    return { ...payload, temperature };
  });
}
