{
  config,
  pkgs,
  lib,
  ...
}:
let
  devices = import ../_devices.nix;
  cornerRadius = 8.0;
in
{
  wayland.windowManager.niri = {
    enable = true;
    # NixOS owns the niri package, session, portals, and xwayland-satellite.
    systemd.enable = false;
    portalPackage = null;
    xwaylandSatellitePackage = null;

    settings = {
      prefer-no-csd = { };

      _children = [
        {
          output = {
            _args = [ "eDP-1" ];
            mode = "1920x1080@60.000000";
            position = {
              _props = {
                x = 0;
                y = 0;
              };
            };
            scale = 1.25;
          };
        }
        {
          output = {
            _args = [ devices.monitor.MSI_G271 ];
            mode = "1920x1080@120.000000";
            position = {
              _props = {
                x = 1536;
                y = 0;
              };
            };
          };
        }
        {
          spawn-at-startup = [
            "swaylock"
            "-fF"
          ];
        }
        {
          spawn-at-startup = [
            (lib.getExe pkgs.swaybg)
            "-i"
            "${config.stylix.image}"
            "-m"
            "fill"
          ];
        }
        {
          window-rule = {
            geometry-corner-radius = {
              _args = [
                cornerRadius
                cornerRadius
                cornerRadius
                cornerRadius
              ];
            };
            clip-to-geometry = true;
            default-column-width = {
              proportion = 0.7;
            };
          };
        }
        {
          window-rule = {
            _children = [
              {
                match._props = {
                  app-id = "^foot$";
                };
              }
            ];
            default-column-display = "tabbed";
          };
        }
        {
          window-rule = {
            _children = [
              {
                match._props = {
                  app-id = "^dev.zed.Zed$";
                };
              }
              {
                match._props = {
                  app-id = "^firefox$";
                };
              }
              {
                match._props = {
                  app-id = "^google-chrome$";
                };
              }
              {
                match._props = {
                  app-id = "^Slack$";
                };
              }
              {
                match._props = {
                  app-id = "^spotify$";
                };
              }
              {
                match._props = {
                  app-id = "^steam$";
                };
              }
            ];
            default-column-width = {
              proportion = 0.9;
            };
          };
        }
      ];

      input = {
        keyboard = {
          repeat-delay = 250;
        };
        touchpad = {
          dwt = { };
          natural-scroll = { };
          tap = { };
        };
        mouse = {
          accel-profile = "adaptive";
          accel-speed = 0.0;
        };
      };

      layout = {
        gaps = 4;
        always-center-single-column = { };
        empty-workspace-above-first = { };
        preset-column-widths._children = [
          {
            proportion = 0.7;
          }
          {
            proportion = 0.9;
          }
        ];
        border.off = { };
        focus-ring.off = { };
        shadow.on = { };
        tab-indicator = {
          gap = 0;
          hide-when-single-tab = { };
          position = "top";
          gaps-between-tabs = 16;
          corner-radius = 4.0;
        };
      };

      hotkey-overlay = {
        hide-not-bound = { };
        skip-at-startup = { };
      };

      binds = {
        "Mod+Shift+Slash".show-hotkey-overlay = { };

        "Mod+T".spawn = [ (lib.getExe pkgs.foot) ];
        "Mod+D".spawn = [ "fuzzel" ];
        "Mod+Alt+L".spawn = [ "swaylock" ];

        "Mod+Alt+S" = {
          _props.allow-when-locked = true;
          spawn-sh = "exec systemctl suspend";
        };
        "Mod+O" = {
          _props.repeat = false;
          toggle-overview = { };
        };
        "Mod+Q" = {
          _props.repeat = false;
          close-window = { };
        };
        "Mod+W".toggle-column-tabbed-display = { };

        "Mod+H".focus-column-left = { };
        "Mod+L".focus-column-right = { };
        "Mod+Shift+H".move-column-left = { };
        "Mod+Shift+L".move-column-right = { };

        "Mod+N".focus-window-down = { };
        "Mod+P".focus-window-up = { };
        "Mod+Shift+N".move-window-down = { };
        "Mod+Shift+P".move-window-up = { };

        "Mod+J".focus-workspace-down = { };
        "Mod+K".focus-workspace-up = { };
        "Mod+Shift+J".move-column-to-workspace-down = { };
        "Mod+Shift+K".move-column-to-workspace-up = { };

        "Mod+Left".focus-monitor-left = { };
        "Mod+Right".focus-monitor-right = { };
        "Mod+Shift+Left".move-column-to-monitor-left = { };
        "Mod+Shift+Right".move-column-to-monitor-right = { };

        "Mod+Home".focus-column-first = { };
        "Mod+End".focus-column-last = { };
        "Mod+Shift+Home".move-column-to-first = { };
        "Mod+Shift+End".move-column-to-last = { };

        "Mod+BracketLeft".consume-or-expel-window-left = { };
        "Mod+BracketRight".consume-or-expel-window-right = { };

        "Mod+Comma".consume-window-into-column = { };
        "Mod+Period".expel-window-from-column = { };

        "Mod+R".switch-preset-column-width = { };
        "Mod+Shift+R".switch-preset-window-height = { };
        "Mod+Ctrl+R".reset-window-height = { };
        "Mod+F".maximize-column = { };
        "Mod+Ctrl+F".expand-column-to-available-width = { };
        "Mod+Shift+F".fullscreen-window = { };

        "Mod+C".center-column = { };
        "Mod+Ctrl+C".center-visible-columns = { };

        "Mod+E".set-column-width = "50%";
        "Mod+Minus".set-column-width = "-10%";
        "Mod+Equal".set-column-width = "+10%";
        "Mod+Shift+Minus".set-window-height = "-10%";
        "Mod+Shift+Equal".set-window-height = "+10%";

        "Mod+V".toggle-window-floating = { };
        "Mod+Shift+V".switch-focus-between-floating-and-tiling = { };

        "Print".screenshot = { };
        "Ctrl+Print".screenshot-screen = { };
        "Alt+Print".screenshot-window = { };
        "Mod+Escape" = {
          _props.allow-inhibiting = false;
          toggle-keyboard-shortcuts-inhibit = { };
        };

        "Mod+Shift+E".quit = { };
        "Ctrl+Alt+Delete".quit = { };

        "XF86AudioRaiseVolume" = {
          _props.allow-when-locked = true;
          spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
        };
        "XF86AudioLowerVolume" = {
          _props.allow-when-locked = true;
          spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
        };
        "XF86AudioMute" = {
          _props.allow-when-locked = true;
          spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        };
        "XF86AudioMicMute" = {
          _props.allow-when-locked = true;
          spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
        };
        "XF86AudioPlay" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl play-pause";
        };
        "XF86AudioStop" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl stop";
        };
        "XF86AudioPrev" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl previous";
        };
        "XF86AudioNext" = {
          _props.allow-when-locked = true;
          spawn-sh = "playerctl next";
        };
        "XF86MonBrightnessUp" = {
          _props.allow-when-locked = true;
          spawn = [
            "brightnessctl"
            "--class=backlight"
            "set"
            "+10%"
          ];
        };
        "XF86MonBrightnessDown" = {
          _props.allow-when-locked = true;
          spawn = [
            "brightnessctl"
            "--class=backlight"
            "set"
            "10%-"
          ];
        };
      };
    };
  };
}
