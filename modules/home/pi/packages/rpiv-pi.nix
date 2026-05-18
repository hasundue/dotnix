# Per-package module for @juicesharp/rpiv-pi.
#
# Builds a patched copy of rpiv-pi that injects per-agent `model` and `thinking`
# configuration into bundled agent .md file YAML frontmatter.
#
# Usage:
#   pi.rpiv-pi.agents = {
#     codebase-analyzer = {
#       model = "opencode-go/deepseek-v4-pro";
#       thinking = "high";
#     };
#   };

{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    types
    mapAttrs'
    nameValuePair
    optionalString
    concatMapStringsSep
    concatStringsSep
    attrNames
    filter
    literalExpression
    ;

  cfg = config.pi;

  # Rebuild node_modules (same as default.nix — guaranteed Nix cache hit)
  npmModules =
    if cfg.packagesDir != null then
      pkgs.importNpmLock.buildNodeModules {
        npmRoot = cfg.packagesDir;
        nodejs = pkgs.nodejs;
      }
    else
      null;

  rpivPiOrig = if npmModules != null then "${npmModules}/node_modules/@juicesharp/rpiv-pi" else null;

  # Generate newline-separated YAML lines to insert for an agent
  mkAgentYAML =
    agentCfg:
    let
      lines = filter (x: x != "") [
        (optionalString (agentCfg.model or null != null) "model: ${agentCfg.model}")
        (optionalString (agentCfg.thinking or null != null) "thinking: ${agentCfg.thinking}")
      ];
    in
    lines;

  # Build per-agent patch: agentName -> newline-separated YAML lines
  agentPatches = mapAttrs' (
    name: agentCfg: nameValuePair name (mkAgentYAML agentCfg)
  ) cfg.rpiv-pi.agents;

  # Serialized case statements for bash
  patchCases = concatStringsSep "\n" (
    map (
      name:
      let
        lines = agentPatches.${name};
        sedLines = concatMapStringsSep "\\n" (line: line) lines;
      in
      ''
        ${name})
          sed -i '1a\${sedLines}' "$f"
          ;;
      ''
    ) (attrNames agentPatches)
  );

  # Patched derivation: symlink original, replace agents/ with configured copies
  rpivPiPatched =
    if rpivPiOrig != null then
      pkgs.runCommand "rpiv-pi-patched" { } ''
        set -e
        mkdir -p "$out"

        # Symlink original package contents (skip node_modules, agents, and extensions)
        for f in ${rpivPiOrig}/*; do
          base=$(basename "$f")
          [ "$base" = "node_modules" ] && continue
          [ "$base" = "agents" ] && continue
          [ "$base" = "extensions" ] && continue
          ln -s "$f" "$out/$base"
        done

        # Copy extensions/ so import.meta.url resolves to the patched store path
        cp -r --no-preserve=mode ${rpivPiOrig}/extensions "$out/extensions"
        chmod -R u+w "$out/extensions"

        # Copy agents/ so we can patch them
        cp -r --no-preserve=mode ${rpivPiOrig}/agents "$out/agents"

        # Apply per-agent patches
        for f in "$out"/agents/*.md; do
          base=$(basename "$f" .md)
          case "$base" in
            ${patchCases}
            *)
              # No custom config for this agent
              ;;
          esac
        done

        # Symlink original node_modules so require() resolves correctly
        ln -s "${npmModules}/node_modules" "$out/node_modules"
      ''
    else
      null;

in
{
  options.pi.rpiv-pi = {
    agents = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            model = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Model ID for this agent (e.g., opencode-go/deepseek-v4-flash).";
            };
            thinking = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "Thinking level for this agent (e.g., low, medium, high).";
            };
          };
        }
      );
      default = { };
      example = literalExpression ''
        {
          codebase-analyzer = {
            model = "opencode-go/deepseek-v4-flash";
            thinking = "high";
          };
        }
      '';
      description = "Per-agent configuration for bundled rpiv-pi agents.";
    };
  };

  config = mkIf (cfg.enable && cfg.packagesDir != null && cfg.rpiv-pi.agents != { }) (mkMerge [
    {
      # Disable the original auto-discovered package
      pi.packages."@juicesharp/rpiv-pi".enable = lib.mkDefault false;

      # Inject the patched package
      pi.extraPackages = [ "${rpivPiPatched}" ];

      # Fix permissions on copied agent files so pi can update them
      home.activation.fixPiAgentPermissions = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ -d "$HOME/.pi/agent/agents" ]; then
          chmod -R u+w "$HOME/.pi/agent/agents"/*.md 2>/dev/null || true
        fi
      '';
    }
  ]);
}
