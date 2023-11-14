{ lib, pkgs, neovim-plugins, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    withNodeJs = false;
    withPython3 = false;
    withRuby = false;

    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;
  };

  programs.git.extraConfig.core.editor = "nvim";

  home.shellAliases = {
    nv = "nvim";
  };

  xdg.configFile = {
    "nvim/init.lua".source = ./init.lua;
    "nvim/lua".source = ./lua;
    "nvim/rc".source = ./rc;
  };

  xdg.dataFile = lib.mapAttrs'
    (name: value: lib.nameValuePair
      ("nvim/plugins/" + name)
      { source = value; }
    )
    neovim-plugins.repos;
}
