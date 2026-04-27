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
    hm = "home-manager --log-format internal-json -v";
    hms = "${hm} switch -b backup --flake . &| nom --json";
    nd = "nom develop";
    nf = "nix flake";
    nfc = "${nf} check";
    nfs = "${nf} show";
    nfu = "${nf} update";
    nor = "sudo nixos-rebuild --log-format internal-json -v";
    nors = "${nor} switch --flake . &| nom --json";
    nort = "${nor} test --flake . &| nom --json";
    nr = "nix run";
  };
}
