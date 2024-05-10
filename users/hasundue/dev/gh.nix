{ pkgs, ... }:

{
  programs.gh = {
    enable = true;
    extensions = [
      pkgs.gh-copilot
    ];
  };

  home.shellAliases = rec {
    ce = "gh copilot explain";
    cs = "gh copilot suggest";
    csg = "${cs} -t git";
    csh = "${cs} -t gh";
    css = "${cs} -t shell";
  };
}
