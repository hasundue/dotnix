{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cachix
    home-manager
    hydra-check
    nix-output-monitor
  ];
  home.shellAliases = rec {
    hc = "hydra-check --short --channel nixos-unstable";
    hm = "home-manager";
    hms = "${hm} switch -b backup --flake . &| nom";
    nd = "nom develop";
    nf = "nix flake";
    nfc = "${nf} check";
    nfs = "${nf} show";
    nfu = "${nf} update";
    nor = "sudo nixos-rebuild";
    nors = "${nor} switch --flake . &| nom";
    nort = "${nor} test --flake . &| nom";
    nr = "nix run";
  };
}
