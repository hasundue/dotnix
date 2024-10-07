{ pkgs, ... }:

{
  xdg = {
    enable = true;
    portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];
      config.common.default = [ "wlr" "gtk" ];
    };
    mimeApps = {
      enable = true;
      defaultApplications = {
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
      };
    };
    userDirs = {
      enable = true;
      desktop = "$HOME/opt";
      documents = "$HOME/doc";
      download = "$HOME/tmp";
      music = "$HOME/mus";
      pictures = "$HOME/img";
      publicShare = "$HOME/opt";
      templates = "$HOME/opt";
      videos = "$HOME/vid";
    };
  };
}

