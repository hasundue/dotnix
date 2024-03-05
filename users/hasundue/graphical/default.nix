{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix
    ./chromium.nix
  ];

  home = {
    packages = with pkgs; [
      # communication
      slack
      telegram-desktop
      zoom-us
      discord

      # entertainment
      spotify

      # desktop
      gammastep
      hicolor-icon-theme
      qt5.qtwayland
      qt6.qtwayland

      # tools
      grim
      slurp
      wl-clipboard
      xdg-utils
    ];

    sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
      # Set the default IME to fcitx 
      GLFW_IM_MODULE = "ibus";
      GTK_IM_MODULE = "fcitx";
      QT_IM_MODULE = "fcitx";
      XMODIFIERS = "@im=fcitx";
    };
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc fcitx5-gtk ];
  };

  gtk = {
    enable = true;
    gtk2.extraConfig = "gtk-application-prefer-dark-theme = true";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
    gtk4.extraConfig.gtk-hint-font-metrics = true;
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
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

  stylix = {
    image = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/a/a5/Tsunami_by_hokusai_19th_century.jpg";
      hash = "sha256-MMFwJg3jk/Ub1ZKtrMbwcUtg8VfAl0TpxbbUbmphNxg=";
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.95;
    };
    targets = {
      gtk.enable = true;
    };
  };
}
