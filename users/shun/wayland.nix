{ pkgs, ... }: 

{
  wayland.windowManager.sway = {
    enable = true;
    config = {
      bars = [{
        statusCommand = "i3status";
      }];
      floating = {
        criteria = [
          { title = "1Password"; }
          { title = "Alby"; }
          { title = "Steam"; }
        ];
      };
      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 10;
      };
      input = {
        "type:keyboard" = {
          xkb_options = "ctrl:nocaps";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
      };
      menu = "tofi-run | xargs swaymsg exec env NIXOS_OZONE_WL=1 --";
      output = {
        "AU Optronics 0x313D Unknown" = {
          scale = "1.2";
          scale_filter = "nearest";
        };
        "Microstep MSI G271 0x30303146" = {
          mode = "1920x1080@120Hz";
        };
        "*" = {
          subpixel = "rgb";
          background = "#3c3836 solid_color";
        };
      };
      fonts = {
        names = [ "FiraCode Nerd Font" ];
        style = "Bold";
        size = 10.0;
      };
      modifier = "Mod4";
      startup = [
        { command = "wl-paste -t text --watch clipman store"; }
      ];
      terminal = "alacritty";
      window = {
        titlebar = false;
      };
    };
    extraConfig = ''
      bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bindsym XF86MonBrightnessUp exec brightnessctl set +10%
      bindsym XF86MonBrightnessDown exec brightnessctl set 10%-
    '';
    wrapperFeatures.gtk = true;
  };

  programs.waybar = {
    enable = true;
  };

  programs.i3status.enable = true;

  gtk = {
    enable = true;
    font = {
      name = "Source Han Sans";
      size = 10;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
      gtk-xft-antialias = 1;
      gtk-xft-hinting = 1;
      gtk-xft-hintstyle = "slight";
      gtk-xft-rgba = "rgb";
    };
    theme = {
      name = "Nordic-darker";
      package = pkgs.nordic;
    };
    cursorTheme = {
      name = "Nordzy-cursors";
    };
  };

  home.pointerCursor = {
    name = "Nordzy-cursors";
    package = pkgs.nordzy-cursor-theme;
    gtk.enable = true;
  };

  qt = {
    enable = true;
    platformTheme = "gtk";
  };

  services.clipman.enable = true;
}
