{ config, pkgs, lib, nixos-hardware, ... }:

with lib;

{
  imports = [
    ./hardware-configuration.nix
    nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme

    ../../core
    ../../dev
    ../../desktop
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
    services.login.fprintAuth = mkIf (config.services.fprintd.enable) true;
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
    avahi.enable = mkIf (config.services.geoclue2.enable) true;

    # FIXME: use vfs0097 driver and enable this
    fprintd = {
      enable = false;
      tod = {
        enable = true;
        driver = pkgs.libfprint-2-tod1-vfs0090;
      };
    };

    # FIXME: https://github.com/NixOS/nixpkgs/issues/321121
    geoclue2 = {
      enable = true;
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    };

    pipewire.enable = true;
    upower.enable = true;
  };
}
