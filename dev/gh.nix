{ pkgs, ... }:

{
  programs = {
    gh = {
      enable = true;
      extensions = [
        pkgs.gh-copilot
      ];
    };
    gh-dash.enable = true;
  };

  home.shellAliases = rec {
    ce = "gh copilot explain";
    cs = "gh copilot suggest";
    csg = "${cs} -t git";
    csh = "${cs} -t gh";
    css = "${cs} -t shell";

    ghd = "gh dash";

    ghi = "gh issue";
    ghic = "${ghi} create";
    ghid = "${ghi} develop -c";
    ghil = "${ghi} list";
    ghis = "${ghi} status";
    ghiv = "${ghi} view";
  };
}
