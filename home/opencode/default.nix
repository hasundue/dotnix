{ lib, ... }:

{
  programs.opencode = {
    enable = true;

    # Automatically integrate MCP servers from programs.mcp.servers
    enableMcpIntegration = true;

    rules = ''
      ## Response Formatting
      - Use fenced code blocks for all multi-line code/output (e.g. ``` ... ```).
      - Always include a language tag when possible (e.g., ```ts, ```sh, ```json, ```diff).

      ## GitHub Operations
      - For ANY GitHub-related operations (checking issues, PRs, creating issues/PRs, searching
        GitHub resources, etc.), you MUST use the Task tool with the github subagent instead of
        using the gh command directly via Bash.
    '';

    settings = {
      agent = {
        github = {
          description = "Helps with GitHub operations like creating PRs, issues, and searching resources.";
          mode = "subagent";
          model = "github-copilot/claude-haiku-4.5";
          prompt = ''
            You are a helpful assistant that specializes in performing GitHub operations.
            You will be provided with specific instructions and context to carry out these tasks effectively.
          '';
          tools = {
            "github_*" = true;
            write = false;
            edit = false;
            bash = false;
          };
        };
      };
      model = "github-copilot/claude-sonnet-4.5";
      theme = lib.mkForce "kanagawa-transparent";
      autoupdate = false;
      tools = {
        "nixos_*" = false;
        "github_*" = false;
      };
    };
  };

  home.shellAliases = rec {
    oc = "opencode";
    occ = "${oc} --continue";
  };

  xdg.configFile."opencode/themes/kanagawa-transparent.json".source =
    ./theme-kanagawa-transparent.json;
}
