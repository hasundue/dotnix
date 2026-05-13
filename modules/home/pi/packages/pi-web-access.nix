# Per-package module for pi-web-access (npm:pi-web-access).
#
# Usage:
#   pi.packages.pi-web-access.settings = {
#     workflow = "none";
#   };
#
# Writes ~/.pi/web-search.json when settings is non-empty.
# See: https://github.com/earendil-works/pi-mono/tree/main/packages/pi-web-access#configuration

{ config, lib, ... }:

let
  inherit (builtins) toJSON;

  pkgConfig = config.pi.packages.pi-web-access or { };
  settings = pkgConfig.settings or { };
in
{
  config = lib.mkIf (settings != { }) {
    home.file.".pi/web-search.json" = {
      text = toJSON settings;
    };
  };
}
