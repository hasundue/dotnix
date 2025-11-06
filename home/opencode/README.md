# OpenCode Configuration

This directory contains the OpenCode configuration used across all projects managed by this NixOS setup.

## Architecture

### Context Management Strategy

OpenCode is configured to minimize context bloat by delegating heavy operations to specialized subagents. This architecture ensures AI agents maintain optimal performance across all projects.

**Core Principle**: Keep baseline context lean by routing operations with high context costs through subagents, which return only concise, essential results.

### Subagent Usage

#### When to Use Subagents

Use subagents for operations that would bloat the main conversation context:

- **GitHub operations** - Use github subagent instead of direct GitHub MCP tools
  - GitHub MCP exposes many tools (issues, PRs, releases, checks, etc.)
  - Subagent keeps these tool definitions out of baseline context
  - Returns only relevant, summarized information

- **NixOS queries** - Delegate to nixos-mcp via subagent when needed
  - NixOS MCP has extensive tooling for package search, options, etc.
  - Heavy tool definitions avoided in main context

- **Code exploration** - Use Task tool with general subagent
  - Large search results and file contents
  - Multi-step exploration tasks
  - Returns focused findings instead of raw data

- **Heavy external operations**
  - PDF reading (zotero-mcp)
  - Web searches with large results
  - Any operation returning variable-sized, potentially large responses

#### Subagent Configuration

Subagents are configured in `default.nix`:

```nix
agent = {
  build = {
    # Main agent - minimal tools
    tools = {
      "github*" = false;  # Disabled - use subagent instead
    };
  };
  
  github = {
    # Specialized subagent with focused toolset
    mode = "subagent";
    model = "github-copilot/claude-haiku-4.5";  # Faster model for focused tasks
    tools = {
      "github*" = true;   # GitHub MCP tools available here
      write = false;      # Limited permissions
      edit = false;
      bash = false;
    };
  };
}
```

### MCP Integration

MCP servers are configured centrally in `home/mcp.nix` and automatically integrated via `enableMcpIntegration = true`.

**Current Setup**:
- Only lightweight, essential MCP servers in main context
- Heavy MCP servers accessed exclusively through subagents
- Subagents have their own tool access configurations

## Usage

### Shell Aliases

- `oc` - Launch OpenCode
- `occ` - Continue previous OpenCode session

### Custom Theme

Uses `kanagawa-transparent` theme matching the overall system aesthetic (Stylix + Kanagawa).

## Philosophy

This configuration reflects a deliberate trade-off:
- **Higher latency**: Subagent calls add round-trip time
- **Lower context usage**: Baseline context stays minimal, avoiding frequent context limit issues
- **Better scalability**: Can work with complex codebases and multiple tools without hitting limits

The architecture prioritizes context efficiency over immediate response time, based on the observation that context limits were a more frequent pain point than latency.
