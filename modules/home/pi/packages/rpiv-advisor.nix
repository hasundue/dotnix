# Per-package module for @juicesharp/rpiv-advisor.
#
# Writes the rpiv-advisor config to ~/.config/rpiv-advisor/advisor.json.
#
# Usage (to override defaults):
#   pi.packages."@juicesharp/rpiv-advisor".settings = {
#     modelKey = "opencode-go:deepseek-v4-pro";
#     effort = "high";
#   };

{ config, lib, ... }:

let
  inherit (builtins) toJSON;

  pkgConfig = config.pi.packages."@juicesharp/rpiv-advisor" or { };

  # Default settings, overridable via pi.packages
  defaults = {
    modelKey = "opencode-go:deepseek-v4-pro";
    effort = "high";
  };

  settings = defaults // (pkgConfig.settings or { });
in
{
  config = lib.mkIf config.pi.enable {
    home.file.".config/rpiv-advisor/advisor.json" = {
      text = toJSON settings;
    };
  };
}
