{ pkgs, modulesPath, nixos-hardware, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme

    ../../core
    ../../graphical

    ../../users/hasundue

    # Machine specific user configuration
    ./users/hasundue
  ];

  boot = {
    initrd = {
      availableKernelModules = [ "xhci_pci" "nvme" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ ];
      systemd.enable = true;
    };
    kernelModules = [ "kvm-intel" ];
    loader.systemd-boot.enable = true;
    plymouth.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      brightnessctl
    ];
  };

  fileSystems = {
    "/" = {
      device = "/dev/disk/by-uuid/b84708e4-8ed1-4a7b-bd3e-99943c9cbe9d";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/7DC9-656E";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  };

  hardware = {
    bluetooth.enable = true;
    brillo.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ libva ];
    };
    pulseaudio.enable = false;
  };

  networking = {
    hostName = "x1carbon";
    networkmanager.enable = true;
  };

  security.pam = {
    services.login.fprintAuth = false;
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
    avahi.enable = true; # for geoclue2
    fprintd = {
      enable = false;
      tod = {
        # enable = true;
        # TODO: use a driver for vfs0097 instead
        # driver = pkgs.libfprint-2-tod1-vfs0090;
      };
    };
    geoclue2 = {
      enable = true;
      enable3G = false;
      enableCDMA = false;
      enableNmea = true;
      enableWifi = true;
      enableModemGPS = false;
      # FIXME: https://github.com/NixOS/nixpkgs/issues/321121
      geoProviderUrl = "https://api.beacondb.net/v1/geolocate";
    };
    pipewire.enable = true;
    upower.enable = true;
  };

  virtualisation.docker.enable = true;
}
