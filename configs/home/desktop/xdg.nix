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
      createDirectories = true;
    };
  };
}
