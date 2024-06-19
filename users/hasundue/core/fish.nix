{ pkgs, ... }:

{
  programs.fish = {
    enable = true;
    plugins = [
      { name = "autopair"; inherit (pkgs.fishPlugins.autopair) src; }
    ];
    shellInit = ''
      source ${pkgs.vimPlugins.kanagawa-nvim}/extras/kanagawa.fish
    '';
  };
}
