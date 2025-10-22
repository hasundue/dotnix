{ lib, ... }:

{
  programs.opencode = {
    enable = true;

    settings = {
      theme = "stylix";
      autoupdate = false;
    };

    themes.stylix.theme.background = {
      dark = lib.mkForce "none";
      light = lib.mkForce "none";
    };
  };

  home.shellAliases = rec {
    oc = "opencode";
    occ = "${oc} --continue";
  };
}
