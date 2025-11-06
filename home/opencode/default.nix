{ lib, ... }:

{
  programs.opencode = {
    enable = true;
    settings = {
      model = "anthropic/claude-sonnet-4-5";
      theme = lib.mkForce "kanagawa-transparent";
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
