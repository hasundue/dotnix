{
  config,
  lib,
  pkgs,
  ...
}:
let
  # Styles come from the kanagawa-wave feature; don't override them on the command line.
  commonArgs = "--paging=never";
  pager = "${pkgs.python3}/bin/python3 ${config.xdg.configHome}/delta/pager.py";
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

  # A delta theme is a git config feature, so include the upstream config.
  xdg.configFile."delta/kanagawa-wave.gitconfig".source =
    "${pkgs.kanagawa.delta}/themes/kanagawa-wave.gitconfig";
  programs.git.includes = [
    {
      path = "${config.xdg.configHome}/delta/kanagawa-wave.gitconfig";
    }
  ];

  # Below the side-by-side threshold there is no gutter for a terminal soft
  # wrap to cross, so line numbers are turned off instead.
  xdg.configFile."delta/pager.py" = {
    source = ./delta/pager.py;
    executable = true;
  };
  programs.git.iniContent.pager = {
    diff = lib.mkForce pager;
    show = lib.mkForce pager;
    log = lib.mkForce pager;
  };

  # lazygit captures delta's output, so pass the view width to the wrapper.
  programs.lazygit.settings.git.diffRenderers = [
    {
      command = "${pager} --{{colorScheme}} ${commonArgs} --width={{width}}";
    }
  ];

  programs.worktrunk.settings.switch.picker.pager = "${pager} ${commonArgs}";
}
