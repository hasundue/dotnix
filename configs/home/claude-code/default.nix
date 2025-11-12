{ ... }:
{
  programs.claude-code = {
    enable = true;
    # Disable MCP integration until `{file:...}` syntax is supported
    # mcpServers = config.programs.mcp.servers;
  };
  programs.git.ignores = [
    ".claude/"
    "CLAUDE.local.md"
  ];
}
