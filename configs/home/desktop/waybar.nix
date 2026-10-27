{ pkgs, ... }:

let
  niri-monitor = pkgs.writeShellScript "niri-monitor" ''
    outputs=$(${pkgs.niri}/bin/niri msg --json outputs 2>/dev/null) || exit 0

    ext=$(echo "$outputs" | ${pkgs.jq}/bin/jq -c '[.[] | select(.name != "eDP-1")] | first // empty')
    [ -z "$ext" ] && exit 0

    if echo "$ext" | ${pkgs.jq}/bin/jq -e '.current_mode != null' > /dev/null; then
      echo "$ext" | ${pkgs.jq}/bin/jq -c '{text: "󰍹", class: "active", tooltip: (.model + " (" + .name + ")")}'
    else
      echo "$ext" | ${pkgs.jq}/bin/jq -c '{text: "󰍹", class: "inactive", tooltip: (.model + " (" + .name + ")")}'
    fi
  '';

  niri-monitor-toggle = pkgs.writeShellScript "niri-monitor-toggle" ''
    outputs=$(${pkgs.niri}/bin/niri msg --json outputs 2>/dev/null) || exit 1

    connector=$(echo "$outputs" | ${pkgs.jq}/bin/jq -r '[.[] | select(.name != "eDP-1")] | first | .name // empty')
    [ -z "$connector" ] && exit 1

    is_on=$(echo "$outputs" | ${pkgs.jq}/bin/jq -r '[.[] | select(.name != "eDP-1")] | first | .current_mode != null')

    if [ "$is_on" = "true" ]; then
      ${pkgs.niri}/bin/niri msg output "$connector" off
    else
      ${pkgs.niri}/bin/niri msg output "$connector" on
    fi
  '';

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
    systemd.enable = true;

    style = ''
      * {
        font-family: "0xProto Nerd Font Propo";
      }
      tooltip {
        border: none;
      }
      #custom-monitor.inactive {
        opacity: 0.4;
      }
    '';

    settings.main = {
      layer = "top";
      output = [
        "eDP-1"
        "DP-1"
        "DP-2"
        "HDMI-A-1"
      ];
      height = 32;

      modules-right = [
        "custom/fcitx5"
        "idle_inhibitor"
        "custom/monitor"
        "network"
        "memory"
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

        min-length = 7;
        max-length = 7;

        tooltip = false;
      };

      "custom/monitor" = {
        exec = "${niri-monitor}";
        return-type = "json";
        interval = 1;

        on-click = "${niri-monitor-toggle}";

        min-length = 3;
        max-length = 3;

        tooltip = true;
      };

      idle_inhibitor = {
        format = "{icon}";
        format-icons = {
          activated = "";
          deactivated = "";
        };
        min-length = 3;
        max-length = 3;
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

        on-click = "${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu";
      };

      memory = {
        format = "󰍛 {percentage}%";
        interval = 1;

        min-length = 6;
        max-length = 6;

        tooltip-format = "Used: {used:0.1f}GiB / {total:0.1f}GiB";
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
