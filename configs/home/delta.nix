{ config, pkgs, ... }:
let
  kanagawaBat = pkgs.fetchFromGitHub {
    owner = "kanagawa-community";
    repo = "bat";
    rev = "70d2382f6e9679b0b0c36921a198c35961a9507f";
    hash = "sha256-QrHN0FGi7U3B+71EAU1tRIIkiGsen+aeNZLpFF5xmLY=";
  };
  kanagawaDelta = pkgs.fetchFromGitHub {
    owner = "kanagawa-community";
    repo = "delta";
    rev = "27d780d71a6470a0cb138601d4aaa3b6f143c9c0";
    hash = "sha256-NaZmz5DozPKbp4I1CcUmwwxinerZkmckLRdYNBYtCmc=";
  };
  # Styles come from the kanagawa-wave feature; don't override them on the command line.
  commonArgs = "--paging=never";
in
{
  # delta reads bat's compiled theme cache, which Home Manager rebuilds on activation.
  programs.bat = {
    enable = true;
    themes.kanagawa-wave = {
      src = kanagawaBat;
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

  # A delta theme is a git config feature, so include the upstream config.
  xdg.configFile."delta/kanagawa-wave.gitconfig".source =
    "${kanagawaDelta}/themes/kanagawa-wave.gitconfig";
  programs.git.includes = [
    {
      path = "${config.xdg.configHome}/delta/kanagawa-wave.gitconfig";
    }
  ];

  # Let lazygit scroll long diff lines horizontally instead of soft-wrapping
  # them across delta's line-number gutter.
  programs.lazygit.settings.gui.wrapLinesInDiffView = false;

  programs.lazygit.settings.git.diffRenderers = [
    {
      command = "delta --{{colorScheme}} ${commonArgs} --side-by-side={{if gt .width 140}}true{{else}}false{{end}}";
    }
  ];

  programs.worktrunk.settings.switch.picker.pager = "delta ${commonArgs} --side-by-side=false";
}
