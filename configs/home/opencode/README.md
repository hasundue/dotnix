# OpenCode Configuration

This directory contains the OpenCode configuration used across all projects
managed by this NixOS setup.

## Architecture

### Context Management Strategy

OpenCode is configured to minimize context bloat using two complementary
approaches:

1. **Subagents** - For operations with many tool definitions that would bloat
   baseline context
2. **Local overrides** - For moderate-sized tool sets that are project-specific

**Core Principle**: Keep baseline context lean by routing high-context
operations strategically.

### Subagent Usage

#### When to Use Subagents

Use subagents for operations with **many tool definitions** (high baseline
cost):

- **MCP servers with many tools** - Route through subagents
  - Each MCP server exposes its own tool set (e.g., filesystem, github, browser)
  - Many tools across servers would bloat baseline context if all enabled
  - Subagent isolates the tool definitions and returns only relevant results

- **Code exploration** - Use Task tool with general subagent
  - Large search results and file contents
  - Multi-step exploration tasks
  - Returns focused findings instead of raw data

- **Heavy external operations**
  - PDF reading (zotero-mcp)
  - Web searches with large results
  - Any operation returning variable-sized, potentially large responses

#### When to Use Local Overrides

Use local `opencode.jsonc` files for **moderate tool sets** that are
project-specific:

- **NixOS tools** - Disabled globally, enabled per-project
  - ~18 tool definitions (~2K tokens) - moderate cost
  - Only needed in NixOS configuration projects
  - Responses are concise and useful
  - Example: This dotnix repository enables nixos tools via local override

#### Subagent Configuration

Subagents are configured in `default.nix`:

```nix
agent = {
  general = {
    # Main agent - minimal tools, uses default model
  };
  
  web-research = {
    description = "Performs web research and returns concise summaries.";
    mode = "subagent";
    model = models.subagent;
    prompt = toFileRef ./prompts/web-research.md;
    tools = {
      "*" = false;
      webfetch = true;
    };
  };
}

# Global settings disable nixos tools by default
settings = {
  tools = {
    "nixos*" = false;  # Disabled globally
  };
};
```

#### Local Override Configuration

Project-specific tools are enabled via `opencode.jsonc` in the repository root:

```jsonc
{
  // Enable NixOS tools for this project only
  "tools": {
    "nixos*": true
  }
}
```

### MCP Integration

MCP servers are configured centrally in `home/mcp.nix` and automatically
integrated via `enableMcpIntegration = true`.

**Architecture**:

- MCP servers are always available (configured in `home/mcp.nix`)
- Tool visibility is controlled separately:
  - **Heavy tool sets** → Routed through subagents
  - **Moderate tool sets** → Disabled globally, enabled per-project via
    `opencode.jsonc`
  - **Lightweight tools** → Enabled in main context

## Usage

### Shell Aliases

- `oc` - Launch OpenCode
- `occ` - Continue previous OpenCode session

### Custom Theme

Uses `kanagawa-transparent` theme matching the overall system aesthetic
(Stylix + Kanagawa).

## Philosophy

This configuration uses a two-tier strategy for context management:

### 1. Subagents (for high tool count)

- **Trade-off**: Higher latency vs. zero baseline context cost
- **Use when**: Tool set has 30+ definitions (e.g., github)
- **Benefit**: Keeps baseline context minimal regardless of tool complexity

### 2. Local Overrides (for moderate, project-specific tools)

- **Trade-off**: Small baseline cost (~2K tokens) vs. zero latency
- **Use when**: Tool set is moderate (10-20 tools) and project-specific
- **Benefit**: Direct access without round-trip overhead when needed

The architecture prioritizes context efficiency while avoiding unnecessary
latency for moderate-sized, frequently-used tool sets.
