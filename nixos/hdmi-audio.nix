{ pkgs, ... }:

let
  # Script to handle HDMI audio switching in user context
  hdmiAudioScript = pkgs.writeShellScript "hdmi-audio-handler" ''
    # Log for debugging
    echo "$(date): HDMI udev event triggered" >> /tmp/hdmi-debug.log

    # Run the actual audio switching in user context
    # Find the user running sway/wayland session
    for user_session in /run/user/*/; do
      user_id=$(basename "$user_session")
      if [ -S "$user_session/pipewire-0" ] || [ -S "$user_session/pulse/native" ]; then
        echo "$(date): Found audio session for user $user_id" >> /tmp/hdmi-debug.log
        
        # Run as the user with proper environment
        ${pkgs.sudo}/bin/sudo -u "#$user_id" \
          PIPEWIRE_RUNTIME_DIR="$user_session" \
          XDG_RUNTIME_DIR="$user_session" \
          ${userAudioScript}
        break
      fi
    done
  '';

  # The actual audio switching logic that runs as user
  userAudioScript = pkgs.writeShellScript "user-audio-handler" ''
    # Wait for system to be ready
    sleep 2

    # Check if any external display output is connected (HDMI or DP)
    external_connected=false
    for display_device in /sys/class/drm/card*-HDMI-A-* /sys/class/drm/card*-DP-*; do
      # Skip eDP (internal laptop display)
      if [[ "$display_device" == *"eDP"* ]]; then
        continue
      fi
      if [ -r "$display_device/status" ] && [ "$(cat "$display_device/status")" = "connected" ]; then
        external_connected=true
        break
      fi
    done

    echo "$(date): External display connected: $external_connected" >> /tmp/hdmi-debug.log

    # Switch audio profile based on external display connection status
    if [ "$external_connected" = "true" ]; then
      ${pkgs.wireplumber}/bin/wpctl set-profile 48 3
      echo "$(date): Set HDMI profile" >> /tmp/hdmi-debug.log
      if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
        ${pkgs.libnotify}/bin/notify-send "Audio Profile" "Switched to HDMI audio" 2>/dev/null || true
      fi
    else
      ${pkgs.wireplumber}/bin/wpctl set-profile 48 1
      echo "$(date): Set internal profile" >> /tmp/hdmi-debug.log
      if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
        ${pkgs.libnotify}/bin/notify-send "Audio Profile" "Switched to internal audio" 2>/dev/null || true
      fi
    fi
  '';

in
{
  # Udev rules for external display hotplug detection
  services.udev.extraRules = ''
    # External display status change - run script for HDMI and DP connectors
    ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card*-HDMI-A-*", RUN+="${hdmiAudioScript}"
    ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card*-DP-*", RUN+="${hdmiAudioScript}"
  '';
}
