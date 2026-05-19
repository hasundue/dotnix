{
  config,
  pkgs,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      pi-mcporter.settings = {
        mode = "lazy";
        timeoutMs = 30000;
      };

      "@juicesharp/rpiv-pi".enable = false;
    };

    # Per-agent model/thinking configuration.
    #
    # | Tier | Model              | Thinking | Role                              |
    # |------|--------------------|----------|-----------------------------------|
    # | A    | deepseek-v4-flash  | off      | Mechanical lookups (7 agents)     |
    # | B    | kimi-k2.5 / qwen   | high     | Analysis & synthesis (4 agents)   |
    # | C    | deepseek-v4-pro    | high     | Adversarial gatekeeping (3)       |
    # | D    | minimax-m2.7       | medium   | Web research (1 agent)            |
    #
    # qwen3.5-plus is a subagent-only model — not in the Ctrl+P picker.
    rpiv-pi.agents = {
      # ── Tier A: Mechanical lookups — flash + off ──────────────────
      codebase-locator = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      codebase-pattern-finder = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      integration-scanner = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      diff-auditor = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      peer-comparator = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      test-case-locator = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };
      artifacts-locator = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
      };

      # ── Tier B: Analysis & synthesis — kimi (deep) / qwen (shallow) ─
      codebase-analyzer = {
        model = "opencode-go/kimi-k2.5";
        thinking = "high";
      };
      scope-tracer = {
        model = "opencode-go/kimi-k2.5";
        thinking = "high";
      };
      artifacts-analyzer = {
        model = "opencode-go/qwen3.5-plus";
        thinking = "high";
      };
      precedent-locator = {
        model = "opencode-go/qwen3.5-plus";
        thinking = "high";
      };

      # ── Tier C: Adversarial gatekeeping — pro + high ──────────────
      claim-verifier = {
        model = "opencode-go/deepseek-v4-pro";
        thinking = "high";
      };
      artifact-reviewer = {
        model = "opencode-go/deepseek-v4-pro";
        thinking = "high";
      };
      slice-verifier = {
        model = "opencode-go/deepseek-v4-pro";
        thinking = "high";
      };

      # ── Tier D: Web research — minimax + medium ───────────────────
      web-search-researcher = {
        model = "opencode-go/minimax-m2.7";
        thinking = "medium";
      };
    };

    settings = {
      theme = "kanagawa-wave";
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "high";
      hideThinkingBlock = true;
      enabledModels = [
        "opencode-go/deepseek-v4-flash"
        "opencode-go/deepseek-v4-pro"
        "opencode-go/kimi-k2.5"
        "opencode-go/minimax-m2.7"
      ];
    };

    auth = {
      opencode-go = {
        type = "api_key";
        key = "!cat ${opencodeGoKeyPath}";
      };
    };

    themes = [
      ./themes/kanagawa-wave.json
    ];

    extensions = [
      ./extensions/chat-display.ts
      # ./extensions/footer.ts
      # ./extensions/readonly-mode
      # ./extensions/toggle-bash
    ];

    skills = [
      "${pkgs.worktrunk.src}/skills/worktrunk"
      # ./skills/exa-search
    ];

    keybindings = {
      "app.session.rename" = "ctrl+shift+r";
    };

    context = ''
      When the user types /skill:<name> [args], pi expands it into an XML block:

      ```
      <skill name="<name>" location="/.../.../SKILL.md">
      [system guidance from pi]

      [instructions in SKILL.md]
      </skill>

      [args] (optional)
      ```

      - You have already read the skill content. DO NOT call read on the skill file.
      - Follow the instructions immediately.
      - Respond as if the user had typed `/skill:<name> [args]`.
    '';
  };

  programs.git.ignores = [
    ".pi/"
    ".rpiv/"
  ];

}
