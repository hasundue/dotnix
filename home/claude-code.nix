{
  config,
  pkgs,
  lib,
  ...
}:

let
  getSecretPath = name: config.age.secrets.${name}.path;

  mcp-servers = {
    github = {
      type = "http";
      url = "https://api.githubcopilot.com/mcp/";
      headers = {
        "Authorization" = "Bearer $(cat ${getSecretPath "github/claude-code"})";
      };
    };
  };

  claude = lib.getExe pkgs.claude-code;

  mkClaudeMcpRemoveCmd = name: ''
    if ${claude} mcp list | grep -q ${name}; then
      $DRY_RUN_CMD ${claude} mcp remove ${name}
    fi
  '';

  mkAddMcpServerCmd =
    name:
    { type, ... }@attrs:
    if type == "http" then mkAddMcpHttpServerCmd name attrs else mkAddJsonMcpServerCmd name attrs;

  mkAddMcpHttpServerCmd =
    name:
    {
      type,
      url,
      headers ? { },
    }:
    ''
      $DRY_RUN_CMD ${claude} mcp add -s user --transport http ${name} ${url} ${mkHeaderArgs headers}
    '';

  mkHeaderArgs =
    headers:
    lib.concatStringsSep " " (
      lib.mapAttrsToList (name: value: ''--header "${name}: ${value}"'') headers
    );

  mkAddJsonMcpServerCmd = name: attrs: ''
    $DRY_RUN_CMD ${claude} mcp add-json -s user ${name} '${builtins.toJSON attrs}'
  '';
in
{
  home.activation.claude-mcp-setup = lib.hm.dag.entryAfter [ "writeBoundary" ] (
    lib.concatLines (
      map mkClaudeMcpRemoveCmd (lib.attrNames mcp-servers)
      ++ lib.mapAttrsToList mkAddMcpServerCmd mcp-servers
    )
  );

  home.packages = with pkgs; [
    claude-code
  ];

  programs.git.ignores = [
    ".claude/"
  ];
}
