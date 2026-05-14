{ config, ... }:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
  exaKeyFile = config.age.secrets."api/exa".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      pi-agent-suite = {
        extensions = {
          codex-verbosity.enable = false;
          codex-quota.enable = false;
          context-projection.enable = false;
          convene-council.enable = false;
          url-scheme.enable = false;
          enable-tools.enable = false;
          footer.enable = false;
          custom-compaction.enable = false;
          context-overflow.enable = false;
          completion-sound.enable = false;
          cmux.enable = false;
          system-prompt.enable = false;
          run-subagent.enable = false;
          ask-llm.enable = false;
          consult-advisor.enable = false;

          main-agent-selection.agents = {
            CodeReview = {
              type = "both";
              description = "Reviews code for correctness and risks";
              model = {
                id = "opencode-go/deepseek-v4-flash";
                thinking = "high";
              };
              tools = [
                "read"
                "bash"
                "edit"
              ];
              text = ''
                You are a code review agent. Check correctness, risks, and missing validation.
              '';
            };
          };
        };
      };

      pi-web-access.settings = {
        workflow = "none";
      };

      context-mode.enable = false;
    };

    settings = {
      theme = "kanagawa-wave";
      defaultProvider = "opencode-go";
      defaultModel = "deepseek-v4-flash";
      defaultThinkingLevel = "xhigh";
      hideThinkingBlock = true;
      enabledModels = [
        "opencode-go/deepseek-v4-flash"
        "opencode-go/deepseek-v4-pro"
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
      ./extensions/footer.ts
      # ./extensions/readonly-mode
      # ./extensions/toggle-bash
    ];

    skills = [
      # ./skills/exa-search
    ];

    keybindings = {
      "app.session.rename" = "ctrl+shift+r";
    };

    context = ''
      Be conservative about making changes. Unless the user says "edit",
      "write", "modify", "implement", or otherwise clearly indicates they
      want actual modifications, treat their input as theoretical — explain
      feasibility, approach, and trade-offs instead of executing. Prefer to
      ask clarifying questions before editing.

      Prefer relative paths for tool calls. Use absolute paths only when
      referencing files outside the current working directory.
    '';
  };

  home.sessionVariables = {
    EXA_API_KEY_FILE = exaKeyFile;
  };
}
