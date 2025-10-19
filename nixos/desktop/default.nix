{ pkgs, ... }:

{
  imports = [
    ./bluetooth.nix
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

  environment = {
    pathsToLink = [
      "/share/xdg-desktop-portal"
      "/share/applications"
    ];
    sessionVariables = {
      # Define this globally to make sure it's imported to user systemd by sway
      NIXOS_OZONE_WL = "1";
    };
  };

  home-manager = {
    users.hasundue.imports = [ ../../home/desktop ];
  };

  programs.niri.enable = true;

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

  services.greetd = {
    enable = true;
    settings.default_session.command = "${pkgs.greetd}/bin/agreety --cmd niri-session";
    settings.initial_session = {
      command = "niri-session";
      user = "hasundue";
    };
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
