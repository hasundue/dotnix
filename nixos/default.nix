{
  config,
  pkgs,
  lib,
  ...
}:

{
  imports = [
    ./nix.nix
    ./stylix.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";

  environment = {
    pathsToLink = [
      "/share/bash"
    ];
    systemPackages = with pkgs; [
      vim
    ];
  };

  home-manager = {
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    users.hasundue = {
      imports = [ ../home ];
    };
  };

  programs = {
    fish.enable = true;
    nix-ld = {
      enable = true;
      libraries = [ ];
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  services = {
    openssh.enable = true;
  };

  system = {
    stateVersion = "25.05";
  };

  users.users.hasundue = {
    createHome = true;
    description = "Shun Ueda";
    group = "hasundue";
    extraGroups = [
      "wheel"
      "docker"
    ]
    ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ]
    ++ lib.optionals config.programs.sway.enable [
      "audio"
      "input"
      "video"
    ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  users.groups.hasundue = { };

  virtualisation.docker.enable = true;
}
