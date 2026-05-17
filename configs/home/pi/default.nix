{ config, pkgs, ... }:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
  exaKeyFile = config.age.secrets."api/exa".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      pi-agents = {
        agents = {
          explorer = {
            name = "explorer";
            description = "Fast codebase exploration and file-level reconnaissance";
            model = "opencode-go/deepseek-v4-flash";
            thinking = "off";
            skills = [ ];
            text = ''
              You are an explorer agent.

              - Find the relevant files, APIs, and call paths quickly.
              - Return a compact, structured summary for handoff.
              - Always include concrete file paths.
            '';
          };
          worker = {
            name = "worker";
            description = "General-purpose worker for delegated coding tasks";
            model = "opencode-go/deepseek-v4-flash";
            thinking = "xhigh";
            skills = [ ];
            text = ''
              You are a focused worker agent.

              - Complete the delegated task directly.
              - Be concise.
              - If you touch code, explain exactly what changed.
              - If there is uncertainty, call it out explicitly.
            '';
          };
        };
      };

      pi-web-providers.settings = {
        tools = {
          search = "exa";
          contents = "exa";
          answer = "exa";
          research = "exa";
        };
        providers = {
          exa = {
            credentials = {
              api = "!cat ${exaKeyFile}";
            };
          };
        };
      };

      pi-mcporter.settings = {
        mode = "lazy";
        timeoutMs = 30000;
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
      # ./extensions/footer.ts
      # ./extensions/readonly-mode
      # ./extensions/toggle-bash
    ];

    skills = [
      # "${pkgs.worktrunk.src}/skills/worktrunk"
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
