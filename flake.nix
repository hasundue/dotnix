{
  description = "hasundue's system configuration";
  inputs = {
    # Official NixOS Registries
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    nixos-hardware.url = "github:nixos/nixos-hardware";
    # Nix-Community Projects
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
    # 3rd Party Projects
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
    mcp-nixos = {
      url = "github:utensils/mcp-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    niri.url = "github:sodiboo/niri-flake";
    python-validity = {
      url = "github:viktor-grunwaldt/t480-fingerprint-nixos";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
        uv2nix.follows = "uv2nix";
      };
    };
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        pyproject-nix.follows = "pyproject-nix";
      };
    };
    # My Personal Projects
    nvim = {
      url = "github:hasundue/nvim";
    };
  };
  outputs =
    {
      agenix,
      home-manager,
      niri,
      nixpkgs,
      nixpkgs-master,
      nvim,
      self,
      stylix,
      ...
    }@inputs:
    let
      lib = nixpkgs.lib;
      overlays = builtins.attrValues self.overlays ++ [
        agenix.overlays.default
        niri.overlays.niri
        nvim.overlays.default
      ];
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      pkgsFor = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit overlays system;
          config.allowUnfree = true;
        }
        // self.packages.${system}
      );
      metaConfig = system: {
        # Make sure to avoid evaluation of nixpkgs
        _module.args.pkgs = lib.mkForce pkgsFor.${system};
        # Consumed by ./nixos/_overlays-compat.nix
        nix.nixPath = [ "nixos-config=${self.outPath}" ];
        nixpkgs.overlays = overlays;
      };
      nixosMetaConfig = {
        home-manager.sharedModules = [
          agenix.homeManagerModules.default
        ];
      };
      nixosSystem =
        name:
        { system, modules }:
        lib.nixosSystem {
          inherit system;
          modules = [
            niri.nixosModules.niri
            home-manager.nixosModules.home-manager
            stylix.nixosModules.stylix
            (metaConfig system)
            nixosMetaConfig
            ./configs/stylix.nix
          ]
          ++ modules;
        };
      username = "hasundue";
      homeMetaConfigs = {
        home.homeDirectory = "/home/${username}";
      };
      homeConfig =
        pkgs:
        home-manager.lib.homeManagerConfiguration {
          inherit pkgs;
          modules = [
            agenix.homeManagerModules.default
            niri.homeModules.niri
            stylix.homeModules.stylix
            (metaConfig pkgs.stdenv.hostPlatform.system)
            homeMetaConfigs
            ./configs/home
          ];
        };
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
    in
    {
      devShells = forEachSystem (
        pkgs:
        lib.mapAttrs' (
          name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (
            import ./shells/${name} {
              inherit pkgs;
              inherit (inputs) git-hooks-nix treefmt-nix;
            }
          )
        ) (builtins.readDir ./shells)
      );
      nixosConfigurations = lib.mapAttrs nixosSystem {
        # Thinkpad X1 Carbon 5th Gen
        x1carbon = {
          system = "x86_64-linux";
          modules = with inputs; [
            nixos-hardware.nixosModules.lenovo-thinkpad-x1-extreme
            python-validity.nixosModules."06cb-009a-fingerprint-sensor"
            ./configs/hosts/x1carbon
          ];
        };
        # NixOS-WSL
        nixos = {
          system = "x86_64-linux";
          modules = with inputs; [
            nixos-wsl.nixosModules.default
            ./configs/hosts/wsl
          ];
        };
      };
      overlays = import ./overlays // {
        pristine = import ./overlays/pristine.nix {
          inherit (inputs)
            firefox-addons
            mcp-nixos
            ;
        };
        temporal = import ./overlays/temporal.nix {
          opencode = nixpkgs-master;
        };
      };
      packages = forEachSystem (pkgs: {
        zotero-mcp = pkgs.callPackage ./packages/zotero-mcp.nix {
          inherit (inputs)
            pyproject-build-systems
            pyproject-nix
            uv2nix
            ;
        };
        homeConfigurations.${username} = homeConfig pkgs;
      });
      templates = {
        default = {
          path = ./templates/default;
          description = "A minimal Nix flake template";
        };
      };
    };
}
