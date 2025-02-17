{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;

    profiles = {
      default = {
        id = 0;
        settings = {
          "media.ffmpeg.vaapi.enabled" = true;
        };
        extensions.packages = with pkgs.firefox-addons; [
          darkreader
          ublock-origin
        ];
      };
      debug.id = 99;
    };
  };
}
