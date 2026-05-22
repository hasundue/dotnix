/**
 * Custom Footer — superset of pi's built-in footer.
 *
 * Replaces the default footer via `ctx.ui.setFooter()` to show temperature
 * alongside the model on the right side of the stats line.
 *
 * Built-in reference (read before modifying):
 * `dist/modes/interactive/components/footer.js` in the pi-coding-agent
 * package (store path). The built-in footer shows:
 *   Line 1 — pwd (git branch, session name)
 *   Line 2 — token stats / context% (left) • model • thinking (right)
 *   Line 3 — extension statuses (sorted alphabetically)
 *
 * This superset replaces line 3 with temperature baked into line 2:
 *   Line 2 — token stats / context% (left) • model • thinking • 0.7 (right)
 *
 * Layout logic (truncation, padding, dim styling) mirrors the built-in.
 * Extension statuses from `footerData.getExtensionStatuses()` are consumed
 * here instead of rendering their own line — add new read-only status items
 * to the right side via `getExtensionStatuses().get("<key>")` rather than
 * creating a new line. Status items that should be hidden by default can use
 * `ctx.ui.setStatus("<key>", undefined)` to suppress them when inactive.
 *
 * Note: keep `invalidate()` and `dispose()` as no-ops — the built-in footer
 * handles git branch caching internally via `FooterDataProvider` and our
 * statuses trigger re-render through `ui.requestRender()` on mutation.
 */

import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

export default function agentStatus(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    let thinkingLevel = pi.getThinkingLevel();
    let modelId = ctx.model?.id;

    ctx.ui.setFooter((tui, theme, footerData) => {
      pi.on("thinking_level_select", (event) => {
        thinkingLevel = event.level;
        tui.requestRender();
      });
      pi.on("model_select", (event) => {
        modelId = event.model.id;
        tui.requestRender();
      });
      const unsubBranch = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: () => {
          unsubBranch();
        },
        invalidate() {},
        render(width: number): string[] {
          const lines: string[] = [];

          // Line 1 — pwd
          const branch = footerData.getGitBranch();
          const pwd = branch ? `${ctx.cwd} (${branch})` : ctx.cwd;
          lines.push(truncateToWidth(theme.fg("dim", pwd), width));

          // Line 2 — stats + model + temp + thinking (right)
          let input = 0,
            output = 0,
            cost = 0,
            cache = 0;
          for (const e of ctx.sessionManager.getBranch()) {
            if (e.type === "message" && e.message.role === "assistant") {
              const m = e.message as AssistantMessage;
              input += m.usage.input;
              output += m.usage.output;
              cost += m.usage.cost.total;
              cache += m.usage.cacheWrite ?? 0;
            }
          }
          const fmt = (n: number) =>
            n < 1000 ? `${n}` : `${(n / 1000).toFixed(1)}k`;
          let left = theme.fg(
            "dim",
            `↑${fmt(input)} ↓${fmt(output)} R${fmt(cache)} $${cost.toFixed(3)}`,
          );

          // Context usage
          const ctxUsage = ctx.getContextUsage();
          if (ctxUsage?.tokens != null) {
            left += theme.fg(
              "dim",
              ` ${(ctxUsage.percent ?? 0).toFixed(1)}%/${
                fmt(ctxUsage.contextWindow)
              }`,
            );
          }

          const extStatuses = footerData.getExtensionStatuses();
          const temperature = extStatuses.get("temperature");

          const rightParts: string[] = [];
          rightParts.push(modelId ?? "no-model");
          if (thinkingLevel) rightParts.push(thinkingLevel);
          if (temperature) rightParts.push(temperature);
          const right = theme.fg("dim", rightParts.join(" • "));

          const pad = " ".repeat(
            Math.max(1, width - visibleWidth(left) - visibleWidth(right)),
          );
          lines.push(
            truncateToWidth(left + pad + right, width, theme.fg("dim", "...")),
          );

          return lines;
        },
      };
    });
  });
}
