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

    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
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
    system = "x86_64-linux";
    wayland = { pkgs, config, ... }: {
      config = {
        nix = {
          settings = {
            trusted-public-keys = [
              "nixpkgs-wayland.cachix.org-1:3lwxaILxMRkVhehr5StQprHdEo4IrE8sRho9R9HOLYA="
            ];
            substituters = [ 
              "https://nixpkgs-wayland.cachix.org" 
            ];
          };
        };
        nixpkgs.overlays = [ inputs.nixpkgs-wayland.overlay ];
      };
    };
  in {
    nixosConfigurations = {
      x1carbon = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ 
          ./configuration.nix
          inputs.config-private.nixosModules.default
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          wayland
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { 
              inherit nix-colors;
            };
            home-manager.users.shun = import ./home.nix;
          }
        ];
      };
    };
  };
}
