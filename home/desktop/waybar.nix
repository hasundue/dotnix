{ lib, pkgs, ... }:

let
  devices = import ./_devices.nix;
in
{
  programs.waybar = {
    enable = true;

    settings.main = {
      layer = "top";

      output = [
        "eDP-1"
        devices.monitor.MSI_G271
      ];

      spacing = 4;

      modules-left = [
        "sway/workspaces"
        "sway/mode"
      ];

      modules-center = [
        "clock"
      ];

      modules-right = [
        "idle_inhibitor"
        "network"
        "temperature"
        "memory"
        "disk"
        "pulseaudio"
        "backlight"
        "battery"
        "custom/space"
        "tray"
        "custom/space"
      ];

      "sway/workspaces" = {
        all-outputs = true;
        format = "{name}";
      };

      "sway/mode" = { format = ''<span style="italic">{}</span>''; };

      clock = {
        interval = 60;
        tooltip-format = "<tt>{calendar}</tt>";
        format = "󰥔 {:%H:%M}";
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = " ";
          deactivated = " ";
        };
      };

      temperature = {
        critical-threshold = lib.mkDefault 90;
        format = "{icon} {temperatureC}℃";
        format-icons = [ "" "" "" ];
      };

      memory = {
        format = " {percentage}%";
      };

      disk = {
        format = " {percentage_used}%";
      };

      network = {
        format-wifi = " ";
        format-disconnected = "睊";
        tooltip-format = "{essid}";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-bluetooth = " {volume}%";
        format-bluetooth-muted = "";
        format-muted = "";
        format-icons = {
          headphones = "";
          handsfree = "󰋎";
          headset = "󰋎";
          phone = "";
          default = [ "" "" "" ];
        };
        on-click = "${pkgs.ponymix}/bin/ponymix -t sink toggle";
        on-scroll-up = "${pkgs.ponymix}/bin/ponymix increase 1";
        on-scroll-down = "${pkgs.ponymix}/bin/ponymix decrease 1";
      };

      backlight = {
        device = "intel_backlight";
        format = "{icon} {percent}%";
        format-icons = [ "󱩎" "󱩏" "󱩐" "󱩑" "󱩒" "󱩓" "󱩔" "󱩕" "󱩖" "󰛨" ];
        on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set +1%";
        on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";
      };

      battery = {
        bat = "BAT0";
        states = {
          good = 90;
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = " {capacity}%";
        format-alt = "{icon} {time}";
        format-icons = [ "" "" "" "" "" ];
      };

      tray = {
        icon-size = lib.mkDefault 16;
        spacing = lib.mkDefault 4;
      };

      "custom/space" = {
        format = " ";
      };
    };

    systemd = {
      enable = true;
      target = "sway-session.target";
    };
  };
}
