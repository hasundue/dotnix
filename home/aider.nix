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
      model = "openai/gpt-4o";
      weak-model = "openai/gpt-4o-mini";
    };
  };
}
