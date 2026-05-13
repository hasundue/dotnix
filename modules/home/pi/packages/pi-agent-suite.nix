# Per-package module for pi-agent-suite (npm:pi-agent-suite).
#
# Generates agent .md files with YAML frontmatter from extension agent definitions.
#
# Usage:
#   pi.packages.pi-agent-suite.extensions.main-agent-selection.agents = {
#     AgentName = { type = "main"; description = "..."; model.id = "..."; ... };
#   };

{ config, lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mkIf
    nameValuePair
    optionalAttrs
    ;
  inherit (lib.strings) removePrefix;

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Map extension config key to its storage directory.
  extStorageDir =
    extName:
    {
      "main-agent-selection" = "agent-selection";
    }
    .${extName} or extName;

  # Build the YAML frontmatter attrset for an agent, omitting null/empty fields
  agentFrontmatter =
    agent:
    let
      desc = agent.description or "";
      model = agent.model or { };
      tools = agent.tools or [ ];
      subAgents = agent.subAgents or [ ];
    in
    {
      type = agent.type or "main";
    }
    // optionalAttrs (desc != "") { description = desc; }
    // optionalAttrs (model.id or null != null || model.thinking or null != null) {
      model = filterAttrs (_: v: v != null) {
        id = model.id or null;
        thinking = model.thinking or null;
      };
    }
    // optionalAttrs (tools != [ ]) { tools = tools; }
    // optionalAttrs (subAgents != [ ]) { agents = subAgents; };

  # ---------------------------------------------------------------------------
  # Minimal YAML serializer (subsets: attrs, list of strings, nested attrs)
  # ---------------------------------------------------------------------------

  indent = n: builtins.concatStringsSep "" (builtins.genList (_: "  ") n);

  # Serialize a YAML value at a given indentation depth.
  go =
    v: i:
    if builtins.isAttrs v then
      goAttrs v i
    else if builtins.isList v then
      goList v i
    else
      builtins.toString v;

  # Serialize attrs, each key on its own line.
  goAttrs =
    attrs: i:
    let
      prefix = indent i;
      entries = builtins.attrValues (
        builtins.mapAttrs (
          name: v:
          if builtins.isAttrs v || builtins.isList v then
            "${prefix}${name}:\n${go v (i + 1)}"
          else
            "${prefix}${name}: ${go v (i + 1)}"
        ) attrs
      );
    in
    builtins.concatStringsSep "\n" entries;

  # Serialize a list, each item on its own line.
  goList =
    list: i:
    let
      prefix = indent i;
    in
    builtins.concatStringsSep "\n" (map (v: "${prefix}- ${go v (i + 1)}") list);

  toYAML = go;

  # Generate the full content of one agent .md file
  agentFileContent = agent: "---\n${toYAML (agentFrontmatter agent) 0}\n---\n\n${agent.text}";

  # ---------------------------------------------------------------------------
  # Config
  # ---------------------------------------------------------------------------

  pkg = config.pi.packages.pi-agent-suite or { };
  pkgConfigDir = removePrefix "pi-" "pi-agent-suite"; # → "agent-suite"

  # Enabled extensions that have agents defined
  extWithAgents = filterAttrs (_: ext: (ext.enable or true) && (ext.agents or { }) != { }) (
    pkg.extensions or { }
  );

  # Generate agent .md files
  agentFiles = builtins.foldl' (
    acc: extName:
    let
      ext = extWithAgents.${extName};
    in
    acc
    // mapAttrs' (
      agentName: agent:
      nameValuePair (".pi/agent/${pkgConfigDir}/${extStorageDir extName}/agents/${agentName}.md") {
        text = agentFileContent agent;
      }
    ) ext.agents
  ) { } (builtins.attrNames extWithAgents);

in
{
  config = mkIf (agentFiles != { }) {
    home.file = agentFiles;
  };
}
