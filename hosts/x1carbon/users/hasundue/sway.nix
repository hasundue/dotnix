{
  wayland.windowManager.sway = {
    enable = true;
    config = {
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
      output = {
        "AU Optronics 0x313D Unknown" = {
          mode = "1920x1080@60Hz";
          scale = "1.2";
        };
        "Microstep MSI G271 0x00003146" = {
          mode = "1920x1080@120Hz";
        };
      };
      modifier = "Mod4";
    };
    extraConfig = ''
      bindsym XF86AudioRaiseVolume exec pactl set-sink-volume @DEFAULT_SINK@ +5%
      bindsym XF86AudioLowerVolume exec pactl set-sink-volume @DEFAULT_SINK@ -5%
      bindsym XF86AudioMute exec pactl set-sink-mute @DEFAULT_SINK@ toggle
      bindsym XF86AudioMicMute exec pactl set-source-mute @DEFAULT_SOURCE@ toggle
      bindsym XF86MonBrightnessUp exec brightnessctl set +5%
      bindsym XF86MonBrightnessDown exec brightnessctl set 5%-
    '';
  };
}
