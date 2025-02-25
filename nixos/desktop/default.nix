{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
    ./steam.nix
  ];

  # Enable plymouth and boot silently
  boot = {
    plymouth.enable = true;
    initrd.systemd.enable = true;

    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };

  environment.pathsToLink = [
    "/share/xdg-desktop-portal"
    "/share/applications"
  ];

  home-manager = {
    users.hasundue.imports = [ ../../home/desktop ];
  };

  # Make sure not to interfere swaylock from home-manager
  # https://github.com/NixOS/nixpkgs/issues/158025
  security.pam.services.swaylock = { };

  services = {
    pipewire = {
      enable = true;
      pulse.enable = true;
    };
    pulseaudio.enable = false;
  };

  stylix = {
    cursor = {
      name = "catppuccin-mocha-dark-cursors";
      package = pkgs.catppuccin-cursors.mochaDark;
      size = 24;
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.95;
    };
  };
}
