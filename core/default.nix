{ config, pkgs, lib, home-manager, stylix, ... }:

{
  imports = [
    home-manager.nixosModules.home-manager
    stylix.nixosModules.stylix
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
    extraSpecialArgs = {
      inherit stylix;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    users.hasundue = import ./home.nix;
  };

  nix = {
    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };
    package = pkgs.nixVersions.stable;
    settings = {
      accept-flake-config = true;
      allowed-users = [ "@wheel" ];
      auto-optimise-store = true;
      builders-use-substitutes = true;
      experimental-features = [ "nix-command" "flakes" ];
      substituters = [
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      trusted-users = [ "@wheel" ];
    };
  };

  security = {
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    polarity = "dark";
  };

  system = {
    stateVersion = "24.05";
  };

  users.users.hasundue = {
    createHome = true;
    description = "Shun Ueda";
    group = "hasundue";
    extraGroups = [ "wheel" ]
      ++ lib.optionals config.networking.networkmanager.enable [ "networkmanager" ]
      ++ lib.optionals config.programs.sway.enable [ "audio" "input" "video" ]
      ++ lib.optionals config.virtualisation.docker.enable [ "docker" ];
    isNormalUser = true;
  };

  users.groups.hasundue = { };
}
