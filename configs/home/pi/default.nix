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
          defaultThinkingLevel = "high";
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
        "skills/exa-search/SKILL.md".source = ./skills/exa-search/SKILL.md;
        "skills/exa-search/search.ts" = {
          source = ./skills/exa-search/search.ts;
          executable = true;
        };
        "skills/create-skill/SKILL.md".source = ./skills/create-skill/SKILL.md;
        "skills/create-skill/script.ts".source = ./skills/create-skill/script.ts;
        "skills/create-skill/SKILL_TEMPLATE.md".source = ./skills/create-skill/SKILL_TEMPLATE.md;
      };
}
