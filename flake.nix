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

    firefox-addons = {
      url = "sourcehut:~rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    stylix = {
      url = "github:danth/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    nvim = {
      url = "github:hasundue/nvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
  };

  outputs = { nixpkgs, home-manager, stylix, nvim, ... } @ inputs:
    let
      inherit (nixpkgs) lib;

      forSystem = system: f: f {
        inherit lib;
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [
            nvim.overlays.default
            (final: prev: {
              firefox-addons = inputs.firefox-addons.packages.${system};
            })
          ];
        };
      };

      forEachSystem = f: lib.genAttrs
        [ "x86_64-linux" "aarch64-linux" ]
        (system: forSystem system f);

      nixosSystem = system: host: forSystem system (args: lib.nixosSystem {
        inherit system;
        modules = [
          { nixpkgs.pkgs = args.pkgs; }
          home-manager.nixosModules.home-manager
          stylix.nixosModules.stylix
          host
        ];
        specialArgs = {
          inherit (inputs) nixos-hardware nixos-wsl;
        };
      });

      homeConfig = args: home-manager.lib.homeManagerConfiguration {
        inherit (args) pkgs;
        modules = [ ./home ];
      };
    in
    {
      devShells = forEachSystem (import ./shells);

      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixosSystem "x86_64-linux" ./hosts/x1carbon;
        # NixOS-WSL
        nixos = nixosSystem "x86_64-linux" ./hosts/wsl;
      };

      homeConfigurations = forEachSystem homeConfig;
    };
}
