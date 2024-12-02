{ pkgs, ... }:

{
  home.shellAliases = {
    nd = "nom develop";
  };

  home.packages = with pkgs; [
    nix-output-monitor
  ];
}
