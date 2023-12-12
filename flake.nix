{
  description = "hasundue's NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    base16-schemes = {
      url = "github:tinted-theming/base16-schemes";
      flake = false;
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    hasundue-neovim = {
      url = "git+file:./users/hasundue/core/neovim?dir=nix&ref=main";
    };
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    neovim-nightly = {
      url = "github:nix-community/neovim-nightly-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-hardware.url = "github:nixos/nixos-hardware";
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };
  };

  outputs = { self, nixpkgs, devshell, flake-utils, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ devshell.overlays.default ];
        };
      in
      {
        devShells.default = import ./nix/shell.nix { inherit pkgs; };
      }
    ) //
    {
      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [ ./hosts/x1carbon ];
          specialArgs = inputs;
        };
      };
    };
}
