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
      availableKernelModules = [ "xhci_pci" "ahci" "usb_storage" "sd_mod" "rtsx_pci_sdmmc" ];
      kernelModules = [ "kvm-intel" ];
      systemd.enable = true;
    };
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
      device = "/dev/disk/by-uuid/0f031ba0-6020-4f3f-859f-fe71a309b9a2";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-uuid/6E77-9650";
      fsType = "vfat";
    };
  };

  hardware = {
    bluetooth.enable = true;
    brillo.enable = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [ libva ];
    };
    pulseaudio.enable = true;
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
      enableModemGPS = false;
      submitData = true;
    };
    upower.enable = true;
  };

  swapDevices = [
    { device = "/dev/disk/by-uuid/55a12afc-7e39-4b01-b7a7-314b7083383a"; }
  ];

  virtualisation.docker.enable = true;
}
