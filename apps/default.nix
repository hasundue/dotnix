# Flake apps: nixos-rebuild wrappers, home-manager build/activate, and
# opencode. `pkgs` is expected to carry the flake's overlays (see `apps` in
# ../flake.nix).
{
  self,
  lib,
  pkgs,
  username,
}:
let
  # Flags recommended by nix-output-monitor for pretty human output
  nomOpts = "--log-format internal-json -v";

  # Run a nixos-rebuild action as the nixos-{test,switch,boot} apps. The
  # toplevel already includes home-manager (used as a NixOS module), so one
  # build covers both; activation updates the system profile, so rollback
  # keeps working. Output goes through nom on a TTY, like the *-build apps.
  # Elevation: as a normal user --elevate=sudo lets sudo prompt at activation
  # time (not at all with a warm timestamp or NOPASSWD). Under `sudo nix run`
  # no flag is passed, so ng neither warns nor asks for the password a second
  # time (--ask-elevate-password has no root check in ng and would always
  # prompt).
  nixosApp =
    action:
    pkgs.writeShellScriptBin "nixos-${action}" ''
      set -euo pipefail
      args=(--flake '.#'$(hostname))
      if [ "$(id -u)" -ne 0 ]; then
        args+=(--elevate=sudo)
      fi
      if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
        exec nixos-rebuild ${action} "''${args[@]}" ${nomOpts} "$@" 2>&1 \
          | ${pkgs.nix-output-monitor}/bin/nom --json
      else
        exec nixos-rebuild ${action} "''${args[@]}" "$@"
      fi
    '';

  opencodeConfig =
    let
      homeConfig = self.homeConfigurations."${username}@x1carbon";
      opencodeFiles = lib.mapAttrsToList (name: file: {
        inherit name;
        path = file.source;
      }) (lib.filterAttrs (name: _: lib.hasPrefix "opencode/" name) homeConfig.config.xdg.configFile);
    in
    pkgs.linkFarm "opencode-config" opencodeFiles;
in
{
  # Build home-manager generation (no sudo)
  "home-build" = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "home-build" ''
      set -euo pipefail
      target='.#homeConfigurations."${username}@'"$(hostname)"'".activationPackage'
      if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
        exec nix build "$target" \
          ${nomOpts} "$@" -o result-home 2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
      else
        exec nix build "$target" \
          "$@" -o result-home
      fi
    ''}/bin/home-build";
  };

  # Activate previously built home-manager generation (no sudo)
  "home-switch" = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "home-switch" ''
      set -euo pipefail
      if [ ! -L ./result-home ]; then
        echo "error: no result-home symlink found. Run 'nix run .#home-build' first." >&2
        exit 1
      fi
      exec ./result-home/activate "$@"
    ''}/bin/home-switch";
  };

  # Build NixOS + home-manager (no sudo; leaves ./result)
  "nixos-build" = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "nixos-build" ''
      set -euo pipefail
      if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
        exec nixos-rebuild build --flake '.#'$(hostname) \
          ${nomOpts} "$@" 2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
      else
        exec nixos-rebuild build --flake '.#'$(hostname) "$@"
      fi
    ''}/bin/nixos-build";
  };

  # Switch to the new toplevel
  "nixos-switch" = {
    type = "app";
    program = "${nixosApp "switch"}/bin/nixos-switch";
  };

  # Test the new toplevel without making it the default
  "nixos-test" = {
    type = "app";
    program = "${nixosApp "test"}/bin/nixos-test";
  };

  # Set the boot entry for the next reboot
  "nixos-boot" = {
    type = "app";
    program = "${nixosApp "boot"}/bin/nixos-boot";
  };

  # Run opencode with ephemeral XDG_CONFIG_HOME from flake-tracked config
  opencode = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "opencode" ''
      export XDG_CONFIG_HOME="$(mktemp -d)"
      cp -rsf "${opencodeConfig}/"* "$XDG_CONFIG_HOME/"
      exec ${pkgs.llm-agents.opencode}/bin/opencode "$@"
    ''}/bin/opencode";
  };
}
