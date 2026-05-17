# Per-package module for @tintinweb/pi-subagents.
#
# Generates agent .md files with YAML frontmatter in ~/.pi/agent/agents/
# (the global agent dir for pi-subagents).
#
# Usage:
#   pi.packages."@tintinweb/pi-subagents".agents = {
#     explorer = {
#       name = "explorer";
#       description = "Fast codebase exploration";
#       model = "opencode-go/deepseek-v4-flash";
#       thinking = "low";
#       skills = [ "search" ];
#       text = ''
#         You are an explorer agent...
#       '';
#     };
#   };

{ config, lib, ... }:

let
  inherit (lib)
    filterAttrs
    mapAttrs'
    mkIf
    optionalAttrs
    ;

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Build the YAML frontmatter attrset for an agent, omitting null/empty fields
  agentFrontmatter =
    agent:
    let
      desc = agent.description or "";
      skills = agent.skills or [ ];
    in
    {
      name = agent.name;
    }
    // optionalAttrs (desc != "") { description = desc; }
    // optionalAttrs (agent.model or null != null) { model = agent.model; }
    // optionalAttrs (agent.thinking or null != null) { thinking = agent.thinking; }
    // optionalAttrs (skills != [ ]) { inherit skills; };

  # ---------------------------------------------------------------------------
  # Minimal YAML serializer
  # ---------------------------------------------------------------------------

  indent = n: builtins.concatStringsSep "" (builtins.genList (_: "  ") n);

  go =
    v: i:
    if builtins.isAttrs v then
      goAttrs v i
    else if builtins.isList v then
      goList v i
    else
      builtins.toString v;

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

  pkgConfig = config.pi.packages."@tintinweb/pi-subagents" or { };
  agents = pkgConfig.agents or { };

  # Generate agent .md files
  agentFiles = mapAttrs' (
    agentName: agent:
    let
      name = agent.name or agentName;
    in
    {
      name = ".pi/agent/agents/${name}.md";
      value = {
        text = agentFileContent agent;
      };
    }
  ) agents;

in
{
  config = mkIf (agents != { }) {
    home.file = agentFiles;
  };
}
