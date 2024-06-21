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
          scale = "1.25";
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
  };
}
