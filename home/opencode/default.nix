{ ... }:

{
  programs.opencode = {
    enable = true;
    settings = {
      theme = "kanagawa-transparent";
      autoupdate = false;
    };
  };

  xdg.configFile."opencode/themes/kanagawa-transparent.json".source =
    ./theme-kanagawa-transparent.json;
}
