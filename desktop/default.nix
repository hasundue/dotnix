{ pkgs, firefox-addons, ... }:

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
    extraSpecialArgs = {
      inherit firefox-addons;
    };
    users.hasundue = import ./home.nix;
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
    image = pkgs.fetchurl {
      url = "https://upload.wikimedia.org/wikipedia/commons/a/a5/Tsunami_by_hokusai_19th_century.jpg";
      hash = "sha256-MMFwJg3jk/Ub1ZKtrMbwcUtg8VfAl0TpxbbUbmphNxg=";
    };
    opacity = {
      applications = 0.9;
      desktop = 0.9;
      popups = 0.9;
      terminal = 0.95;
    };
  };
}
