{ config, lib, pkgs, ... }:

{
  imports = [
    ./waybar.nix
  ];

  wayland.windowManager.sway = {
    config = {
      bars = [ ];
      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 5;
      };
      keybindings =
        let
          mod = config.wayland.windowManager.sway.config.modifier;
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
          "${mod}+Ctrl+l" = "exec swaylock -fF";
          "${mod}+Ctrl+s" = "exec systemctl suspend";
        };
      menu = "wofi --show run";
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
    };
    systemd.enable = true;
    wrapperFeatures.gtk = true;
  };

  home.packages = with pkgs; [
    sway-contrib.grimshot
  ];

  programs = {
    i3status.enable = true;
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
