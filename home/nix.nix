{ pkgs, ... }:

{
  home = {
    packages = with pkgs; [
      cachix
      nix-output-monitor
    ];

    shellAliases = rec {
      nd = "nom develop";

      nf = "nix flake";
      nfc = "${nf} check";
      nfs = "${nf} show";
      nfu = "${nf} update";

      nor = "sudo nixos-rebuild --flake .";
      norb = "${nr} boot |& nom";
      nors = "${nr} switch |& nom";
      nort = "${nr} test |& nom";

      nr = "nix run";
    };
  };
}
