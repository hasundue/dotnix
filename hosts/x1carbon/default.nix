{ config, pkgs, lib, nixos-hardware, ... }:

{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme

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
    bluetooth.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ libva ];
    };
    pulseaudio.enable = false; # use pipewire instead
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
        { keys = [ 232 ]; events = [ "key" ]; command = "brightnessctl set 5%-"; }
        { keys = [ 233 ]; events = [ "key" ]; command = "brightnessctl set +5%"; }
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

    geoclue2 = {
      enable = true;
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    };

    pipewire.enable = true;
    upower.enable = true;
  };

  virtualisation.docker.enable = true;
}
