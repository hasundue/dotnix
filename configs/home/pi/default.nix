{ config, ... }:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
  exaKeyFile = config.age.secrets."api/exa".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;
    packages = [
      "pi-mcp-adapter"
      "pi-web-access"
      "pi-subdir-context"
    ];

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
    '';
  };

  home.sessionVariables = {
    EXA_API_KEY_FILE = exaKeyFile;
  };
}
