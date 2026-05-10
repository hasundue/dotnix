{
  config,
  pkgs,
  lib,
  ...
}:

let
  opencodeGoKeyPath = config.age.secrets."api/opencode-go".path;
  exaKeyFile = config.age.secrets."api/exa".path;

  # Build all npm pi packages from the lockfile into the Nix store
  npmPkgs = pkgs.importNpmLock.buildNodeModules {
    npmRoot = ./.;
    nodejs = pkgs.nodejs;
  };

  # Helper: resolve a pi package's directory inside the store
  piPkg = name: "${npmPkgs}/node_modules/${name}";
in
{
  home.packages = [ pkgs.llm-agents.pi ];

  home.sessionVariables = {
    EXA_API_KEY_FILE = exaKeyFile;
  };

  home.file =
    lib.mapAttrs'
      (name: value: {
        name = ".pi/agent/${name}";
        inherit value;
      })
      {
        "AGENTS.md".text = ''
          Be conservative about making changes. Unless the user says "edit",
          "write", "modify", "implement", or otherwise clearly indicates they
          want actual modifications, treat their input as theoretical — explain
          feasibility, approach, and trade-offs instead of executing. Prefer to
          ask clarifying questions before editing.
        '';
        "settings.json".text = builtins.toJSON {
          theme = "kanagawa-wave";
          defaultProvider = "opencode-go";
          defaultModel = "deepseek-v4-flash";
          defaultThinkingLevel = "xhigh";
          hideThinkingBlock = true;
          enabledModels = [
            "opencode-go/deepseek-v4-flash"
            "opencode-go/deepseek-v4-pro"
          ];

          # Nix store paths — resolved by the lockfile, fully declarative
          packages = [
            "${piPkg "pi-mcp-adapter"}"
          ];
        };
        "themes/kanagawa-wave.json".source = ./themes/kanagawa-wave.json;
        "auth.json".text = builtins.toJSON {
          opencode-go = {
            type = "api_key";
            key = "!cat ${opencodeGoKeyPath}";
          };
        };
        # "skills/create-skill/SKILL.md".source = ./skills/create-skill/SKILL.md;
        # "skills/create-skill/script.ts".source = ./skills/create-skill/script.ts;
        # "skills/create-skill/SKILL_TEMPLATE.md".source = ./skills/create-skill/SKILL_TEMPLATE.md;
        "skills/exa-search/SKILL.md".source = ./skills/exa-search/SKILL.md;
        "skills/exa-search/search.ts" = {
          source = ./skills/exa-search/search.ts;
          executable = true;
        };
        # "extensions/readonly-mode/index.ts".source = ./extensions/readonly-mode/index.ts;
        # "extensions/toggle-bash/index.ts".source = ./extensions/toggle-bash/index.ts;
        "keybindings.json".text = builtins.toJSON {
          "app.session.rename" = "ctrl+shift+r";
        };
      };
}
