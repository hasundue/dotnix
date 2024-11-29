{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      set -g fish_greeting
    '';
    plugins = [
      { name = "autopair"; inherit (pkgs.fishPlugins.autopair) src; }
    ];
    shellInit = ''
      source ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.fish
    '';
  };
}
