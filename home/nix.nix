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

      nr = "nix run";

      ns = "nix search nixpkgs";
    };
  };
}
