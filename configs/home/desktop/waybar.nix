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

  # Right-click on the battery icon: arm the 100% override, or disarm it if it
  # is already armed, so a mistaken click is undone by clicking again. The
  # polkit rule in configs/hosts/x1carbon/battery.nix lets those two units start
  # without a password, so the notification is what tells a click from a no-op.
  battery-toggle = pkgs.writeShellScript "battery-toggle" ''
    end=$(cat /sys/class/power_supply/BAT0/charge_control_end_threshold 2>/dev/null || echo 90)
    msg=
    urgency=low

    if [ "$end" -ge 100 ]; then
      if ${pkgs.systemd}/bin/systemctl start battery-restore.service; then
        msg="Back to the 85/90 window."
      else
        msg="Restoring the window failed (journalctl -u battery-restore)."
        urgency=critical
      fi
    elif [ "$(cat /sys/class/power_supply/AC/online)" != "1" ]; then
      msg="Connect the charger first: a full charge needs AC."
      urgency=normal
    elif ${pkgs.systemd}/bin/systemctl start battery-fullcharge.service; then
      msg="Charging to 100%. Right-click again to go back to 85/90."
    else
      msg="Starting the full charge failed (journalctl -u battery-fullcharge)."
      urgency=critical
    fi

    # Failures stay until dismissed; the rest fade after 3 seconds.
    if [ "$urgency" = "critical" ]; then
      timeout=0
    else
      timeout=3000
    fi

    ${pkgs.libnotify}/bin/notify-send -a battery -u "$urgency" -t "$timeout" "Battery" "$msg"
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

  # One dmenu per direction, grouped by card. A card only exposes the outputs its
  # current profile has, so with HDMI plugged in the built-in speakers are not a
  # sink at all and only a profile switch brings them back; the devices a card
  # lists are folded into its profile entries so the same speaker is not offered
  # twice. ▶ marks what the sound is going through now — the profile of the card
  # that holds the default device, or one no card owns — and ◉ the profile a card
  # is set to without being the current output.
  switch-audio =
    dir:
    let
      section = if dir == "sink" then "Sinks" else "Sources";
      class = if dir == "sink" then "Audio/Sink" else "Audio/Source";
      heading = if dir == "sink" then "Other outputs" else "Other inputs";
      at = if dir == "sink" then "SINK" else "SOURCE";
    in
    pkgs.writeShellScript "switch-audio-${dir}" ''
      wpctl=${pkgs.wireplumber}/bin/wpctl
      pw_cli=${pkgs.pipewire}/bin/pw-cli
      pw_dump=${pkgs.pipewire}/bin/pw-dump
      jq=${pkgs.jq}/bin/jq
      awk=${pkgs.gawk}/bin/awk
      fuzzel=${pkgs.fuzzel}/bin/fuzzel

      # The default node is not the one `wpctl status` stars: every media class
      # has its own, so a camera is starred in the Video block.
      current_node=$($wpctl inspect "@DEFAULT_AUDIO_${at}@" 2>/dev/null | $awk '
        NR == 1 { sub(/^id /, ""); sub(/,.*/, ""); print; exit }
      ')

      # Which card holds that node: its profile is the one that decides where the
      # sound goes, so it carries ▶ rather than ◉.
      default_card=$($wpctl inspect "$current_node" 2>/dev/null | $awk -F' = ' '
        /device.id/ { gsub(/"/, "", $2); print $2; exit }
      ')

      # The devices that exist for this direction right now. Only the Audio
      # block counts: the Video block lists its own sources.
      device_awk='
        /^Audio$/ { audio = 1; next }
        /^[A-Z][a-z]+$/ { audio = 0; next }
        /[├└]─/ { inside = audio && ($0 ~ ("[├└]─ " want ":$")); next }
        inside && /\./ {
          gsub(/[│├─└●]/, "")
          gsub(/^[[:space:]]+/, "")
          gsub(/^\*[[:space:]]*/, "")

          id = $1
          sub(/\.$/, "", id)

          sub(/^[0-9]+\.[[:space:]]*/, "")
          sub(/[[:space:]]+\[vol:[^\]]*\]/, "")
          gsub(/[[:space:]]+$/, "")

          prefix = (id == current_node) ? " ▶ " : "    "
          print prefix $0 "\t" id
        }
      '

      devices=$($wpctl status | $awk -v want="${section}" -v current_node="$current_node" "$device_awk")

      # `wpctl status` also lists internal nodes — a headset's microphone shows up
      # twice — and `set-default` refuses those, so only the plain class counts.
      kind_awk='
        /media.class/ { gsub(/"/, "", $2); cls = $2 }
        /device.id/ { gsub(/"/, "", $2); dev = $2 }
        END { print cls "\t" dev }
      '

      plain=
      while IFS=$'\t' read -r label id; do
        [ -z "$id" ] && continue
        IFS=$'\t' read -r cls owner <<< "$($wpctl inspect "$id" 2>/dev/null | $awk -F' = ' "$kind_awk")"
        [ "$cls" = "${class}" ] || continue
        plain+="$label"$'\t'"$id"$'\n'
      done <<< "$devices"
      devices=$plain

      # The node a card exposes in this direction, which is what has to become the
      # default once its profile has been set. It comes from the graph rather than
      # from `wpctl status`, which hides the node a Bluetooth headset records from
      # behind an internal twin that `set-default` refuses.
      node_of_card() {
        $pw_dump 2>/dev/null | $jq -r --arg cls "${class}" --arg dev "$2" '
          .[]
          | select(.type == "PipeWire:Interface:Node")
          | select(.info.props."media.class" == $cls)
          | select((.info.props."device.id" | tostring) == $dev)
          | .id
        ' | ${pkgs.coreutils}/bin/head -n 1
      }

      # The cards, which own the devices above.
      cards=$($wpctl status | $awk '
        /^Audio$/ { audio = 1; next }
        /^[A-Z][a-z]+$/ { audio = 0; next }
        /[├└]─/ { inside = audio && ($0 ~ /[├└]─ Devices:$/); next }
        inside && /\./ {
          gsub(/[│├─└●]/, "")
          gsub(/^[[:space:]]+/, "")

          id = $1
          sub(/\.$/, "", id)

          sub(/^[0-9]+\.[[:space:]]*/, "")
          sub(/[[:space:]]+\[[^]]*\]$/, "")
          gsub(/[[:space:]]+$/, "")

          print id "\t" $0
        }
      ')

      # Every profile a card can carry in this direction. A profile name reads
      # `output:analog-stereo+input:analog-stereo`: the part that decides the
      # direction sits before the plus for a sink and after it for a source, and
      # among the profiles sharing it the highest priority is the one that leaves
      # the other direction alive (duplex over output-only).
      menu=
      card_ids=
      while IFS=$'\t' read -r dev card; do
        [ -z "$dev" ] && continue

        current=$($pw_cli enum-params "$dev" Profile 2>/dev/null | $awk '
          /:index \(/ { getline; print $2; exit }
        ')

        entries=$($pw_cli enum-params "$dev" EnumProfile 2>/dev/null | $awk -v want="${class}" -v dir="${dir}" -v current="$current" '
          # The devices a profile exposes, not its name, decide what a row offers:
          # the codecs of one Bluetooth profile all feed the same node, while
          # analog and HDMI are separate ones.
          function keep() {
            if (idx == "" || avail != "yes" || block !~ want) return

            key = (sig != "" ? sig : pname)
            if (idx == current) active[key] = 1
            if (!(key in prio_of) || prio > prio_of[key]) {
              prio_of[key] = prio
              entry[key] = idx "\t" pdesc
              if (!(key in seen)) {
                seen[key] = 1
                order[++n] = key
              }
            }
          }

          /^  Object:/ { keep(); idx = pname = pdesc = avail = block = sig = cur_class = ""; prio = 0; next }
          /:index \(/ { getline; idx = $2; next }
          /:name \(/ { getline; pname = $0; sub(/.*String "/, "", pname); sub(/"$/, "", pname); next }
          # Only the half that decides this direction: every profile offered here
          # keeps the other direction alive, so its half of the description is
          # the same on every row.
          /:description \(/ {
            getline
            pdesc = $0
            sub(/.*String "/, "", pdesc)
            sub(/"$/, "", pdesc)
            if (dir == "sink") sub(/ \+ .*/, "", pdesc)
            else sub(/^.* \+ /, "", pdesc)
            next
          }
          /:priority \(/ { getline; prio = $2 + 0; next }
          /:available \(/ { getline; avail = ($0 ~ /:yes/) ? "yes" : "no"; next }

          # A class entry reads `String "Audio/Sink"`, then its device indexes
          # after `card.profile.devices`.
          /[Ss]tring "(Audio|Video|Stream)\// {
            block = block "\n" $0
            cur_class = $0
            sub(/.*String "/, "", cur_class)
            sub(/".*/, "", cur_class)
            next
          }
          /card\.profile\.devices/ { in_dev = 1; next }
          in_dev && /Int [0-9]+$/ {
            if (cur_class == want) sig = sig ":" $NF
            next
          }
          in_dev && !/Array:/ { in_dev = 0 }

          { block = block "\n" $0 }

          END {
            keep()
            for (i = 1; i <= n; i++) {
              split(entry[order[i]], field, "\t")
              print field[1] "\t" field[2] "\t" ((order[i] in active) ? "1" : "0")
            }
          }
        ' | while IFS=$'\t' read -r pidx pdesc active; do
          mark="  "
          [ "$active" = "1" ] && mark="◉ "
          [ "$active" = "1" ] && [ "$dev" = "$default_card" ] && mark="▶ "
          printf '    %s%s\tprofile\t%s:%s\n' "$mark" "$pdesc" "$dev" "$pidx"
        done)

        [ -z "$entries" ] && continue

        card_ids="$card_ids $dev"
        menu+="$card"$'\n'"$entries"$'\n'
      done <<< "$cards"

      # What is left belongs to no card: virtual sinks, a camera's microphone.
      rest=
      while IFS=$'\t' read -r label id; do
        [ -z "$id" ] && continue

        owner=$($wpctl inspect "$id" 2>/dev/null | $awk -F' = ' '
          /device.id/ { gsub(/"/, "", $2); print $2; exit }
        ')

        case " $card_ids " in
          *" $owner "*) continue ;;
        esac

        rest+="$label"$'\t'"${dir}"$'\t'"$id"$'\n'
      done <<< "$devices"

      [ -n "$rest" ] && menu+="${heading}"$'\n'"$rest"

      menu=$(printf '%s\n' "$menu" | $awk 'NF')
      [ -z "$menu" ] && exit 0

      labels=$(printf '%s\n' "$menu" | $awk -F'\t' '{ print $1 }')
      selected=$(printf '%s\n' "$labels" | $fuzzel --dmenu --prompt="  ") || exit 0
      [ -z "$selected" ] && exit 0

      action=$(printf '%s\n' "$menu" | $awk -F'\t' -v want="$selected" '$1 == want { print $2 "\t" $3; exit }')
      [ -z "$action" ] && exit 1

      IFS=$'\t' read -r kind target <<< "$action"
      case "$kind" in
        sink | source) $wpctl set-default "$target" ;;
        profile)
          IFS=: read -r pdev pidx <<< "$target"
          $wpctl set-profile "$pdev" "$pidx"

          # A card that already carried this direction, like a connected headset,
          # gains nothing from the switch, so its node has to be made the default
          # as well; a card whose profile was hiding the device gives it a moment
          # to appear.
          node=$(node_of_card "${section}" "$pdev")
          if [ -z "$node" ]; then
            ${pkgs.coreutils}/bin/sleep 0.3
            node=$(node_of_card "${section}" "$pdev")
          fi
          [ -n "$node" ] && $wpctl set-default "$node"
          ;;
        *) exit 0 ;;
      esac
    '';

  # The source has no waybar module of its own, so it reports its own JSON: the
  # icon follows the mute state, the tooltip names the device in use.
  audio-source-status = pkgs.writeShellScript "audio-source-status" ''
    wpctl=${pkgs.wireplumber}/bin/wpctl

    vol=$($wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null) || exit 0
    name=$($wpctl inspect @DEFAULT_AUDIO_SOURCE@ 2>/dev/null | ${pkgs.gawk}/bin/awk -F' = ' '
      /node.description/ {
        gsub(/"/, "", $2)
        print $2
        exit
      }
    ')

    case "$vol" in
      *MUTED*)
        text="󰍭"
        class="muted"
        status="muted"
        ;;
      *)
        text="󰍬"
        class="default"
        status="active"
        ;;
    esac

    ${pkgs.jq}/bin/jq -cn \
      --arg text "$text" --arg class "$class" \
      --arg tooltip "Audio Source — $status (''${name:-unknown})" \
      '{text: $text, class: $class, tooltip: $tooltip}'
  '';
in
{
  programs.waybar = {
    enable = true;
    systemd.enable = true;

    style = ''
      * {
        font-weight: 500;
      }
      tooltip {
        border: none;
      }
      #custom-monitor.inactive {
        opacity: 0.4;
      }
      #custom-audio-source.muted,
      #pulseaudio.muted {
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
        "custom/audio-source"
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

        # Left click picks the sink, right click mutes it.
        on-click = "${switch-audio "sink"}";
        on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
        on-scroll-up = "${pkgs.ponymix}/bin/ponymix increase 1";
        on-scroll-down = "${pkgs.ponymix}/bin/ponymix decrease 1";

        min-length = 6;
        max-length = 7;

        tooltip-format = "{desc}";
      };

      "custom/audio-source" = {
        exec = "${audio-source-status}";
        return-type = "json";
        interval = 1;

        on-click = "${switch-audio "source"}";
        on-click-right = "${pkgs.wireplumber}/bin/wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle";

        min-length = 3;
        max-length = 3;

        tooltip = true;
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

        # The right click changes what the EC is allowed to do, and the resulting
        # state reaches the bar late enough to feel broken. Poll faster.
        interval = 5;

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

        # The pack sits at the window's stop threshold with AC attached. Waybar
        # promotes sysfs's "Not charging" to "Plugged" while the adapter is
        # online, so the key is the promoted name, not the raw status.
        format-plugged = "󰚥 {capacity}%";

        # Top up to 100% before leaving, or cancel it if already armed (see
        # battery-toggle above). No password: polkit allows exactly these units,
        # and the notification reports which way the click went.
        on-click-right = "${battery-toggle}";

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
