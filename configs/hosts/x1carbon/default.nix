{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./hardware-configuration.nix

    ../../nixos
    ../../nixos/desktop
  ];

  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  environment = {
    systemPackages = with pkgs; [
      brightnessctl
    ];
  };

  hardware = {
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ libva ];
    };

    # nixos-hardware's generic ThinkPad profile (pulled in by the X1 Extreme
    # module) assumes the TrackPoint is named "TPPS/2 IBM TrackPoint", but this
    # machine reports "TPPS/2 ALPS TrackPoint". Without this override the
    # trackpoint udev rule and trackpoint.service match nothing.
    trackpoint.device = "TPPS/2 ALPS TrackPoint";
  };

  networking = {
    hostName = "x1carbon";
    networkmanager.enable = true;
  };

  # The RMI4 PS/2 pass-through (serio2) carries both the TrackPoint motion and
  # the three physical click buttons. After resume it occasionally stays
  # unbound from psmouse, which silently kills the buttons until reboot.
  # Re-bind it on every resume; the write fails harmlessly when already bound.
  powerManagement.resumeCommands = ''
    echo -n serio2 > /sys/bus/serio/drivers/psmouse/bind 2>/dev/null || true
    ${config.systemd.package}/bin/udevadm trigger \
      --action=add --attr-match=name="${config.hardware.trackpoint.device}"
  '';

  security.pam.services = {
    swaylock.fprintAuth = true;
  };

  # Allow btop to monitor Intel GPU usage without sudo
  security.wrappers.btop = {
    owner = "root";
    group = "root";
    source = lib.getExe pkgs.btop |> toString;
    capabilities = "cap_perfmon=+ep";
  };

  services = {
    actkbd = {
      enable = true;
      bindings = [
        {
          keys = [ 232 ];
          events = [ "key" ];
          command = "brightnessctl set 5%-";
        }
        {
          keys = [ 233 ];
          events = [ "key" ];
          command = "brightnessctl set +5%";
        }
      ];
    };
    automatic-timezoned.enable = true;
    avahi.enable = lib.mkIf (config.services.geoclue2.enable) true;

    # Support for Validity vfs0097 fingerprint reader using python-validity backend
    "06cb-009a-fingerprint-sensor" = {
      enable = true;
      backend = "python-validity";
    };

    geoclue2.enable = true;
    upower.enable = true;
  };
}
