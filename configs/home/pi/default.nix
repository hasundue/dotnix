{ pkgs, ... }:

{
  home.packages = [ pkgs.pi-coding-agent ];

  home.file = {
    ".pi/agent/settings.json".text = builtins.toJSON {
      theme = "kanagawa-wave";
    };
    ".pi/agent/themes/kanagawa-wave.json".source = ./themes/kanagawa-wave.json;
  };
}
