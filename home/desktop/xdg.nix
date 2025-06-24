{ pkgs, ... }:

{
  xdg = {
    enable = true;

    portal = {
      enable = true;
      xdgOpenUsePortal = true;

      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-wlr
      ];

      config.sway = {
        default = [
          "wlr"
          "gtk"
        ];
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
