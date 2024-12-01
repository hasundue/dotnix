{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
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

  home-manager = {
    users.hasundue.imports = [ ../../home/desktop ];
  };

  programs = {
    regreet.enable = true;
    sway.enable = true;
  };

  stylix = {
    cursor = {
      name = "Nordzy-cursors";
      package = pkgs.nordzy-cursor-theme;
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.95;
    };
  };
}
