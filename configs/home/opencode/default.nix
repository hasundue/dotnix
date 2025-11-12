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
