{ pkgs, ... }:

{
  programs.git.settings.core.editor = "nvim";

  home = {
    packages = [ pkgs.nvim.packages.default ];
    shellAliases = {
      nv = "nvim";
    };
    sessionVariables.EDITOR = "nvim";
  };
}
