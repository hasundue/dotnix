# Per-package module for @juicesharp/rpiv-pi.
#
# Builds a patched copy of rpiv-pi that injects `model: opencode-go/deepseek-v4-flash`
# into every bundled agent .md file's YAML frontmatter. The patched derivation is
# injected via pi.extraPackages; the user must disable the original auto-discovered
# package in configs/home/pi/default.nix:
#
#   pi.packages."@juicesharp/rpiv-pi".enable = false;

{
  config,
  pkgs,
  lib,
  ...
}:

let
  inherit (lib) mkIf;

  cfg = config.pi;

  # Rebuild node_modules (same as default.nix — guaranteed Nix cache hit)
  npmModules =
    if cfg.packagesDir != null then
      pkgs.importNpmLock.buildNodeModules {
        npmRoot = cfg.packagesDir;
        nodejs = pkgs.nodejs;
      }
    else
      null;

  rpivPiOrig = if npmModules != null then "${npmModules}/node_modules/@juicesharp/rpiv-pi" else null;

  # Patched derivation: symlink original, replace agents/ with model-pinned copies
  rpivPiPatched =
    if rpivPiOrig != null then
      pkgs.runCommand "rpiv-pi-patched" { } ''
        set -e
        mkdir -p "$out"

        # Symlink original package contents (skip node_modules, agents, and extensions)
        for f in ${rpivPiOrig}/*; do
          base=$(basename "$f")
          [ "$base" = "node_modules" ] && continue
          [ "$base" = "agents" ] && continue
          [ "$base" = "extensions" ] && continue
          ln -s "$f" "$out/$base"
        done

        # Copy extensions/ so import.meta.url resolves to the patched store path.
        # agents.ts resolves PACKAGE_ROOT from its own file URL via
        # dirname(dirname(dirname(thisFile))). Symlinks would follow-through to
        # the original store, making syncBundledAgents() read unpatched agent
        # files. A real copy keeps the resolution inside the patched path.
        cp -r --no-preserve=mode ${rpivPiOrig}/extensions "$out/extensions"
        chmod -R u+w "$out/extensions"

        # Create agents/ with patched copies — insert model: after opening ---
        mkdir "$out/agents"
        for f in ${rpivPiOrig}/agents/*; do
          base=$(basename "$f")
          cp --no-preserve=mode "$f" "$out/agents/$base"
          if [[ "$base" == *.md ]]; then
            sed -i '1a\model: opencode-go/deepseek-v4-flash' "$out/agents/$base"
          fi
        done

        # Symlink original node_modules so require() resolves correctly
        ln -s "${npmModules}/node_modules" "$out/node_modules"
      ''
    else
      null;

in
{
  config = mkIf (cfg.enable && cfg.packagesDir != null) {
    pi.extraPackages = [ "${rpivPiPatched}" ];
  };
}
