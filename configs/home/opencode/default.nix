{
  pkgs,
  config,
  lib,
  ...
}:
let
  toFileRef = path: "{file:${path}}";
in
{
  programs.opencode = {
    enable = true;
    enableMcpIntegration = true;
    extraPackages = with pkgs; [
      nodejs
      python3
    ];
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
    model = "opencode-go/deepseek-v4-flash";
    permission = {
      bash = {
        "curl" = "allow";
        "git commit" = "ask";
        "git push" = "ask";
        "nix eval" = "allow";
        "nixos-rebuild" = "deny";
      };
      external_directory = {
        "~/.cache/ghq/**" = "allow";
      };
      skill = {
        "lean4" = "deny";
      };
    };
    tools = lib.mapAttrs' (
      name: server: lib.nameValuePair "${name}_*" false
    ) config.programs.mcp.servers;
  };

  programs.opencode.settings.agent = {
    github = {
      description = "Helps with GitHub operations like creating PRs, reviewing PRs, issues, and searching resources.";
      mode = "subagent";
      prompt = toFileRef ./prompts/github.md;
      tools = {
        "github_*" = true;
      };
    };
    nixos = {
      description = "Queries NixOS data sources — packages, options, docs, flake info, and more.";
      mode = "subagent";
      prompt = toFileRef ./prompts/nixos.md;
      tools = {
        "nixos_*" = true;
      };
    };
    web-research = {
      description = "Performs web research and returns concise summaries.";
      mode = "subagent";
      prompt = toFileRef ./prompts/web-research.md;
      tools = {
        "*" = false;
        webfetch = true;
      };
    };
  };

  programs.opencode.skills = {
    lean4 = "${pkgs.lean4-skills-src}/plugins/lean4/skills/lean4";
  };

  programs.git.ignores = [
    ".opencode.local.json*"
    ".opencode/"
  ];

  home = {
    sessionVariables = {
      OPENCODE_CONFIG = ".opencode.local.json";
      OPENCODE_DISABLE_LSP_DOWNLOAD = "true";
    };
    shellAliases = rec {
      oc = "opencode";
      occ = "${oc} --continue";
    };
  };
}
