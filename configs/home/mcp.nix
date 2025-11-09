{ config, pkgs, ... }:
{
  home.packages = with pkgs; [
    mcp-nixos
    zotero-mcp
  ];
  programs.mcp = {
    enable = true;
    servers = {
      github = {
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          Authorization = "Bearer {file:${config.age.secrets."github/claude-code".path}}";
        };
      };
      nixos = {
        command = "mcp-nixos";
        args = [ ];
      };
      zotero = {
        command = "zotero-mcp";
        env = {
          ZOTERO_LOCAL = "true";
        };
      };
    };
  };
}
