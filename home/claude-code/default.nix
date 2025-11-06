{ ... }:
{
  programs.claude-code = {
    enable = false;
    # Disable MCP integration until `{file:...}` syntax is supported
    # mcpServers = config.programs.mcp.servers;
  };
  programs.git.ignores = [
    ".claude/settings.local.*"
    "CLAUDE.local.md"
  ];
}
