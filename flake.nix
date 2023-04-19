{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    nixos-hardware.url = "github:nixos/nixos-hardware";
    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager/release-22.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private = {
      url = "git+https://github.com/hasundue/nixos-config-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ 
    nixpkgs,
    nixpkgs-unstable,
    nixpkgs-master,
    nixos-hardware,
    nix-colors,
    home-manager,
    private,
    ...
  }: let
    system = "x86_64-linux";
    pkgs-unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
    pkgs-master = import nixpkgs-master {
      inherit system;
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations = {
      x1carbon = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [ 
          ./configuration.nix
          private.nixosModules.default
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.extraSpecialArgs = { 
              inherit pkgs-unstable;
              inherit pkgs-master;
              inherit nix-colors;
            };
            home-manager.users.shun = import ./home.nix;
          }
        ];
      };
    };
  };
}
