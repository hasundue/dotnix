{ lib, pkgs, ... }: 

{
  wayland.windowManager.sway = {
    config = {
      bars = [{
        statusCommand = "i3status";
      }];
      gaps = {
        smartBorders = "on";
        smartGaps = false;
        inner = 10;
      };
      menu = "tofi-run | xargs swaymsg exec env NIXOS_OZONE_WL=1 --";
      terminal = lib.getExe pkgs.foot;
      window = {
        titlebar = false;
      };
    };
    systemd.enable = true;
    wrapperFeatures.gtk = true;
  };

  home = {
    packages = (with pkgs; [ 
      grim
      slurp
      tofi
    ]);
  };

  programs = {
    i3status.enable = true;
    swaylock = {
      enable = true;
    };
  };

  services = {
    swayidle = {
      enable = true;
    };
  };
}
