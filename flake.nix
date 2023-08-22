{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    config-private = {
      url = "git+https://github.com/hasundue/nixos-config-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    nixpkgs,
    nixos-hardware,
    nix-colors,
    home-manager,
    ...
  }: let
    stateVersion = "23.05";
    system = "x86_64-linux";

    caches = { pkgs, config, ... }: {
      nix = {
        settings = {
          # add binary caches for nixpkgs and home-manager
          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
          ];
          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
          ];
        };
      };
    };

    home = [
      home-manager.nixosModules.home-manager
      {
        home-manager = {
          extraSpecialArgs = { 
            inherit stateVersion;
            inherit nix-colors;
          };
          useGlobalPkgs = true;
          useUserPackages = true;
          users = {
            shun = import ./users/shun;
          };
        };
      }
    ];

    defaultModules = [ caches ] ++ home;

    networks = inputs.config-private.nixosModules.networks;

    defaultSpecialArgs = {
      inherit inputs;
      inherit nixos-hardware;
      inherit home-manager;
      inherit stateVersion;
    };
  in {
    nixosConfigurations = {
      # Thinkpad X1 Carbon 5th Gen
      x1carbon = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          ./hosts/x1carbon.nix
          ./system/default.nix
          networks.default
        ] ++ defaultModules;
        specialArgs = defaultSpecialArgs;
      };
    };
  };
}
