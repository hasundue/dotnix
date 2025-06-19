{ pkgs, ... }:

{
  programs.git.extraConfig.core.editor = "nvim";

  home = {
    packages = [ pkgs.nvim.pkgs.nix ];
    shellAliases = {
      nv = "nvim";
    };
    sessionVariables.EDITOR = "nvim";
  };
}
