# Flake apps: nixos-rebuild wrappers and home-manager build/activate.
# `pkgs` is expected to carry the flake's overlays (see `apps` in ../flake.nix).
{
  pkgs,
  username,
}:
let
  # Flags recommended by nix-output-monitor for pretty human output
  nomOpts = "--log-format internal-json -v";

  # Run a nixos-rebuild action as the nixos-{test,switch,boot} apps. The
  # toplevel already includes home-manager (used as a NixOS module), so one
  # build covers both; activation updates the system profile, so rollback
  # keeps working.
  #
  # No nom here: its only useful input is the build's internal-json stream, and
  # its status ticker repaints (and clears) the current line every second,
  # which would erase sudo's password prompt during activation. The *-build
  # apps keep nom.
  #
  # Elevation: as a normal user --elevate=sudo lets ng elevate only the
  # activation commands. Under `sudo nix run` no flag is passed, so ng neither
  # warns nor asks for the password a second time
  # (--ask-elevate-password has no root check in ng and would always prompt).
  nixosApp =
    action:
    pkgs.writeShellScriptBin "nixos-${action}" ''
      set -euo pipefail
      args=(--flake '.#'$(hostname))
      if [ "$(id -u)" -ne 0 ]; then
        args+=(--elevate=sudo)
      fi
      exec nixos-rebuild ${action} "''${args[@]}" "$@"
    '';

in
{
  # Build only, for inspection (no sudo; leaves ./result-home)
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

  # Build and activate the home-manager generation (no sudo). The same command
  # the `hms` alias runs, so there is no pre-built generation to activate by
  # mistake.
  "home-switch" = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "home-switch" ''
      set -euo pipefail
      flake=".#${username}@$(hostname)"
      if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
        exec ${pkgs.home-manager}/bin/home-manager \
          ${nomOpts} switch --flake "$flake" "$@" \
          2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
      else
        exec ${pkgs.home-manager}/bin/home-manager switch --flake "$flake" "$@"
      fi
    ''}/bin/home-switch";
  };

  # Activate from the checkout this app runs in, and point the live tree at it.
  # `DOTNIX_LIVE_ROOT` is read by the activation hook, not by the evaluation,
  # so the build stays pure and cached: the live root never enters the store.
  #
  # The root comes from `$PWD` rather than the wrapper's own location, so
  # starting from a subdirectory works. `nix run <path>#home-live` from
  # elsewhere does not: `$PWD` is still the caller's, so `cd` into the checkout
  # first.
  "home-live" = {
    type = "app";
    program = "${pkgs.writeShellScriptBin "home-live" ''
      set -euo pipefail
      root="$(git -C "$PWD" rev-parse --show-toplevel)"
      export DOTNIX_LIVE_ROOT="$root"
      flake="$root#${username}@$(hostname)"
      if [ -t 1 ] && [ -z "''${NOM_DISABLE:-}" ]; then
        exec ${pkgs.home-manager}/bin/home-manager \
          ${nomOpts} switch --flake "$flake" "$@" \
          2>&1 | ${pkgs.nix-output-monitor}/bin/nom --json
      else
        exec ${pkgs.home-manager}/bin/home-manager switch --flake "$flake" "$@"
      fi
    ''}/bin/home-live";
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
}
