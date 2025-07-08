{
  pkgs,
  lib,
  ...
}@args:

let
  aliases = rec {
    nr = "sudo nixos-rebuild --flake .";
    nrb = "${nr} boot |& nom";
    nrs = "${nr} switch |& nom";
    nrt = "${nr} test |& nom";
  };

  treefmt = lib.treefmt-nix.mkWrapper pkgs {
    programs.nixfmt = {
      enable = true;
    };
  };

  git-hooks = lib.git-hooks-nix.${pkgs.system}.run {
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
  packages = (pkgs.writeAliasScripts aliases) ++ [
    pkgs.nil
    treefmt
  ];
  inputsFrom = [ (import ./nix.nix args) ];
  shellHook = git-hooks.shellHook;
}
