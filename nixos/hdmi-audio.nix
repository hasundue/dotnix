{ pkgs, ... }:

let
  # Script to handle HDMI audio switching
  hdmiAudioScript = pkgs.writeShellScript "hdmi-audio-handler" ''
    # Wait for system to be ready
    sleep 2

    # Check if any HDMI output is connected
    hdmi_connected=false
    for hdmi_device in /sys/class/drm/card*-HDMI-A-*; do
      if [ -r "$hdmi_device/status" ] && [ "$(cat "$hdmi_device/status")" = "connected" ]; then
        hdmi_connected=true
        break
      fi
    done

    # Switch audio profile based on HDMI connection status
    if [ "$hdmi_connected" = "true" ]; then
      ${pkgs.wireplumber}/bin/wpctl set-profile 48 3
      if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
        ${pkgs.libnotify}/bin/notify-send "Audio Profile" "Switched to HDMI audio"
      fi
    else
      ${pkgs.wireplumber}/bin/wpctl set-profile 48 1
      if [ -n "$WAYLAND_DISPLAY" ] || [ -n "$DISPLAY" ]; then
        ${pkgs.libnotify}/bin/notify-send "Audio Profile" "Switched to internal audio"
      fi
    fi
  '';

in
{
  # Udev rules for HDMI hotplug detection
  services.udev.extraRules = ''
    # HDMI status change - run the same script which will detect actual state
    ACTION=="change", SUBSYSTEM=="drm", KERNEL=="card*-HDMI-A-*", RUN+="${hdmiAudioScript}"
  '';
}
