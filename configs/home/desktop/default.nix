{ pkgs, ... }:

{
  imports = [
    ./chromium.nix
    ./fcitx5.nix
    ./firefox.nix
    ./kitty.nix
    ./niri
    ./slack.nix
    ./spotify.nix
    ./vscode.nix
    ./waybar.nix
    ./xdg.nix
  ];

  home = {
    packages = with pkgs; [
      # communication
      discord

      # desktop
      hicolor-icon-theme
      adwaita-icon-theme # For input-keyboard-symbolic
      qt5.qtwayland
      qt6.qtwayland
      xfce.thunar

      # tools
      grim
      slurp
      wl-clipboard
      xdg-utils

      # research
      zotero
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

  programs = {
    swaylock.enable = true;
    fuzzel.enable = true;
  };

  services = {
    gammastep = {
      enable = true;
      provider = "geoclue2";
      temperature = {
        day = 6500;
        night = 4500;
      };
    };

    swayidle = {
      enable = true;
      events = [
        {
          event = "before-sleep";
          command = "${pkgs.swaylock}/bin/swaylock -fF";
        }
      ];
      timeouts = [
        {
          timeout = 3600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };
}
