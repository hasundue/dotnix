{ lib, pkgs, ... }: 

{
  imports = [
    ./waybar.nix
  ];

  wayland.windowManager.sway = {
    config = {
      bars = [];
      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 5;
      };
      menu = "rofi -show run";
      terminal = lib.getExe pkgs.alacritty;
      window = {
        titlebar = false;
      };
    };
    extraConfig = ''
      bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bindsym XF86MonBrightnessUp exec brightnessctl set +5%
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
    '';
    systemd.enable = true;
    wrapperFeatures.gtk = true;
  };

  programs = {
    i3status.enable = true;
    swaylock = {
      enable = true;
    };
    rofi = {
      enable = true;
    };
  };

  services = {
    swayidle = {
      enable = true;
      events = [
        { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -fF"; }
      ];
      timeouts = [
        { timeout = 60; command = "${pkgs.systemd}/bin/systemctl suspend"; }
      ];
    };
  };
}
