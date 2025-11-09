{
  config,
  pkgs,
  lib,
  ...
}:
let
  remoteServers = {
    github = {
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        Authorization = "Bearer {file:${config.age.secrets."github/claude-code".path}}";
      };
    };
  };
  stdioServers = {
    nixos = {
      package = pkgs.mcp-nixos;
    };
    zotero = {
      package = pkgs.zotero-mcp;
      env = [ "ZOTERO_LOCAL=true" ];
    };
  };
  mkLocalServerConfigs = import ./wrapper.nix { inherit pkgs lib; };
  localServerConfigs = mkLocalServerConfigs stdioServers;
in
{
  home.packages = lib.attrValues stdioServers |> map (s: s.package);
  programs.mcp = {
    enable = true;
    servers = remoteServers // localServerConfigs.servers;
  };
  systemd.user = {
    inherit (localServerConfigs) sockets services;
  };
}
