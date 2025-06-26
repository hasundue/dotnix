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
    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
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
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nvim = {
      url = "github:hasundue/nvim";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib =
        builtins
        // nixpkgs.lib
        // {
          git-hooks-nix = inputs.git-hooks-nix.lib;
          treefmt-nix = inputs.treefmt-nix.lib;
        };

      overlays = with inputs; [
        self.overlays.default
        agenix.overlays.default
        nvim.overlays.default
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
        ) (lib.readDir ./shells)
      );

      formatter = forEachSystem (
        { pkgs, ... }: (inputs.treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper
      );

      nixosConfigurations = {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = nixosSystem "x86_64-linux" [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
          ./hosts/x1carbon
        ];
        # NixOS-WSL
        nixos = nixosSystem "x86_64-linux" [
          inputs.nixos-wsl.nixosModules.default
          ./hosts/wsl
        ];
      };

      overlays = import ./overlays;
    };
}
