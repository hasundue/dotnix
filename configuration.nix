
# Global System Configuration 

{ inputs, lib, config, pkgs, ... }:

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
      dates = "daily";
      options = "--delete-older-than 7d";
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

  services.xserver = {
    enable = true;
    autorun = true;

    xkbOptions = "ctrl:nocaps";

    libinput = {
      enable = true;
      mouse = {
        #naturalScrolling = true;
      };
      touchpad = {
        tapping = true;
        naturalScrolling = true;
      };
    };

    displayManager = {
      lightdm = {
        enable = true;
      };
      session = [
        {
          manage = "window";
          name = "xsession";
          start = ''${pkgs.runtimeShell} $HOME/.xsession'';
        }
      ];
      defaultSession = "none+xsession";
    };
  };

  # Enable sound.
  sound.enable = true;

  # Hardwares
  hardware = {
    pulseaudio.enable = true;
    bluetooth.enable = true;
  };

  # System-wide packages
  environment = {
    systemPackages = with pkgs; [
      git
      vim
      zsh
    ];
    variables = {
      EDITOR = "vim";
      VISUAL = "vim";
    };
    pathsToLink = [
      "/share/zsh"
    ];
  };

  # Users
  users.users = {
    shun = {
      isNormalUser = true;
      extraGroups = [ "wheel" "nixbld" ];
      initialPassword = "password";
    };
  };

  system.stateVersion = "22.11";
}
