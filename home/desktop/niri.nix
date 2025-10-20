{
  config,
  pkgs,
  lib,
  ...
}:

let
  devices = import ./_devices.nix;

  forEachCorner = v: {
    top-left = v;
    top-right = v;
    bottom-left = v;
    bottom-right = v;
  };
in
{
  programs.niri.settings = {
    prefer-no-csd = true;

    outputs = {
      "eDP-1" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 60.0;
        };
        position = {
          x = 0;
          y = 0;
        };
        scale = 1.25;
      };
      "${devices.monitor.MSI_G271}" = {
        mode = {
          width = 1920;
          height = 1080;
          refresh = 120.0;
        };
        # Position accounts for eDP-1's scaled width: 1920 / 1.25 = 1536
        position = {
          x = 1536;
          y = 0;
        };
      };
    };

    spawn-at-startup = [
      {
        argv = [
          "waybar"
        ];
      }
      {
        argv = [
          "swaylock"
          "-fF"
        ];
      }
      {
        argv = [
          (lib.getExe pkgs.swaybg)
          "-i"
          "${config.stylix.image}"
          "-m"
          "fill"
        ];
      }
    ];

    window-rules = [
      {
        geometry-corner-radius = forEachCorner 8.0;
        clip-to-geometry = true;
      }
      {
        matches = [ { app-id = "^foot$"; } ];
        default-column-width = {
          proportion = 0.75;
        };
      }
      {
        matches = [ { app-id = "^firefox$"; } ];
        open-maximized = true;
      }
    ];

    input = {
      keyboard = {
        xkb.options = "ctrl:nocaps";
        repeat-delay = 250;
      };
      touchpad = {
        dwt = true;
        natural-scroll = true;
        tap = true;
      };
      mouse = {
        accel-profile = "adaptive";
        accel-speed = 0.0;
      };
    };

    layout = {
      gaps = 8;
      always-center-single-column = true;
      empty-workspace-above-first = true;

      preset-column-widths = [
        { proportion = 0.5; }
        { proportion = 0.75; }
      ];

      border.enable = false;
      focus-ring.enable = false;

      shadow.enable = true;

      tab-indicator = {
        gap = 4;
        position = "top";
        gaps-between-tabs = 8;
        corner-radius = 4.0;
      };
    };

    binds = with config.lib.niri.actions; {
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      "Mod+T".action = spawn "foot";
      "Mod+D".action = spawn "fuzzel";
      "Super+Alt+L".action = spawn "swaylock";

      "Super+Alt+S" = {
        action = spawn-sh "pkill orca || exec orca";
        allow-when-locked = true;
      };

      "XF86AudioRaiseVolume" = {
        action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn-sh "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn-sh "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        allow-when-locked = true;
      };

      "XF86AudioPlay" = {
        action = spawn-sh "playerctl play-pause";
        allow-when-locked = true;
      };
      "XF86AudioStop" = {
        action = spawn-sh "playerctl stop";
        allow-when-locked = true;
      };
      "XF86AudioPrev" = {
        action = spawn-sh "playerctl previous";
        allow-when-locked = true;
      };
      "XF86AudioNext" = {
        action = spawn-sh "playerctl next";
        allow-when-locked = true;
      };

      "XF86MonBrightnessUp" = {
        action = spawn "brightnessctl" "--class=backlight" "set" "+10%";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn "brightnessctl" "--class=backlight" "set" "10%-";
        allow-when-locked = true;
      };

      "Mod+O" = {
        action = toggle-overview;
        repeat = false;
      };

      "Mod+Q" = {
        action = close-window;
        repeat = false;
      };

      "Mod+Left".action = focus-column-left;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+Right".action = focus-column-right;
      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+L".action = focus-column-right;

      "Mod+Ctrl+Left".action = move-column-left;
      "Mod+Ctrl+Down".action = move-window-down;
      "Mod+Ctrl+Up".action = move-window-up;
      "Mod+Ctrl+Right".action = move-column-right;
      "Mod+Ctrl+H".action = move-column-left;
      "Mod+Ctrl+J".action = move-window-down;
      "Mod+Ctrl+K".action = move-window-up;
      "Mod+Ctrl+L".action = move-column-right;

      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Ctrl+Home".action = move-column-to-first;
      "Mod+Ctrl+End".action = move-column-to-last;

      "Mod+Shift+Left".action = focus-monitor-left;
      "Mod+Shift+Down".action = focus-monitor-down;
      "Mod+Shift+Up".action = focus-monitor-up;
      "Mod+Shift+Right".action = focus-monitor-right;
      "Mod+Shift+H".action = focus-monitor-left;
      "Mod+Shift+J".action = focus-monitor-down;
      "Mod+Shift+K".action = focus-monitor-up;
      "Mod+Shift+L".action = focus-monitor-right;

      "Mod+Shift+Ctrl+Left".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+Down".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+Up".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+Right".action = move-column-to-monitor-right;
      "Mod+Shift+Ctrl+H".action = move-column-to-monitor-left;
      "Mod+Shift+Ctrl+J".action = move-column-to-monitor-down;
      "Mod+Shift+Ctrl+K".action = move-column-to-monitor-up;
      "Mod+Shift+Ctrl+L".action = move-column-to-monitor-right;

      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;
      "Mod+U".action = focus-workspace-up;
      "Mod+I".action = focus-workspace-down;
      "Mod+Ctrl+Page_Down".action = move-column-to-workspace-down;
      "Mod+Ctrl+Page_Up".action = move-column-to-workspace-up;
      "Mod+Ctrl+U".action = move-column-to-workspace-up;
      "Mod+Ctrl+I".action = move-column-to-workspace-down;

      "Mod+Shift+Page_Down".action = move-workspace-down;
      "Mod+Shift+Page_Up".action = move-workspace-up;
      "Mod+Shift+U".action = move-workspace-up;
      "Mod+Shift+I".action = move-workspace-down;

      "Mod+WheelScrollDown" = {
        action = focus-workspace-down;
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = {
        action = focus-workspace-up;
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollDown" = {
        action = move-column-to-workspace-down;
        cooldown-ms = 150;
      };
      "Mod+Ctrl+WheelScrollUp" = {
        action = move-column-to-workspace-up;
        cooldown-ms = 150;
      };

      "Mod+WheelScrollRight".action = focus-column-right;
      "Mod+WheelScrollLeft".action = focus-column-left;
      "Mod+Ctrl+WheelScrollRight".action = move-column-right;
      "Mod+Ctrl+WheelScrollLeft".action = move-column-left;

      "Mod+Shift+WheelScrollDown".action = focus-column-right;
      "Mod+Shift+WheelScrollUp".action = focus-column-left;
      "Mod+Ctrl+Shift+WheelScrollDown".action = move-column-right;
      "Mod+Ctrl+Shift+WheelScrollUp".action = move-column-left;

      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;

      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;

      "Mod+Comma".action = consume-window-into-column;
      "Mod+Period".action = expel-window-from-column;

      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+R".action = reset-window-height;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;

      "Mod+Ctrl+F".action = expand-column-to-available-width;

      "Mod+C".action = center-column;

      "Mod+Ctrl+C".action = center-visible-columns;

      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";

      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      "Mod+V".action = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

      "Mod+W".action = toggle-column-tabbed-display;

      "Print".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];

      "Mod+Escape" = {
        action = toggle-keyboard-shortcuts-inhibit;
        allow-inhibiting = false;
      };

      "Mod+Shift+E".action = quit;
      "Ctrl+Alt+Delete".action = quit;

      "Mod+Shift+P".action = power-off-monitors;
    };
  };
}
