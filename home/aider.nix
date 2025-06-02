{ config, pkgs, ... }:

let
  apiKeyFile = config.age.secrets."api/gemini".path;
in
{
  home = {
    packages = with pkgs; [
      aider-chat
      python312Packages.google-generativeai
    ];

    shellAliases = {
      ai = "aider --model gemini-2.0-flash --api-key gemini=$(cat ${apiKeyFile})";
    };
  };
}
