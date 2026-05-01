{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cachix
    home-manager
    hydra-check
    nix-output-monitor
  ];
  home.shellAliases =
    let
      opts = "--log-format internal-json -v";
      pipeToNom = ". &| nom --json";
    in
    rec {
      hc = "hydra-check --short --channel nixos-unstable";
      hm = "home-manager";
      hms = "${hm} ${opts} switch -b backup --flake ${pipeToNom}";
      nd = "nom develop";
      nf = "nix flake";
      nfc = "${nf} check";
      nfs = "${nf} show";
      nfu = "${nf} update";
      nor = "sudo nixos-rebuild";
      nors = "${nor} ${opts} switch --flake ${pipeToNom}";
      nort = "${nor} ${opts} test --flake . ${pipeToNom}";
      nr = "nix run";
    };
}
