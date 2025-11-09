{ lib, ... }:

let
  models = {
    main = "{env:OPENCODE_MODEL}";
    subagent = "{env:OPENCODE_SUBAGENT_MODEL}";
  };
in
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

      ## Web Research Operations
      - For extensive web research (multiple pages, synthesis needed, uncertain scope), use the
        Task tool with the web-research subagent instead of WebFetch directly.
      - For targeted lookups (specific fact, known concise page, user-provided URL), direct
        WebFetch is acceptable.
      - Prefer local tools (Read, raw URLs) over web fetches when possible.
    '';

    settings = {
      agent = {
        plan = {
          permission = {
            bash = {
              "curl" = "allow";
              "nix eval" = "allow";
            };
          };
        };
        github = {
          description = "Helps with GitHub operations like creating PRs, issues, and searching resources.";
          mode = "subagent";
          model = models.subagent;
          prompt = ''
            You are a helpful assistant that specializes in performing GitHub operations.
            You will be provided with specific instructions and context to carry out these tasks effectively.
          '';
          tools = {
            "*" = false;
            "github_*" = true;
          };
        };
        web-research = {
          description = "Performs web research and returns concise summaries.";
          mode = "subagent";
          model = models.subagent;
          prompt = ''
            You are a web research assistant. Your job is to:
            1. Fetch web content using WebFetch
            2. Extract the most relevant information for the user's question
            3. Return a concise summary (100-500 tokens)
            4. Include source URLs for reference

            Be direct and factual. Avoid unnecessary details.
          '';
          tools = {
            "*" = false;
            webfetch = true;
          };
        };
      };
      model = models.main;
      theme = lib.mkForce "kanagawa";
      permission = {
        bash = {
          "curl" = "allow";
          "git push" = "deny";
        };
      };
      tools = {
        "nixos_*" = false;
        "github_*" = false;
      };
    };
  };

  programs.git.ignores = [
    "opencode.local.json*"
  ];

  home = {
    sessionVariables = {
      OPENCODE_MODEL = "github-copilot/claude-sonnet-4.5";
      OPENCODE_SUBAGENT_MODEL = "github-copilot/claude-haiku-4.5";
    };
    shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };
  };
}
