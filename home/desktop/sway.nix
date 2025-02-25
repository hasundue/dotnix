{ config, lib, pkgs, ... }:

{
  wayland.windowManager.sway = {
    enable = true;

    config = {
      bars = [ ];

      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 5;
      };

      input = {
        "type:keyboard" = {
          repeat_delay = "250";
          xkb_options = "ctrl:nocaps";
        };
        "type:touchpad" = {
          tap = "enabled";
          natural_scroll = "enabled";
        };
        "type:mouse" = {
          accel_profile = "adaptive";
          pointer_accel = "0.2";
        };
      };

      keybindings =
        let
          Mod = config.wayland.windowManager.sway.config.modifier;
        in
        lib.mkOptionDefault {
          # Function Keys
          "XF86AudioRaiseVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+";
          "XF86AudioLowerVolume" = "exec wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-";
          "XF86AudioMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          "XF86AudioMicMute" = "exec wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
          "XF86MonBrightnessUp" = "exec brightnessctl set +5%";
          "XF86MonBrightnessDown" = "exec brightnessctl set 5%-";
          # Screenshots
          "Print" = "exec grimshot savecopy output";
          "Alt+Print" = "exec grimshot savecopy active";
          "Ctrl+Print" = "exec grimshot savecopy area";
          # Power Management
          "${Mod}+Ctrl+l" = "exec swaylock -fF";
          "${Mod}+Ctrl+s" = "exec systemctl suspend";
        };

      menu = "wofi --show run";

      modifier = "Mod4";

      output = {
        "AU Optronics 0x313D Unknown" = {
          mode = "1920x1080@60Hz";
          position = "0 0";
          scale = "1.25";
        };
        "Microstep MSI G271 0x30303146" = {
          mode = "1920x1080@120Hz";
          position = "1536 0";
        };
      };

      startup = [
        { command = "swaylock -fF"; } # for auto-login
      ];

      terminal = lib.getExe pkgs.alacritty;

      window = {
        commands = [
          {
            command = "resize set 1024 576, move position center";
            criteria = {
              floating = true;
              app_id = "Alacritty";
            };
          }
        ];
        titlebar = false;
      };

      workspaceOutputAssign = [
        { workspace = "1"; output = "eDP-1"; }
      ] ++ map
        (i: { workspace = toString (i); output = "HDMI-A-1"; })
        (builtins.genList (i: i + 2) 8);
    };

    systemd = {
      enable = true;

      # Enable xdg-desktop-portal to find applications
      # FIXME: Import minimal set of variables
      variables = [ "--all" ];
    };
  };

  home.packages = with pkgs; [
    sway-contrib.grimshot
  ];

  programs = {
    swaylock.enable = true;
    wofi.enable = true;
  };

  services = {
    swayidle = {
      enable = true;
      events = [
        { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
      ];
      timeouts = [
        { timeout = 1800; command = "${pkgs.systemd}/bin/systemctl suspend"; }
      ];
    };
  };
}
