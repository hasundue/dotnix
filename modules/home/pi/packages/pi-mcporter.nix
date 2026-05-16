# Per-package module for pi-mcporter (npm:pi-mcporter).
#
# Writes pi-mcporter settings to ~/.pi/agent/mcporter.json and
# bridges MCP servers from programs.mcp.servers to MCPorter's config.
#
# Usage:
#   pi.packages.pi-mcporter.settings = {
#     mode = "lazy";
#     timeoutMs = 30000;
#   };

{ config, lib, pkgs, ... }:

let
  inherit (builtins) toJSON;

  pkgConfig = config.pi.packages.pi-mcporter or { };
  piSettings = pkgConfig.settings or { };
  mcpServers = config.programs.mcp.servers or { };
in
{
  config = lib.mkIf config.pi.enable {
    home.packages = with pkgs; [ mcporter ];

    # pi-mcporter extension settings — configPath tells the mcporter
    # runtime where to find the server definitions.
    home.file.".pi/agent/mcporter.json" = lib.mkIf (piSettings != { }) {
      text = toJSON (piSettings // {
        configPath = "${config.home.homeDirectory}/.config/mcporter/mcporter.json";
      });
    };

    # MCPorter config from programs.mcp.servers (standard MCP JSON format)
    home.file.".config/mcporter/mcporter.json" = lib.mkIf (mcpServers != { }) {
      text = toJSON { mcpServers = mcpServers; };
    };
  };
}
