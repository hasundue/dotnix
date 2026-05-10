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
    mkEnableOption
    mkOption
    nameValuePair
    types
    ;
  inherit (lib.attrsets) mapAttrs' optionalAttrs;

  cfg = config.pi;
in
{
  options.pi = {
    enable = mkEnableOption "Pi coding agent configuration";

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
      type = types.listOf types.str;
      default = [ ];
      example = [ "pi-mcp-adapter" ];
      description = ''
        Npm package names to expose as Pi packages.
        Each name must be declared as a dependency in packagesDir/package.json.
      '';
    };

    extraPackages = mkOption {
      type = types.listOf types.str;
      default = [ ];
      example = [ "/absolute/path/to/a/pi/package" ];
      description = ''
        Extra absolute paths to add to the settings packages array,
        in addition to those resolved via packagesDir.
      '';
    };

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

    extensions = mkOption {
      type = types.attrsOf (types.either types.path types.attrs);
      default = { };
      description = ''
        Extension resources as { name = source; }.
        Source can be a path or an attrset with `source` and optionally `executable`.
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

      # Collect all packages: resolved npm packages + extra paths
      allPackages = (map piNpmPkg cfg.packages) ++ cfg.extraPackages;

      # Prefix resources under .pi/agent/
      piFile = name: ".pi/agent/${name}";

      # Build home.file entries for a collection of resources
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
    in
    {
      home.packages = [ pkgs.llm-agents.pi ];

      home.file = mkMerge [
        {
          "${piFile "settings.json"}".text = builtins.toJSON (mkMerge [
            (optionalAttrs (allPackages != [ ]) { packages = allPackages; })
            cfg.settings
          ]);
        }
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
        (resourceEntries "extensions" cfg.extensions)
      ];
    }
  );
}
