{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      cachix
      hydra-check
      nix-output-monitor
    ];

    shellAliases = rec {
      hc = "hydra-check --short --channel nixos-unstable";

      nd = "nom develop";
      nf = "nix flake";
      nfc = "${nf} check";
      nfs = "${nf} show";
      nfu = "${nf} update";
      nr = "nix run";
      ns = "nix search nixpkgs";
    };
  };
}
