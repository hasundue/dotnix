{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-22.11";
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    nix-colors.url = "github:misterio77/nix-colors";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    private = {
      url = "git+https://github.com/hasundue/nixos-config-private.git";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ 
    nixpkgs,
    nixos-hardware,
    nix-colors,
    home-manager,
    private,
    ...
  }: {
    nixosConfigurations = {
      x1carbon = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [ 
          ./configuration.nix
          private.nixosModules.default
          nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.shun = import ./home.nix;
            home-manager.extraSpecialArgs = { inherit nix-colors; };
          }
        ];
      };
    };
  };
}
