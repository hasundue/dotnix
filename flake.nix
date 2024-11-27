{
  description = "hasundue's system configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox-addons = {
      url = "sourcehut:~rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        flake-utils.follows = "flake-utils";
      };
    };

    neovim-flake = {
      url = "github:hasundue/neovim-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };
  };

  outputs = { self, nixpkgs, nixos-wsl, ... } @ inputs:
    inputs.flake-utils.lib.eachDefaultSystem
      (system: {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            inputs.devshell.overlays.default
            inputs.rust-overlay.overlays.default
          ];
        };
        devShells = import ./nix/shell.nix inputs system;
      }) //
    {
      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./hosts/x1carbon
            { nixpkgs.pkgs = self.pkgs.${system}; }
          ];
          specialArgs = inputs // {
            firefox-addons = inputs.firefox-addons.packages.${system};
            neovim-flake = inputs.neovim-flake.${system};
          };
        };
        # NixOS-WSL
        nixos = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            nixos-wsl.nixosModules.default
            {
              nixpkgs.pkgs = self.pkgs.${system};
              system.stateVersion = "24.05";
              wsl.enable = true;
            }
            ./hosts/wsl
          ];
          specialArgs = inputs // {
            neovim-flake = inputs.neovim-flake.${system};
          };
        };
      };
    };
}
