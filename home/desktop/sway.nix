{
  config,
  lib,
  pkgs,
  ...
}:

let
  devices = import ./_devices.nix;
in
{
  wayland.windowManager.sway = {
    enable = true;

    extraConfig = ''
      disable_titlebar yes
      for_window [tiling] border pixel 0
      workspace_layout tabbed
    '';

    config = {
      bars = [ ];

      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 4;
      };

      input = {
        "type:keyboard" = {
          repeat_delay = "250";
          xkb_options = "ctrl:nocaps";
        };
        "type:touchpad" = {
          dwt = "enabled"; # disable-while-typing
          natural_scroll = "enabled";
          tap = "enabled";
        };
        "type:pointer" = {
          accel_profile = "adaptive";
          pointer_accel = "0";
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
        "eDP-1" = {
          mode = "1920x1080@60Hz";
          position = "0 0";
          scale = "1.25";
        };
        "${devices.monitor.MSI_G271}" = {
          mode = "1920x1080@120Hz";
          position = "1536 0";
        };
      };

      startup = [
        { command = "swaylock -fF"; } # for auto-login
        { command = "${pkgs.swaybg}/bin/swaybg -i ${config.stylix.image} -m fill"; }
      ];

      terminal = lib.getExe pkgs.foot;

      window = {
        commands = [
          {
            command = "resize set 1024 576, move position center";
            criteria = {
              floating = true;
              app_id = "foot";
            };
          }
        ];
        titlebar = false;
        border = 0;
      };

      floating = {
        titlebar = false;
        border = 0;
      };

      # FIXME: Do this dynamically
      workspaceOutputAssign = [
        {
          workspace = "1";
          output = "eDP-1";
        }
      ]
      ++ map (i: {
        workspace = toString (i);
        output = devices.monitor.MSI_G271;
      }) (builtins.genList (i: i + 2) 8);
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

  programs.waybar = lib.attrsets.optionalAttrs config.wayland.windowManager.sway.enable {
    settings.main = {
      modules-left = [
        "sway/workspaces"
        "sway/mode"
        "custom/sway-window-count"
      ];
      "sway/workspaces" = {
        all-outputs = true;
        format = "{name}";
      };
      "sway/mode" = {
        format = ''<span style="italic">{}</span>'';
      };
      "custom/sway-window-count" = {
        exec = "${./sway-window-count.sh}";
        format = "{}";
      };
    };
  };

  services = {
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
