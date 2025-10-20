{ ... }:

{
  programs.opencode = {
    enable = true;
    settings = {
      theme = "kanagawa-transparent";
      autoupdate = false;
    };
  };

  home.shellAliases = rec {
    oc = "opencode";
    occ = "${oc} --continue";
  };

  xdg.configFile."opencode/themes/kanagawa-transparent.json".source =
    ./theme-kanagawa-transparent.json;
}
