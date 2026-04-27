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
    context = ./context.md;
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
      nil = {
        command = [ "nil" ];
        extensions = [ ".nix" ];
      };
    };
    model = models.main;
    permission = {
      bash = {
        "curl" = "allow";
        "git commit" = "ask";
        "git push" = "ask";
        "nix eval" = "allow";
        "nixos-rebuild" = "deny";
      };
    };
    tools = lib.mapAttrs' (
      name: server: lib.nameValuePair "${name}_*" false
    ) config.programs.mcp.servers;
  };

  programs.opencode.settings.agent = {
    general = {
      model = models.subagent;
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

  programs.git.ignores = [
    "opencode.local.json*"
  ];

  home = {
    sessionVariables = {
      OPENCODE_MODEL = "opencode-go/deepseek-v4-flash";
      OPENCODE_SUBAGENT_MODEL = "opencode-go/deepseek-v4-flash";
      OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    };
    shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };
  };
}
