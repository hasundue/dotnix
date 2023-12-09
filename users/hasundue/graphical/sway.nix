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
    };
  };
}
