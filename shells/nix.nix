{ pkgs, neovim-flake, ... }:

let
  neovim = neovim-flake.mkNeovim {
    modules = with neovim-flake; [
      core
      clipboard
      copilot
      nix
    ];
  };
in
{
  aliases = rec {
    nf = "nix flake";
    nfc = "${nf} check";
    nfs = "${nf} show";
    nfu = "${nf} update";

    nr = "sudo nixos-rebuild --flake .";
    nrb = "${nr} boot |& nom";
    nrs = "${nr} switch |& nom";
    nrt = "${nr} test |& nom";

    nv = "nvim";
  };

  packages = with pkgs; [
    cachix
    neovim
    nix-output-monitor
  ];
}
