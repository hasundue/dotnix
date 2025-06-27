{
  config,
  pkgs,
  lib,
  ...
}:

let
  claude = lib.getExe pkgs.claude-code;

  mkClaudeMcpRemoveCmd = name: ''
    if ${claude} mcp list | grep -q ^${name}:; then
      $DRY_RUN_CMD ${claude} mcp remove ${name}
    fi
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
  lib.concatLines (
    map mkClaudeMcpRemoveCmd (lib.attrNames mcpSevers) ++ lib.mapAttrsToList mkAddMcpServerCmd mcpSevers
  )
)
