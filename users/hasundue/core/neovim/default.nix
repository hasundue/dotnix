{ lib, pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    withNodeJs = false;
    withPython3 = false; withRuby = false;

    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;

    plugins = with pkgs.vimPlugins; [
      # UI
      kanagawa-nvim # colorscheme
    ];
  };

  programs.git.extraConfig.core.editor = "nvim";

  home.shellAliases = {
    nv = "nvim";
  };

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
  };
}
