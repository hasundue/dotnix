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
  };

  networking = {
    hostName = "x1carbon";
    networkmanager.enable = true;
  };

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
