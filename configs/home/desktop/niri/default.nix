{
  config,
  pkgs,
  lib,
  ...
}:
let
  devices = import ../_devices.nix;
  niriLib = import ./lib.nix { inherit pkgs; };
  inherit (niriLib) forEachCorner;
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
        position = {
          x = 1536;
          y = 0;
        };
      };
    };
    spawn-at-startup = [
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
        default-column-width = {
          proportion = 0.7;
        };
      }
      {
        matches = [
          { app-id = "^kitty$"; }
          { app-id = "^org.wezfurlong.wezterm$"; }
        ];
        default-column-display = "tabbed";
        default-column-width = {
          proportion = 0.5;
        };
      }
      {
        matches = [
          { app-id = "^firefox$"; }
          { app-id = "^Slack$"; }
          { app-id = "^spotify$"; }
          { app-id = "^chromium-browser$"; }
        ];
        default-column-width = {
          proportion = 0.9;
        };
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
      gaps = 4;
      always-center-single-column = true;
      empty-workspace-above-first = true;
      preset-column-widths = [
        { proportion = 0.7; }
        { proportion = 0.9; }
      ];
      border.enable = false;
      focus-ring.enable = false;
      shadow.enable = true;
      tab-indicator = {
        gap = 0;
        hide-when-single-tab = true;
        position = "top";
        gaps-between-tabs = 0;
        corner-radius = 4.0;
      };
    };
    binds = with config.lib.niri.actions; {
      "Mod+Shift+Slash".action = show-hotkey-overlay;

      "Mod+T".action = spawn "kitty";
      "Mod+D".action = spawn "fuzzel";
      "Mod+Alt+L".action = spawn "swaylock";

      "Mod+Alt+S" = {
        action = spawn-sh "exec systemctl suspend";
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
      "Mod+W".action = toggle-column-tabbed-display;

      "Mod+H".action = focus-column-left;
      "Mod+L".action = focus-column-right;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+L".action = move-column-right;

      "Mod+N".action = focus-window-down; # N stands for Next
      "Mod+P".action = focus-window-up; # P stands for Previous
      "Mod+Shift+N".action = move-window-down;
      "Mod+Shift+P".action = move-window-up;

      "Mod+J".action = focus-workspace-down;
      "Mod+K".action = focus-workspace-up;
      "Mod+Shift+J".action = move-column-to-workspace-down;
      "Mod+Shift+K".action = move-column-to-workspace-up;

      "Mod+Left".action = focus-monitor-left;
      "Mod+Right".action = focus-monitor-right;
      "Mod+Shift+Left".action = move-column-to-monitor-left;
      "Mod+Shift+Right".action = move-column-to-monitor-right;

      "Mod+Home".action = focus-column-first;
      "Mod+End".action = focus-column-last;
      "Mod+Shift+Home".action = move-column-to-first;
      "Mod+Shift+End".action = move-column-to-last;

      "Mod+BracketLeft".action = consume-or-expel-window-left;
      "Mod+BracketRight".action = consume-or-expel-window-right;

      "Mod+Comma".action = consume-window-into-column;
      "Mod+Period".action = expel-window-from-column;

      "Mod+R".action = switch-preset-column-width;
      "Mod+Shift+R".action = switch-preset-window-height;
      "Mod+Ctrl+R".action = reset-window-height;
      "Mod+F".action = maximize-column;
      "Mod+Ctrl+F".action = expand-column-to-available-width;
      "Mod+Shift+F".action = fullscreen-window;

      "Mod+C".action = center-column;
      "Mod+Ctrl+C".action = center-visible-columns;

      "Mod+E".action = set-column-width "50%";
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";
      "Mod+Shift+Minus".action = set-window-height "-10%";
      "Mod+Shift+Equal".action = set-window-height "+10%";

      "Mod+V".action = toggle-window-floating;
      "Mod+Shift+V".action = switch-focus-between-floating-and-tiling;

      "Print".action.screenshot = [ ];
      "Ctrl+Print".action.screenshot-screen = [ ];
      "Alt+Print".action.screenshot-window = [ ];
      "Mod+Escape" = {
        action = toggle-keyboard-shortcuts-inhibit;
        allow-inhibiting = false;
      };

      "Mod+Shift+E".action = quit;
      "Ctrl+Alt+Delete".action = quit;

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
    };
  };
}
