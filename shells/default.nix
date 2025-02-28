{ pkgs, ... } @ args:

let
  aliases = rec {
    nr = "sudo nixos-rebuild --flake .";
    nrb = "${nr} boot |& nom";
    nrs = "${nr} switch |& nom";
    nrt = "${nr} test |& nom";
  };
in
pkgs.mkShellNoCC {
  packages = (pkgs.writeAliasScripts aliases);
  inputsFrom = [ (import ./nix.nix args) ];
}
