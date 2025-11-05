{
  description = "hasundue's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-opencode-0_15_14.url = "github:nixos/nixpkgs?ref=876df71365b3c0ab2d363cd6af36a80199879430";
    nixos-hardware.url = "github:nixos/nixos-hardware";

    systems.url = "github:nix-systems/default";

    flake-compat = {
      url = "github:nix-community/flake-compat";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-wsl = {
      url = "github:nix-community/nixos-wsl";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.systems.follows = "systems";
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        systems.follows = "systems";
      };
    };
    firefox-addons = {
      url = "sourcehut:~rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs = {
        nixpkgs.follows = "nixpkgs";
      };
    };
    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
    };
    niri.url = "github:sodiboo/niri-flake";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim = {
      url = "github:hasundue/nvim";
    };

    python-validity = {
      url = "github:viktor-grunwaldt/t480-fingerprint-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib // {
        git-hooks-nix = inputs.git-hooks-nix.lib;
        treefmt-nix = inputs.treefmt-nix.lib;
      };

      overlays = with inputs; [
        agenix.overlays.default
        niri.overlays.niri
        nvim.overlays.default
        self.overlays.default
        (final: prev: {
          inherit (import nixpkgs-opencode-0_15_14 { inherit (final) system; }) opencode;
          firefox-addons = firefox-addons.packages.${final.system};
        })
      ];

      forSystem =
        system: f:
        f {
          inherit lib;
          pkgs = import nixpkgs {
            inherit system overlays;
            config.allowUnfree = true;
          };
        };

      forEachSystem = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: forSystem system f);

      nixosSystem =
        name:
        { system, modules }:
        lib.nixosSystem {
          inherit system;
          modules =
            with inputs;
            [
              {
                home-manager.sharedModules = [
                  agenix.homeManagerModules.default
                ];
                nix.nixPath = [
                  "nixos-config=${self.outPath}"
                ];
                nixpkgs = {
                  inherit overlays;
                  config.allowUnfree = true;
                };
              }
              niri.nixosModules.niri
              home-manager.nixosModules.home-manager
              stylix.nixosModules.stylix
            ]
            ++ modules;
        };
    in
    {
      devShells = forEachSystem (
        args:
        lib.mapAttrs' (
          name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (
            import ./shells/${name} (args // { inherit inputs; })
          )
        ) (builtins.readDir ./shells)
      );

      nixosConfigurations = lib.mapAttrs nixosSystem {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = {
          system = "x86_64-linux";
          modules = [
            inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
            inputs.python-validity.nixosModules."06cb-009a-fingerprint-sensor"
            ./hosts/x1carbon
          ];
        };
        # NixOS-WSL
        nixos = {
          system = "x86_64-linux";
          modules = [
            inputs.nixos-wsl.nixosModules.default
            ./hosts/wsl
          ];
        };
      };

      overlays = import ./overlays;

      templates = {
        default = {
          path = ./templates/default;
          description = "A minimal Nix flake template";
        };
      };
    };
}
