# Per-package module for pi-web-providers (npm:pi-web-providers).
#
# Writes the web providers config to ~/.pi/agent/web-providers.json.
#
# Usage:
#   pi.packages.pi-web-providers.settings = {
#     tools = {
#       search = "exa";
#       contents = "exa";
#     };
#     providers.exa.credentials.api = "!cat /path/to/key";
#   };

{ config, lib, ... }:

let
  inherit (builtins) toJSON;

  pkgConfig = config.pi.packages.pi-web-providers or { };
  settings = pkgConfig.settings or { };
in
{
  config = lib.mkIf (settings != { }) {
    home.file.".pi/agent/web-providers.json" = {
      text = toJSON settings;
    };
  };
}
