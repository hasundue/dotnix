{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
in
{
  home.packages = [ pkgs.llm-agents.pi ];

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
      };
}
