{
  description = "hasundue's system configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
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
    nixpkgs-wayland = {
      url = "github:nix-community/nixpkgs-wayland";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-compat.follows = "flake-compat";
      inputs.lib-aggregate.inputs.flake-utils.inputs.systems.follows = "systems";
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
        nixpkgs-wayland.overlays.default
        nvim.overlays.default
        self.overlays.default
      ];

      firefox-overlay =
        system:
        (final: prev: {
          firefox-addons = inputs.firefox-addons.packages.${system};
        });

      forSystem =
        system: f:
        f {
          inherit lib;
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = overlays ++ [ (firefox-overlay system) ];
          };
        };

      forEachSystem = f: lib.genAttrs [ "x86_64-linux" "aarch64-linux" ] (system: forSystem system f);

      nixosSystem =
        system: modules:
        forSystem system (
          args:
          lib.nixosSystem {
            inherit system;
            modules =
              with inputs;
              [
                { nixpkgs.pkgs = args.pkgs; }
                {
                  home-manager.sharedModules = [
                    agenix.homeManagerModules.default
                  ];
                }
                home-manager.nixosModules.home-manager
                stylix.nixosModules.stylix
              ]
              ++ modules;
          }
        );
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

      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixosSystem "x86_64-linux" [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          inputs.python-validity.nixosModules."06cb-009a-fingerprint-sensor"
          ./hosts/x1carbon
        ];
        # NixOS-WSL
        nixos = nixosSystem "x86_64-linux" [
          inputs.nixos-wsl.nixosModules.default
          ./hosts/wsl
        ];
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
