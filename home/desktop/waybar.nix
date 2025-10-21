{ pkgs, ... }:

let
  fcitx5-status = pkgs.writeShellScript "fcitx5-status" ''
    IM=$(${pkgs.fcitx5}/bin/fcitx5-remote -n 2>/dev/null)

    case "$IM" in
      keyboard-us)
        echo "EN"
        ;;
      mozc)
        echo "JP"
        ;;
      *)
        echo "$IM"
        ;;
    esac
  '';
in
{
  programs.waybar = {
    enable = true;

    style = ''
      * {
        font-family: "0xProto Nerd Font Propo";
      }
      tooltip {
        border: none;
      }
    '';

    settings.main = {
      layer = "top";
      output = [ "eDP-1" ];
      height = 32;

      modules-right = [
        "custom/fcitx5"
        "network"
        "pulseaudio"
        "backlight"
        "battery"
        "clock"
      ];

      "custom/fcitx5" = {
        exec = "${fcitx5-status}";
        interval = 1;

        format = "󰌌 {}";

        on-click = "${pkgs.fcitx5}/bin/fcitx5-remote -t";
        exec-if = "${pkgs.procps}/bin/pgrep fcitx5";

        min-length = 6;
        max-length = 6;

        tooltip = false;
      };

      network = {
        format-wifi = "{icon}";
        format-icons = [
          "󰤟"
          "󰤢"
          "󰤥"
          "󰤨"
        ];
        format-disconnected = "󰤫";
        format-disabled = "󰤮";

        min-length = 3;
        max-length = 3;

        tooltip-format-wifi = "Network: {essid}\nIP Addr: {ipaddr}/{cidr}\nStrength: {signalStrength}%\nFrequency: {frequency} GHz";
      };

      pulseaudio = {
        format = "{icon} {volume}%";
        format-muted = "{icon} {volume}%";

        format-bluetooth = "󰗾 {volume}%";
        format-bluetooth-muted = "󰗿 {volume}%";

        format-icons = {
          headphones = "󰋋";
          handsfree = "󰋎";
          headset = "󰋎";
          phone = "󰏲";
          default = [
            "󰕿"
            "󰖀"
            "󰕾"
          ];
        };

        on-click = "${pkgs.ponymix}/bin/ponymix -t sink toggle";
        on-scroll-up = "${pkgs.ponymix}/bin/ponymix increase 1";
        on-scroll-down = "${pkgs.ponymix}/bin/ponymix decrease 1";

        min-length = 6;
        max-length = 7;

        tooltip-format = "{desc}";
      };

      backlight = {
        device = "intel_backlight";

        format = "{icon} {percent}%";
        format-icons = [
          "󱩎"
          "󱩏"
          "󱩐"
          "󱩑"
          "󱩒"
          "󱩓"
          "󱩔"
          "󱩕"
          "󱩖"
          "󰛨"
        ];

        on-scroll-up = "${pkgs.brightnessctl}/bin/brightnessctl set +1%";
        on-scroll-down = "${pkgs.brightnessctl}/bin/brightnessctl set 1%-";

        min-length = 6;
        max-length = 7;

        tooltip = false;
      };

      battery = {
        bat = "BAT0";

        states = {
          warning = 20;
          critical = 10;
        };

        format = "{icon} {capacity}%";
        format-time = "{H}:{M}";
        format-icons = [
          "󰂎"
          "󰁺"
          "󰁻"
          "󰁼"
          "󰁽"
          "󰁾"
          "󰁿"
          "󰂀"
          "󰂁"
          "󰂂"
          "󰁹"
        ];
        format-charging = "󰂄 {capacity}%";

        min-length = 6;
        max-length = 6;

        tooltip = false;
      };

      clock = {
        format = "{:%H:%M}";

        min-length = 7;
        max-length = 7;

        tooltip-format = "{:%A, %B %d, %Y}";
      };
    };
  };
}
