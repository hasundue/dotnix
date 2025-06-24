{
  pkgs,
  lib,
  inputs,
  ...
}@args:

let
  aliases = rec {
    nr = "sudo nixos-rebuild --flake .";
    nrb = "${nr} boot |& nom";
    nrs = "${nr} switch |& nom";
    nrt = "${nr} test |& nom";
  };

  treefmt = (inputs.treefmt-nix.lib.evalModule pkgs ../treefmt.nix).config.build.wrapper;

  pre-commit = inputs.git-hooks.lib.${pkgs.system}.run {
    src = ../.;
    hooks = {
      treefmt = {
        enable = true;
        package = treefmt;
      };
    };
  };
in
pkgs.mkShellNoCC {
  packages = (pkgs.writeAliasScripts aliases) ++ [ treefmt ];
  inputsFrom = [ (import ./nix.nix args) ];
  shellHook = pre-commit.shellHook;
}
