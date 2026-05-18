# Per-package module for @juicesharp/rpiv-advisor.
#
# Writes the rpiv-advisor config to ~/.config/rpiv-advisor/advisor.json
# only when the user explicitly provides settings. Without settings, no
# config is written and the package uses its own default (advisor disabled).
#
# Usage:
#   pi.packages."@juicesharp/rpiv-advisor".settings = {
#     modelKey = "opencode-go:deepseek-v4-pro";
#     effort = "high";
#   };

{ config, lib, ... }:

let
  inherit (builtins) toJSON;

  pkgConfig = config.pi.packages."@juicesharp/rpiv-advisor" or { };
  settings = pkgConfig.settings or { };
in
{
  config = lib.mkIf (config.pi.enable && settings != { }) {
    home.file.".config/rpiv-advisor/advisor.json" = {
      text = toJSON settings;
    };
  };
}
