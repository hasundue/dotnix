{
  config,
  pkgs,
  lib,
  ...
}:

let
  claude = lib.getExe pkgs.claude-code;

  mkClaudeMcpRemoveAllCmd = ''
    # Remove all existing MCP servers to sync with our configuration
    for server in $(${claude} mcp list | grep -E '^[^:]+:' | cut -d: -f1); do
      $DRY_RUN_CMD ${claude} mcp remove "$server"
    done
  '';

  mkAddMcpServerCmd =
    name: attrs:
    if attrs ? type && attrs.type == "http" then
      mkAddMcpHttpServerCmd name attrs
    else
      mkAddJsonMcpServerCmd name attrs;

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
mcpSevers:
lib.hm.dag.entryAfter [ "writeBoundary" ] (
  lib.concatLines ([ mkClaudeMcpRemoveAllCmd ] ++ lib.mapAttrsToList mkAddMcpServerCmd mcpSevers)
)
