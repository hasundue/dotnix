{
  description = "hasundue's NixOS configuration";

  nixConfig = {
    extra-trusted-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.05";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly.url = "github:nix-community/neovim-nightly-overlay";

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    schemes = {
      url = "github:tinted-theming/schemes";
      flake = false;
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    neovim-config = {
      url = "git+file:./users/hasundue/core/neovim?dir=nix&ref=main";
    };
  };

  outputs = { self, nixpkgs, nixpkgs-master, flake-utils, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem
      (system: {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [ self.overlays.default ];
        };
        pkgs-master = import nixpkgs-master {
          inherit system;
        };
        devShells = import ./nix/shell.nix inputs system;
      }) //
    {
      overlays = import ./nix/overlay.nix inputs;
      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixpkgs.lib.nixosSystem rec {
          system = "x86_64-linux";
          modules = [
            ./hosts/x1carbon
            { nixpkgs.pkgs = self.pkgs.${system}; }
          ];
          specialArgs = inputs // {
            inherit system;
            pkgs-master = self.pkgs-master.${system};
          };
        };
      };
    };
}
