{ pkgs, lib, neovim-flake, ... }:

let
  aliases = lib.mapAttrsToList
    (name: value: "alias ${name}='${value}'")
    rec {
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

  neovim = neovim-flake.neovim {
    modules = with neovim-flake; [
      core
      clipboard
      copilot
      nix
    ];
  };
in
{
  packages = with pkgs; [
    cachix
    neovim
    nix-output-monitor
  ];

  shellHook = lib.concatStringsSep "\n" aliases;
}
