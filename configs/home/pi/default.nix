{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
  exaKeyFile = config.age.secrets."api/exa".path;
in
{
  pi = {
    enable = true;
    packagesDir = ./.;

    packages = {
      "@tintinweb/pi-subagents" = { };

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
      "${pkgs.worktrunk.src}/skills/worktrunk"
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

  programs.git.ignores = [
    ".pi/"
    ".rpiv/"
  ];

  home.activation.writeRpivWebToolsConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfgDir="$HOME/.config/rpiv-web-tools"
    mkdir -p "$cfgDir"
    cat > "$cfgDir/config.json" << EOF
    {
      "provider": "exa",
      "apiKeys": {
        "exa": "$(cat ${exaKeyFile})"
      }
    }
    EOF
  '';
}
