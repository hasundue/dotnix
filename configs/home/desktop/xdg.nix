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

    # The pi-gpui package ships the `.desktop` entry that declares
    # `x-scheme-handler/pi-gpui`, but the association itself has to be recorded
    # somewhere. `xdg.mimeApps` would make ~/.config/mimeapps.list a store link,
    # and the browsers write to that file when one of them becomes the default.
    # The legacy user-level list under $XDG_DATA_HOME is consulted for the keys
    # the config one does not have, so only this association lives there.
    dataFile."applications/mimeapps.list".text = ''
      [Default Applications]
      x-scheme-handler/pi-gpui=pi-gpui.desktop
    '';
  };
}
