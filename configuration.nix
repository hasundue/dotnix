
# Global System Configuration 

{ pkgs, ... }:

{
  imports = [
    ./hardware-configuration.nix
  ];

  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 5";
    };
    package = pkgs.nixFlakes;
    settings = {
      auto-optimise-store = true;
      trusted-users = [ "root" "@wheel" ];
    };
  };

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Asia/Tokyo";

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
    extraLocaleSettings = {
      # Extra locale settings that need to be overwritten
      # LC_TIME = "ja_JP.UTF-8";
      # LC_MONETARY = "ja_JP.UTF-8";
    };
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts = {
    enableDefaultFonts = true;
    fontconfig = {
      defaultFonts = {
        serif = [ "Source Han Serif" ];
        sansSerif = [ "Source Han Sans" ];
        monospace = [ "Source Han Mono" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
    fonts = with pkgs; [
      noto-fonts-emoji

      source-han-serif
      source-han-sans
      source-han-mono

      (nerdfonts.override {
        fonts = [ "FiraCode" ];
      })
    ];
  };

  networking = {
    hostName = "x1carbon";
    wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  };

  # Hardwares
  hardware = {
    pulseaudio.enable = true;
    bluetooth.enable = true;

    opengl = {
      enable = true;
      # driSupport32Bit = true;
      # Required for steam
      extraPackages32 = with pkgs.pkgsi686Linux; [ libva ];
    };
  };

  # Enable sound
  sound = {
    enable = true;
    mediaKeys.enable = true;
  };

  # Display backlight
  services.actkbd = {
    enable = true;
    bindings = [
      { keys = [ 232 ]; events = [ "key" ]; command = "brightnessctl s 10%-"; }
      { keys = [ 233 ]; events = [ "key" ]; command = "brightnessctl s +10%"; }
    ];
  };

  # System-wide packages
  environment = {
    systemPackages = with pkgs; [
      brightnessctl
      usbutils
      gcc
      git
      vim
      zsh
    ];
    variables = {
      SHELL = "zsh";
      EDITOR = "vim";
      VISUAL = "vim";
    };
    pathsToLink = [
      "/share/zsh"
    ];
  };

  services.fprintd = {
    enable = true;
    tod = {
      enable = true;
      driver = pkgs.libfprint-2-tod1-vfs0090;
    };
  };

  users.groups.video = {};
  users.groups.input = {};

  # Users
  users.users = {
    shun = {
      isNormalUser = true;
      extraGroups = [ "wheel" "nixbld" "input" "video" "audio" ];
      initialPassword = "password";
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
    pam = {
      services = {
        login.fprintAuth = true;
      };
    };
    polkit.enable = true;
  };

  programs.dconf.enable = true;

  system.stateVersion = "23.05";
}
