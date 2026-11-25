{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Styles come from the kanagawa-wave feature; don't override them on the command line.
  commonArgs = "--paging=never";
in
{
  # delta reads bat's compiled theme cache, which Home Manager rebuilds on activation.
  programs.bat = {
    enable = true;
    themes.kanagawa-wave = {
      src = pkgs.kanagawa.bat;
      file = "themes/kanagawa-wave.tmTheme";
    };
  };

  programs.delta = {
    enable = true;
    enableGitIntegration = true;
    options = {
      features = "kanagawa-wave";
      "side-by-side" = "140";
    };
  };

  # delta does not wrap unified diffs; chop long lines in less instead of
  # letting the terminal soft-wrap them over the line-number gutter.
  home.sessionVariables.LESS = "-RS";
  programs.git.iniContent.pager.log = lib.mkForce "less -R";

  # A delta theme is a git config feature, so include the upstream config.
  xdg.configFile."delta/kanagawa-wave.gitconfig".source =
    "${pkgs.kanagawa.delta}/themes/kanagawa-wave.gitconfig";
  programs.git.includes = [
    {
      path = "${config.xdg.configHome}/delta/kanagawa-wave.gitconfig";
    }
  ];

  # Let lazygit wrap diffs itself; without a gutter there is nothing for a
  # soft wrap to cross.
  programs.lazygit.settings.gui.wrapLinesInDiffView = true;

  programs.lazygit.settings.git.diffRenderers = [
    {
      command = "delta --{{colorScheme}} ${commonArgs} --side-by-side=false --line-numbers=false";
    }
  ];

  programs.worktrunk.settings.switch.picker.pager = "delta ${commonArgs} --side-by-side=false";
}
