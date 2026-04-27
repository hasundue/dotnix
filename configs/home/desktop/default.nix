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
    ./zed
  ];

  home = {
    packages = with pkgs; [
      # apps
      discord
      google-chrome
      zotero

      # desktop
      adwaita-icon-theme # For input-keyboard-symbolic
      hicolor-icon-theme
      qt5.qtwayland
      qt6.qtwayland

      # tools
      slurp
      thunar
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
      events = {
        "before-sleep" = "${pkgs.swaylock}/bin/swaylock -fF";
      };
      timeouts = [
        {
          timeout = 3600;
          command = "${pkgs.systemd}/bin/systemctl suspend";
        }
      ];
    };
  };
}
