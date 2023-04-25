{ pkgs, stateVersion, ... }:

{
  nix = {
    extraOptions = ''
      experimental-features = nix-command flakes
    '';
    gc = {
      automatic = true;
      options = "--delete-older-than 10";
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
  };

  system = {
    inherit stateVersion;
  };
}
