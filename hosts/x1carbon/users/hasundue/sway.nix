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
        "eDP-1" = {
          mode = "1920x1080@60Hz";
          scale = "1.2";
        };
        "DP-2" = {
          mode = "1920x1080@120Hz";
        };
      };
      modifier = "Mod4";
      workspaceOutputAssign = [
        { workspace = "1"; output = "eDP-1"; }
      ] ++ map 
        (i: { workspace = toString (i); output = "DP-2"; })
        (builtins.genList (i: i + 2) 8);
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
