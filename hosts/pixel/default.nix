{ pkgs, ... }:

{
  imports = [
    ../../nixos
  ];

  terminal.font = "${pkgs.nerd-fonts.caskaydia-cove}/fonts/ttf/CaskaydiaCove-Regular.ttf";
}
