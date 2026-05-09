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
  home.packages = [ pkgs.llm-agents.pi ];

  home.sessionVariables = {
    EXA_API_KEY_FILE = exaKeyFile;
  };

  home.file =
    lib.mapAttrs'
      (name: value: {
        name = ".pi/agent/${name}";
        inherit value;
      })
      {
        "settings.json".text = builtins.toJSON {
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
        "themes/kanagawa-wave.json".source = ./themes/kanagawa-wave.json;
        "auth.json".text = builtins.toJSON {
          opencode-go = {
            type = "api_key";
            key = "!cat ${opencodeGoKeyPath}";
          };
        };
        "skills".source = ./skills;
        "extensions".source = ./extensions;
        "APPEND_SYSTEM.md".text = ''
          Be conservative about making changes. Unless the user says "edit",
          "write", "modify", "implement", or otherwise clearly indicates they
          want actual modifications, treat their input as theoretical — explain
          feasibility, approach, and trade-offs instead of executing. Prefer to
          ask clarifying questions before editing.
        '';
        "keybindings.json".text = builtins.toJSON {
          "app.session.rename" = "ctrl+shift+r";
        };
      };
}
