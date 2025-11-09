{ pkgs, ... }:

{
  programs.git.settings.core.editor = "nvim";

  home = {
    packages = [ pkgs.nvim.pkgs.default ];
    shellAliases = {
      nv = "nvim";
    };
    sessionVariables.EDITOR = "nvim";
  };
}
