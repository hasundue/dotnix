{
  config,
  lib,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;

  # Only enabled features need a checkout on disk.
  enabled = lib.filterAttrs (_: feature: feature.enable) config.dotnix.live;

  # Evaluated at activation time. Existence cannot be checked during
  # evaluation: `builtins.pathExists` returns false for out-of-store paths
  # under pure evaluation, and `types.path.check` does not look at the
  # filesystem. This runs before `writeBoundary` so a failed activation leaves
  # the previous generation's links untouched instead of dangling.
  checks = lib.concatStrings (
    lib.mapAttrsToList (
      name: feature:
      let
        dir = "${feature.root}/${feature.path}";
      in
      ''
        [ -d ${lib.escapeShellArg dir} ] || {
          echo "error: dotnix.live.${name}.enable = true but ${dir} is missing." >&2
          echo "  fix: check out the repository there, set dotnix.live.${name}.root, or disable it." >&2
          exit 1
        }
      ''
    ) enabled
  );
in
{
  options.dotnix.live = mkOption {
    default = { };
    description = ''
      Per-feature live configuration sources.

      Each feature gets a stable path at {file}`~/dotnix.live.<name>` that
      points at a checkout when enabled, or at the store copy of the same
      files when disabled. Consumers reference the stable path and never the
      checkout location, so moving a repository or promoting the live copy to
      a separate worktree changes one option and nothing else.
    '';
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            enable = mkEnableOption "live configuration for ${name}";

            root = mkOption {
              # Deliberately `types.str`: interpolating a `types.path` value
              # into a string copies it into the store, which would make the
              # link read-only and defeat the purpose.
              type = types.str;
              default = "${config.home.homeDirectory}/dotnix";
              defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/dotnix"'';
              description = "Checkout that provides the live files.";
            };

            path = mkOption {
              type = types.str;
              default = "configs/home/${name}";
              description = "Directory inside {option}`root` holding the live files.";
            };

            stable = mkOption {
              type = types.str;
              readOnly = true;
              default = "${config.home.homeDirectory}/dotnix.live.${name}";
              description = ''
                Path consumers link to. Resolves to the checkout when
                {option}`enable` is true, and to the store copy otherwise.
              '';
            };
          };
        }
      )
    );
  };

  config = lib.mkIf (enabled != { }) {
    home.activation.dotnixLiveCheck = lib.hm.dag.entryBefore [ "writeBoundary" ] checks;
  };
}
