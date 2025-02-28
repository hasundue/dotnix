{ pkgs, ... } @ args:

let
  home = (import ../home/nix.nix args).home;
in
pkgs.mkShellNoCC {
  packages = home.packages ++ (pkgs.writeAliasScripts home.shellAliases);
}
