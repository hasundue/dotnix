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
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
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

    home = [
      home-manager.nixosModules.home-manager
      {
        nixpkgs.overlays = [
          inputs.neovim-nightly.overlay
        ];
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
        ] ++ home;
        specialArgs = defaultSpecialArgs;
      };
    };
  };
}
