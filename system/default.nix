{ pkgs, stateVersion, ... }:

{
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
    config.allowUnfree = true;
  };

  i18n = {
    defaultLocale = "en_US.UTF-8";
    supportedLocales = [
      "en_US.UTF-8/UTF-8"
      "ja_JP.UTF-8/UTF-8"
    ];
  };

  console = {
    font = "Lat2-Terminus16";
    useXkbConfig = true;
  };

  fonts = {
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

  virtualisation.docker = {
    enable = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };

  users.users = {
    shun = {
      isNormalUser = true;
      extraGroups = [ "wheel" "nixbld" "input" "video" "audio" "docker" ];
      initialPassword = "password";
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  services = {
    upower.enable = true;
  };

  programs = {
    dconf.enable = true;
  };

  system = {
    inherit stateVersion;
  };
}
