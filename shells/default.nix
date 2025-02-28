{ pkgs, lib, ... } @ args:

let
  aliases = rec {
    nr = "sudo nixos-rebuild --flake .";
    nrb = "${nr} boot |& nom";
    nrs = "${nr} switch |& nom";
    nrt = "${nr} test |& nom";
  };
in
pkgs.mkShellNoCC {
  packages = (lib.mapAttrsToList pkgs.writeAliasBin aliases);
  inputsFrom = [ (import ./nix.nix args) ];
}
