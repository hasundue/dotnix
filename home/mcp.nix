{ config, ... }:

{
  # Single source of truth for ALL MCP servers
  programs.mcp = {
    enable = true;
    servers = {
      github = {
        url = "https://api.githubcopilot.com/mcp/";
        headers = {
          # Direct file reference - no environment variable needed!
          Authorization = "Bearer {file:${config.age.secrets."github/claude-code".path}}";
        };
      };

      # Easy to add more MCP servers here in the future
      # context7 = {
      #   url = "https://mcp.context7.com/mcp";
      #   headers = {
      #     CONTEXT7_API_KEY = "{file:${config.age.secrets."api/context7".path}}";
      #   };
      # };
    };
  };
}
