{ firefox-addons, ... }: 

{
  programs.firefox = {
    enable = true;

    profiles = {
      default = {
        id = 0;
        settings = {
          "media.ffmpeg.vaapi.enabled" = true;
        };
        extensions = with firefox-addons; [
          darkreader
          ublock-origin
        ];
      };
      debug.id = 99;
    };
  };
}
