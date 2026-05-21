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
    };

    rpiv-pi.agents = {
      # ── Tier A: Mechanical lookups
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

      # ── Tier B: Analysis & synthesis
      codebase-analyzer = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "high";
      };
      scope-tracer = {
        model = "opencode-go/minimax-m2.7";
        thinking = "off";
      };
      artifacts-analyzer = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "high";
      };
      precedent-locator = {
        model = "opencode-go/minimax-m2.7";
        thinking = "off";
      };

      # ── Tier C: Adversarial gatekeeping
      claim-verifier = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "high";
      };
      artifact-reviewer = {
        model = "opencode-go/minimax-m2.7";
        thinking = "high";
      };
      slice-verifier = {
        model = "opencode-go/minimax-m2.7";
        thinking = "high";
      };

      # ── Tier D: Web research
      web-search-researcher = {
        model = "opencode-go/deepseek-v4-flash";
        thinking = "off";
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
        "opencode-go/kimi-k2.6"
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
      ./skills/create-deno-skill
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
