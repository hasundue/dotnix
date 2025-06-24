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

  security.pam = {
    services.login.fprintAuth = lib.mkIf (config.services.fprintd.enable) true;
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

    # FIXME: use vfs0097 driver and enable this
    fprintd = {
      enable = false;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-vfs0090;
      };
    };

    geoclue2.enable = true;
    upower.enable = true;
  };
}
