{ pkgs, ... }:

{
  imports = [
    ./alacritty.nix
  ];

  home = {
    packages = with pkgs; [
      # browsers 
      (vivaldi.override {
        proprietaryCodecs = true;
      })
      google-chrome

      # communication
      slack
      zoom-us
      discord

      # entertainment
      spotify

      # desktop
      gammastep
      gnome.adwaita-icon-theme
      gnome.evince
      hicolor-icon-theme
      qgnomeplatform
      qt5.qtwayland
      qt6.qtwayland
    ];

    sessionVariables = {
      QT_AUTO_SCREEN_SCALE_FACTOR = 1;
    };
  };

  gtk = {
    enable = true;
    gtk2.extraConfig = "gtk-application-prefer-dark-theme = true";
    gtk3.extraConfig.gtk-application-prefer-dark-theme = true;
  };

  qt = {
    enable = true;
    platformTheme = "gnome";
    style = {
      name = "adwaita";
      package = pkgs.adwaita-qt;
    };
  };

  services = {
    gammastep = {
      enable = true;
      provider = "geoclue2";
      tray = true;
      settings.general = {
        brightness-day = 1.0;
        brightness-night = 0.4;
      };
    };
  };

  stylix = {
    fonts = {
      sansSerif = {
        package = pkgs.noto-fonts-cjk-sans;
        name = "Noto Sans CJK JP";
      };
      serif = {
        package = pkgs.noto-fonts-cjk-serif;
        name = "Noto Serif CJK JP";
      };
      monospace = {
        package = pkgs.nerdfonts.override { fonts = [ "Hack" ]; };
        name = "Hack Nerd Font";
      };
      emoji = {
        package = pkgs.noto-fonts-emoji;
        name = "Noto Color Emoji";
      };
    };
    image = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/a/a5/Tsunami_by_hokusai_19th_century.jpg";
      hash = "sha256-mgrskDJJ+UKeQLVYZUROHV9tAir0kOwZwtNDkPDpHHE=";
    };
    targets = {
      gnome.enable = true;
      gtk.enable = true;
    };
  };
}
