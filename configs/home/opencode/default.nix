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
    # enableMcpIntegration = true;
    extraPackages = with pkgs; [
      nodejs
      python3
    ];
    # context = ./context.md; # commented: testing vanilla ws profile
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
    model = "opencode-go/minimax-m2.5";
    small_model = "opencode-go/qwen3.5-plus";
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
        "/tmp/**" = "allow";
        "/nix/store/**" = "allow";
      };
      skill = {
        "lean4" = "deny";
      };
    };
    # tools = lib.mapAttrs' (
    #   name: server: lib.nameValuePair "${name}_*" false
    # ) config.programs.mcp.servers;
  };

  programs.opencode.settings.agent = {
    plan = {
      model = "opencode-go/minimax-m2.5";
      temperature = 0.3;
      reasoningEffort = "high";
      textVerbosity = "low";
    };
    build = {
      model = "opencode-go/minimax-m2.5";
      temperature = 0.3;
      reasoningEffort = "high";
      textVerbosity = "low";
    };
    coder = {
      model = "opencode-go/deepseek-v4-flash";
      temperature = 0.2;
      reasoningEffort = "high";
      textVerbosity = "low";
    };
    explore = {
      model = "opencode-go/qwen3.5-plus";
      temperature = 0.2;
      reasoningEffort = "low";
      textVerbosity = "low";
    };
    researcher = {
      model = "opencode-go/deepseek-v4-flash";
      temperature = 0.4;
      reasoningEffort = "high";
      textVerbosity = "medium";
    };
    scribe = {
      model = "opencode-go/deepseek-v4-flash";
      temperature = 1.0;
      reasoningEffort = "low";
      textVerbosity = "high";
    };
    reviewer = {
      model = "opencode-go/deepseek-v4-pro";
      temperature = 0.1;
      reasoningEffort = "high";
      textVerbosity = "medium";
    };
  };

  # programs.opencode.skills = {
  #   lean4 = "${pkgs.lean4-skills-src}/plugins/lean4/skills/lean4";
  #   nixos = ./skills/nixos.md;
  # };

  imports = [ ./ocx.nix ];

  programs.opencode.web = {
    enable = true;
    extraArgs = [
      "--hostname"
      "0.0.0.0"
      "--port"
      "4096"
    ];
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
      ocw = "${oc} web --hostname 0.0.0.0 --port 4096";
    };
  };
}
