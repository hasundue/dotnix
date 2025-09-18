{
  config,
  pkgs,
  lib,
  ...
}@inputs:

let
  getSecretPath = name: config.age.secrets.${name}.path;

  mcpServers = {
    github = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        "Authorization" = "Bearer $(cat ${getSecretPath "github/claude-code"})";
      };
    };
    serena = {
      type = "stdio";
      command = lib.getExe' pkgs.serena "serena";
      args = [
        "start-mcp-server"
        "--transport"
        "stdio"
        "--context"
        "ide-assistant"
        "--project"
        "$(pwd)"
      ];
    };
  };

  setupMcpServers = import ./setup-mcp-servers.nix inputs;
in
{
  home.activation.claude-mcp-setup = setupMcpServers mcpServers;

  home.packages = with pkgs; [
    claude-code
  ];

  programs.git.ignores = [
    ".claude/settings.local.*"
    ".serena/*"
    "CLAUDE.local.md"
  ];
}
