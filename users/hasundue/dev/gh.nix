{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-copilot
    ];
  };

  home.shellAliases = {
    ce = "gh copilot explain";
    cs = "gh copilot suggest";
  };
}
