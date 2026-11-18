{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkOption types;

  # Activation runs with a PATH of store paths only, which does not include
  # git. Name it outright so the report does not silently degrade to
  # "unknown" on every activation.
  git = lib.getExe pkgs.git;

  # Only enabled features need a checkout on disk.
  enabled = lib.filterAttrs (_: feature: feature.enable) config.dotnix.live;

  # The check runs before `writeBoundary`, the link update after it, so a
  # failure leaves the previous checkout live rather than a half-written home.
  # Home Manager's activation is not transactional either way; this at least
  # keeps the live tree on the generation that stayed active.
  #
  # Placement matters twice: the existence guard must come before anything is
  # written (`builtins.pathExists` cannot see out-of-store paths during
  # evaluation, and `types.path.check` does not look at the filesystem), while
  # the link itself is what consumers resolve, so it only needs to be right by
  # the end of the run.
  checks = lib.concatStrings (
    lib.mapAttrsToList (
      name: feature:
      let
        stable = lib.escapeShellArg feature.stable;
      in
      ''
        __dotnix_root="''${DOTNIX_LIVE_ROOT:-${feature.root}}"
        __dotnix_dir="$__dotnix_root/${feature.path}"
        [ -d "$__dotnix_dir" ] || {
          echo "error: dotnix.live.${name}.enable = true but $__dotnix_dir is missing." >&2
          echo "  fix: check out the repository there, set dotnix.live.${name}.root, or disable it." >&2
          exit 1
        }
        if [ -e ${stable} ] && [ ! -L ${stable} ]; then
          echo "error: ${stable} exists and is not a symlink, so dotnix.live.${name} cannot point it anywhere." >&2
          echo "  fix: move that file out of the way, or disable dotnix.live.${name}." >&2
          exit 1
        fi
      ''
    ) enabled
  );

  # `DOTNIX_LIVE_ROOT` moves the live tree to the checkout that was activated,
  # and activation is the only place that can read it: this home configuration
  # cannot be evaluated impurely, and a pure evaluation cannot read the
  # environment at all.
  links = lib.concatStrings (
    lib.mapAttrsToList (
      name: feature:
      let
        stable = lib.escapeShellArg feature.stable;
      in
      ''
        __dotnix_root="''${DOTNIX_LIVE_ROOT:-${feature.root}}"
        __dotnix_dir="$__dotnix_root/${feature.path}"
        if [ -z "''${DRY_RUN:-}" ]; then
          ln --force --no-target-directory --symbolic "$__dotnix_dir" ${stable}
        fi
        echo "dotnix.live.${name} -> $__dotnix_dir"
        if ${git} -C "$__dotnix_root" rev-parse -q --verify HEAD > /dev/null; then
          __dotnix_branch="$(${git} -C "$__dotnix_root" symbolic-ref -q --short HEAD || ${git} -C "$__dotnix_root" rev-parse --short HEAD)"
          __dotnix_dirty="$(${git} -C "$__dotnix_root" status --porcelain | wc -l)"
          echo "  branch: $__dotnix_branch, $__dotnix_dirty dirty path(s)"
        else
          echo "  branch: unknown (not a git checkout)"
        fi
        echo "  home-switch returns it to ${feature.root}"
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
              # A static default keeps the checkout out of the evaluation; the
              # activation hook reads `DOTNIX_LIVE_ROOT` around it, which is
              # how `home-live` moves the live tree. Leaving the variable unset
              # -- `home-switch`, `home-build`, `nixos-*` -- keeps this value.
              default = "${config.home.homeDirectory}/dotnix";
              defaultText = lib.literalExpression ''"''${config.home.homeDirectory}/dotnix"'';
              description = ''
                Checkout that provides the live files, when
                {env}`DOTNIX_LIVE_ROOT` is unset at activation time.
              '';
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
    home.activation.dotnixLiveLink = lib.hm.dag.entryAfter [ "writeBoundary" ] links;
  };
}
