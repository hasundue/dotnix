{ neovim-flake, ... }:

{
  programs.git.extraConfig.core.editor = "nvim";

  home = {
    packages = [
      (with neovim-flake; mkNeovim {
        modules = [
          core
          clipboard
          copilot
          nix
          lua
        ];
      })
    ];
    sessionVariables.EDITOR = "nvim";
    shellAliases.nv = "nvim";
  };
}
