{ pkgs, ... }:

{
  programs.git.extraConfig.core.editor = "nvim";

  home = {
    packages = [ pkgs.nvim.pkgs.default ];
    shellAliases = {
      nv = "nvim";
    };
    sessionVariables.EDITOR = "nvim";
  };
}
