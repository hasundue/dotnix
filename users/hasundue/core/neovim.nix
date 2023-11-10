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
}
