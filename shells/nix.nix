{ pkgs, ... }:

let
  config = import ../home/nix.nix { inherit pkgs; };
  aliases = config.home.shellAliases;
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    cachix
    nix-output-monitor
  ] ++ (lib.mapAttrsToList pkgs.writeAliasBin aliases);
}
