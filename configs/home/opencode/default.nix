{
  config,
  lib,
  ...
}:
let
  models = {
    main = "{env:OPENCODE_MODEL}";
    subagent = "{env:OPENCODE_SUBAGENT_MODEL}";
  };
  toFileRef = path: "{file:${path}}";
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    rules = toString ./rules.md;
  };
  programs.opencode.settings = {
    formatter = {
      deno = {
        command = [
          "deno"
          "fmt"
          "$FILE"
        ];
        extensions = [
          ".js"
          ".jsx"
          ".mjs"
          ".cjs"
          ".ts"
          ".tsx"
          ".mts"
          ".cts"
          ".md"
          ".markdown"
          ".json"
          ".jsonc"
          ".ipynb"
        ];
      };
      nixfmt = {
        command = [
          "nixfmt"
          "$FILE"
        ];
        extensions = [ ".nix" ];
      };
    };
    lsp = {
      nixd = {
        command = [ "nixd" ];
        extensions = [ ".nix" ];
      };
    };
    model = models.main;
    permission = {
      bash = {
        "curl" = "allow";
        "git commit" = "ask";
        "git push" = "ask";
        "nixos-rebuild" = "deny";
      };
    };
    theme = lib.mkForce "kanagawa";
    tools = lib.mapAttrs' (
      name: server: lib.nameValuePair "${name}_*" false
    ) config.programs.mcp.servers;
  };
  programs.opencode.settings.agent = {
    general = {
      model = models.subagent;
    };
    plan = {
      permission = {
        bash = {
          "nix eval" = "allow";
        };
      };
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
  };
  programs.opencode.settings.provider = {
    anthropic = {
      models = {
        claude-sonnet-4-5 = {
          headers = {
            "anthropic-beta" =
              "claude-code-20250219,interleaved-thinking-2025-05-14,fine-grained-tool-streaming-2025-05-14,clear_tool_uses_20250919,clear_thinking_20251015";
          };
          options = {
            thinking = {
              type = "enabled";
              budgetTokens = 16000;
            };
          };
        };
      };
    };
  };
  programs.git.ignores = [
    "opencode.local.json*"
  ];
  home = {
    sessionVariables = {
      OPENCODE_MODEL = "anthropic/claude-sonnet-4-5";
      OPENCODE_SUBAGENT_MODEL = "anthropic/claude-haiku-4-5";
    };
    shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };
  };
}
