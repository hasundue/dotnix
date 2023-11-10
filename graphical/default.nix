{ pkgs, ... }:

{
  imports = [
    ./fonts.nix
  ];

  # silent boot for plymouth
  boot = {
    consoleLogLevel = 0;
    kernelParams = [
      "quiet"
      "udev.log_level=3"
    ];
  };

  programs.dconf.enable = true;

  services = {
    dbus.packages = with pkgs; [ dconf ];
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
    targets = {
      gtk.enable = true;
      plymouth.enable = true;
    };
  };
}
