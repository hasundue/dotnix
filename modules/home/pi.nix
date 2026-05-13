{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib)
    mkIf
    mkMerge
    mkOption
    nameValuePair
    types
    ;
  inherit (lib.attrsets) filterAttrs mapAttrs' optionalAttrs;
  inherit (lib.strings) removePrefix;

  cfg = config.pi;

  # ---------------------------------------------------------------------------
  # Sub-extension submodule
  # ---------------------------------------------------------------------------

  subExtOptions = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Enable this sub-extension. Set false to opt out.";
    };
    agents = mkOption {
      type = types.attrsOf (types.submodule { options = agentOptions; });
      default = { };
      description = ''
        Agent definitions for this sub-extension (e.g. agent-selection).
        Each key becomes the agent ID (filename) when written to disk.
      '';
    };
  };

  # ---------------------------------------------------------------------------
  # Agent submodule
  # ---------------------------------------------------------------------------

  agentOptions = {
    type = mkOption {
      type = types.enum [
        "main"
        "subagent"
        "both"
      ];
      default = "main";
      description = "Agent type.";
    };
    description = mkOption {
      type = types.str;
      default = "";
      description = "Short description shown in agent lists.";
    };
    model = mkOption {
      type = types.submodule {
        options = {
          id = mkOption {
            type = types.nullOr types.str;
            default = null;
            description = "Model ID in provider/model form (e.g. opencode-go/deepseek-v4-flash).";
          };
          thinking = mkOption {
            type = types.nullOr (
              types.enum [
                "off"
                "minimal"
                "low"
                "medium"
                "high"
                "xhigh"
              ]
            );
            default = null;
            description = "Thinking level.";
          };
        };
      };
      default = { };
      description = "Optional model override for this agent.";
    };
    tools = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Allowed tools (exact names or narrow wildcard patterns).";
    };
    subAgents = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Subagent IDs that this agent may call (YAML field: agents).";
    };
    text = mkOption {
      type = types.str;
      description = "Agent system prompt body (markdown after the YAML frontmatter).";
    };
  };

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  # Derive the per-package config directory from npm package name.
  # Convention: pi-* packages strip the prefix, e.g. pi-agent-suite → agent-suite.
  pkgDir = name: removePrefix "pi-" name;

  # Map extension config key to its storage directory under the package dir.
  # Some extensions use a different directory name for state/agents.
  extStorageDir =
    extName:
    {
      "main-agent-selection" = "agent-selection";
    }
    .${extName} or extName;

  # Build the YAML frontmatter attrset for an agent, omitting null/empty fields
  agentFrontmatter =
    agent:
    {
      type = agent.type;
    }
    // optionalAttrs (agent.description != "") { description = agent.description; }
    // optionalAttrs (agent.model.id != null || agent.model.thinking != null) {
      model = filterAttrs (_: v: v != null) {
        id = agent.model.id;
        thinking = agent.model.thinking;
      };
    }
    // optionalAttrs (agent.tools != [ ]) { tools = agent.tools; }
    // optionalAttrs (agent.subAgents != [ ]) { agents = agent.subAgents; };

  # Generate the full content of one agent .md file
  agentFileContent = agent: "---\n${builtins.toJSON (agentFrontmatter agent)}\n---\n\n${agent.text}";

in
{
  options.pi = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable Pi coding agent configuration.";
    };

    # -------------------------------------------------------------------------
    # packages – npm packages (installable units)
    # -------------------------------------------------------------------------

    packagesDir = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = ''
        Directory containing package.json and package-lock.json for Pi npm packages.
        When set, the module builds all dependencies using importNpmLock.buildNodeModules
        and injects the store paths into the settings packages array.
      '';
    };

    packages = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            enable = mkOption {
              type = types.bool;
              default = true;
              description = "Enable the package. Disabled packages are not added to settings.json.";
            };
            extensions = mkOption {
              type = types.attrsOf (types.submodule { options = subExtOptions; });
              default = { };
              description = ''
                Sub-extension configurations within this package.

                To opt out of a default sub-extension:
                  footer.enable = false;

                To configure agents for agent-selection:
                  agent-selection.agents = { ... };
              '';
            };
          };
        }
      );
      default = { };
      example = {
        pi-agent-suite = {
          extensions = {
            footer.enable = false;
            agent-selection.agents = {
              CodeReview = {
                type = "main";
                description = "Reviews code and checks implementation risks";
                model.id = "opencode-go/deepseek-v4-flash";
                model.thinking = "high";
                tools = [
                  "read"
                  "bash"
                  "edit"
                ];
                text = ''
                  You are a code review agent. Check correctness, risks, and missing validation.
                '';
              };
            };
          };
        };
      };
    };

    extraPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/absolute/path/to/a/pi/package" ];
      description = ''
        Extra absolute paths to add to the settings packages array,
        in addition to those resolved via packages.
      '';
    };

    # -------------------------------------------------------------------------
    # extensions – local extension resource files
    # -------------------------------------------------------------------------

    extensions = mkOption {
      type = types.listOf types.path;
      default = [ ];
      description = ''
        Local extension files or directories. The basename (with .ts suffix)
        is used as the filename under .pi/agent/extensions/.
      '';
    };

    # -------------------------------------------------------------------------
    # Other config
    # -------------------------------------------------------------------------

    settings = mkOption {
      type = types.attrs;
      default = { };
      description = "Additional attributes merged into settings.json (merged after packages).";
    };

    auth = mkOption {
      type = types.attrs;
      default = { };
      description = "Auth providers config written to auth.json.";
    };

    themes = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = [ ./kanagawa-wave.json ];
      description = "Theme files. Each file is placed under themes/ using its filename.";
    };

    skills = mkOption {
      type = types.listOf types.path;
      default = [ ];
      example = [ ./exa-search ];
      description = ''
        Skill directories. Each directory is symlinked under skills/ using its dirname.
        Executable bits of files inside are preserved via the symlink.
      '';
    };

    keybindings = mkOption {
      type = types.attrs;
      default = { };
      description = "Key binding overrides merged into keybindings.json.";
    };

    context = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Content for AGENTS.md. If null, the file is not created.";
    };
  };

  config = mkIf cfg.enable (
    let
      # Build npm packages from the lockfile when packagesDir is set
      npmModules =
        if cfg.packagesDir != null then
          pkgs.importNpmLock.buildNodeModules {
            npmRoot = cfg.packagesDir;
            nodejs = pkgs.nodejs;
          }
        else
          null;

      piNpmPkg = name: "${npmModules}/node_modules/${name}";

      # -----------------------------------------------------------------------
      # Enabled packages
      # -----------------------------------------------------------------------

      # Read dependency names from package.json for auto-discovery
      lockDeps =
        if cfg.packagesDir != null then
          let
            pkgJson = builtins.fromJSON (builtins.readFile (toString cfg.packagesDir + "/package.json"));
          in
          builtins.attrNames (pkgJson.dependencies or { })
        else
          [ ];

      # Auto-include lockfile packages with defaults
      defaultPkgs = builtins.listToAttrs (
        map (
          name:
          nameValuePair name {
            enable = true;
            extensions = { };
          }
        ) lockDeps
      );

      # Merge user overrides on top of auto-included defaults.
      # cfg.packages only contains keys the user explicitly wrote.
      allPkgConfigs = defaultPkgs // cfg.packages;

      # Enabled packages
      enabledPkgs = filterAttrs (_: pkg: pkg.enable) allPkgConfigs;

      # Produce a patched package directory: symlink the original contents,
      # overwrite package.json with filtered pi.extensions, and symlink the
      # original node_modules root so require() resolves correctly.
      patchPackage =
        name: disabledExts:
        if disabledExts == [ ] then
          piNpmPkg name
        else
          pkgs.runCommand "${name}-patched"
            {
              nativeBuildInputs = [ pkgs.jq ];
            }
            ''
              set -e
              mkdir -p "$out"

              # Symlink original package contents (skip node_modules, we add our own)
              for f in ${npmModules}/node_modules/${name}/*; do
                base=$(basename "$f")
                [ "$base" = "node_modules" ] && continue
                ln -s "$f" "$out/$base"
              done

              # Overwrite package.json with patched version
              rm "$out/package.json"
              cp "${npmModules}/node_modules/${name}/package.json" "$out/package.json"
              chmod u+w "$out/package.json"

              exts='${builtins.toJSON (map (e: "./extensions/${e}/index.ts") disabledExts)}'
              jq --argjson exts "$exts" \
                '.pi.extensions |= map(select(. as $x | $exts | index($x) | not))' \
                "$out/package.json" > "$out/package.json.tmp"
              mv "$out/package.json.tmp" "$out/package.json"

              # Symlink original node_modules so extensions can require() deps
              ln -s "${npmModules}/node_modules" "$out/node_modules"
            '';

      resolvePkgPath =
        name:
        let
          pkg = allPkgConfigs.${name};
          disabledExts = builtins.attrNames (filterAttrs (_: ext: !ext.enable) pkg.extensions);
        in
        if disabledExts == [ ] then piNpmPkg name else "${patchPackage name disabledExts}";

      pkgStorePaths = map resolvePkgPath (builtins.attrNames enabledPkgs);

      # All packages: store paths + extra paths
      allPackages = pkgStorePaths ++ cfg.extraPackages;

      # -----------------------------------------------------------------------
      # home.file helpers
      # -----------------------------------------------------------------------

      piFile = name: ".pi/agent/${name}";

      resourceEntries =
        prefix: resources:
        mapAttrs' (
          name: source:
          nameValuePair (piFile "${prefix}/${name}") (
            if builtins.isPath source || builtins.isString source then
              { source = builtins.toString source; }
            else
              source
          )
        ) resources;

      # -----------------------------------------------------------------------
      # Agent .md files
      # Iterate enabled packages → enabled sub-extensions with agents
      # -----------------------------------------------------------------------

      agentFiles = builtins.foldl' (
        acc: pkgName:
        let
          pkg = enabledPkgs.${pkgName};
          pkgConfigDir = pkgDir pkgName;

          # Sub-extensions that are enabled and have agents defined
          extWithAgents = filterAttrs (_: ext: ext.enable && ext.agents != { }) pkg.extensions;
        in
        acc
        // builtins.foldl' (
          acc2: extName:
          let
            ext = extWithAgents.${extName};
          in
          acc2
          // mapAttrs' (
            agentName: agent:
            nameValuePair (piFile "${pkgConfigDir}/${extStorageDir extName}/agents/${agentName}.md") {
              text = agentFileContent agent;
            }
          ) ext.agents
        ) { } (builtins.attrNames extWithAgents)
      ) { } (builtins.attrNames enabledPkgs);

    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file = mkMerge [
        {
          "${piFile "settings.json"}".text = builtins.toJSON (
            (optionalAttrs (allPackages != [ ]) { packages = allPackages; }) // cfg.settings
          );
        }
        agentFiles
        (optionalAttrs (cfg.context != null) {
          "${piFile "AGENTS.md"}".text = cfg.context;
        })
        (optionalAttrs (cfg.auth != { }) {
          "${piFile "auth.json"}".text = builtins.toJSON cfg.auth;
        })
        (optionalAttrs (cfg.keybindings != { }) {
          "${piFile "keybindings.json"}".text = builtins.toJSON cfg.keybindings;
        })
        (resourceEntries "themes" (
          builtins.listToAttrs (map (f: nameValuePair (baseNameOf (builtins.toString f)) f) cfg.themes)
        ))
        (builtins.listToAttrs (
          map (
            dir: nameValuePair (piFile "skills/${baseNameOf (builtins.toString dir)}") { source = dir; }
          ) cfg.skills
        ))
        (resourceEntries "extensions" (
          builtins.listToAttrs (map (f: nameValuePair (baseNameOf (builtins.toString f)) f) cfg.extensions)
        ))
      ];
    }
  );
}
