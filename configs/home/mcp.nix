{ pkgs, ... }:
{
  mcp-servers.programs = {
    github = {
      enable = true;
      passwordCommand = {
        GITHUB_PERSONAL_ACCESS_TOKEN = [
          "gh"
          "auth"
          "token"
        ];
      };
    };
    nixos.enable = true;
  };
  mcp-servers.settings.servers = {
    lean = {
      command = "${pkgs.lean-lsp-mcp}/bin/lean-lsp-mcp";
    };
  };
}
