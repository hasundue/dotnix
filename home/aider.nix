{ config, pkgs, lib, ... }:

let
  apiKeyFile = config.age.secrets."api/copilot".path;
in
{
  home = {
    packages = with pkgs; [
      aider-chat
    ];

    shellAliases = {
      aider = "aider --api-key openai=$(cat ${apiKeyFile})";
    };

    file.".aider.conf.yml".text = lib.generators.toYAML { } {
      openai-api-base = "https://api.githubcopilot.com";

      model = "openai/claude-3.7-sonnet";
      weak-model = "openai/gpt-4o-mini";

      auto-commits = false;
      auto-test = true;
    };

    file.".aider.model.metadata.json".text = lib.generators.toJSON { } {
      "openai/claude-3.7-sonnet" = {
        "max_tokens" = 8192;
        "max_input_tokens" = 200000;
        "max_output_tokens" = 64000;
      };
    };
  };

  programs.git.ignores = [
    ".aider*"
  ];
}
