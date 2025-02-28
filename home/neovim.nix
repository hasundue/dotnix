{ pkgs, ... }:

let
  neovim = pkgs.mkNeovim {
    modules = pkgs.mkNeovim.modules.all;
  };
in
{
  programs.git.extraConfig.core.editor = "nvim";

  home = {
    packages = [ neovim ];
    shellAliases = {
      nv = "nvim";
    };
    sessionVariables.EDITOR = "nvim";
  };
}
