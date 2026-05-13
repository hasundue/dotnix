import type { AssistantMessage } from "@earendil-works/pi-ai";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";

const RUNTIME_PROPERTY = "__piHarnessAgentRuntimeCompositionV5";
const MAIN_AGENT_CHANGE_EVENT = "pi-harness:main-agent-contribution-change";

interface CompositionHolder {
  runtime: {
    getMainAgentContribution(): { agent?: { id: string } } | undefined;
  };
}

interface EventBus {
  on(event: string, listener: () => void): () => void;
}

function getAgentId(pi: ExtensionAPI): string | undefined {
  const holder = (pi.events as Record<string, unknown>)[RUNTIME_PROPERTY];
  if (!holder) return undefined;
  return (holder as CompositionHolder).runtime?.getMainAgentContribution()
    ?.agent?.id;
}

export default function agentStatus(pi: ExtensionAPI): void {
  pi.on("session_start", (_event, ctx) => {
    let agentId = getAgentId(pi);
    let thinkingLevel = pi.getThinkingLevel();
    let modelId = ctx.model?.id;

    ctx.ui.setFooter((tui, theme, footerData) => {
      const unsubAgent = (pi.events as unknown as EventBus).on(
        MAIN_AGENT_CHANGE_EVENT,
        () => {
          agentId = getAgentId(pi);
          tui.requestRender();
        },
      );
      const unsubBranch = footerData.onBranchChange(() => tui.requestRender());

      return {
        dispose: () => {
          unsubAgent();
          unsubBranch();
        },
        invalidate() {},
        render(width: number): string[] {
          const lines: string[] = [];

          // Line 1 — pwd
          const branch = footerData.getGitBranch();
          const pwd = branch ? `${ctx.cwd} (${branch})` : ctx.cwd;
          lines.push(truncateToWidth(theme.fg("dim", pwd), width));

          // Line 2 — stats + model + agent (right)
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

          const rightParts: string[] = [];
          if (agentId) rightParts.push(agentId);
          rightParts.push(modelId ?? "no-model");
          if (thinkingLevel) rightParts.push(thinkingLevel);
          const right = theme.fg("dim", rightParts.join(" • "));

          const pad = " ".repeat(
            Math.max(1, width - visibleWidth(left) - visibleWidth(right)),
          );
          lines.push(
            truncateToWidth(left + pad + right, width, theme.fg("dim", "...")),
          );

          // Line 3 — extension statuses (agent already shown inline)
          const statuses = Array.from(
            footerData.getExtensionStatuses().entries(),
          )
            .filter(([k]) => k !== "agent")
            .sort(([a], [b]) => a.localeCompare(b))
            .map(([, v]) =>
              v.replace(/[\r\n\t]/g, " ").replace(/ +/g, " ").trim()
            );
          if (statuses.length > 0) {
            lines.push(
              truncateToWidth(
                statuses.join(" · "),
                width,
                theme.fg("dim", "..."),
              ),
            );
          }

          return lines;
        },
      };
    });
  });
}
