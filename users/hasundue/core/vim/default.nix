{ lib, pkgs, vim-plugins, ... }:

{
  programs.vim = {
    enable = true;
    extraConfig = lib.readFile ./vimrc;
    packageConfigurable = pkgs.vim;
  };

  home = {
    file = {
      ".vim/rc".source = ./rc;
    };
    shellAliases = {
      vim = "vim --noplugin";
    };
  };

  stylix.targets.vim.enable = false;

  xdg.dataFile = lib.mapAttrs'
    (name: value: lib.nameValuePair
      ("vim/plugins/" + name)
      { source = value; })
    (lib.filterAttrs
      (name: value: name != "nixpkgs" && name != "_type" && name != "self")
      vim-plugins);
}
