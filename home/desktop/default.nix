{ pkgs, ... }:

{
  imports = [
    ./chromium.nix
    ./fcitx5
    ./firefox.nix
    ./foot.nix
    ./sway.nix
    ./vscode.nix
    ./waybar.nix
    ./xdg.nix
  ];

  home = {
    packages = with pkgs; [
      # communication
      slack
      discord

      # desktop
      gammastep
      hicolor-icon-theme
      qt5.qtwayland
      qt6.qtwayland
      xfce.thunar

      # entertainment
      spotify

      # tools
      grim
      slurp
      wl-clipboard
      xdg-utils
    ];

    sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    };
  };

  gtk = {
    enable = true;
    gtk2.extraConfig = "gtk-application-prefer-dark-theme = true";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-hint-font-metrics = true;
  };

  services = {
    gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 5500;
        night = 4500;
      };
      tray = true;
    };
  };
}
