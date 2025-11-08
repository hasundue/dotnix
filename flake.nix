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
    { self, nixpkgs, ... }@inputs:
    let
      lib = nixpkgs.lib;
      overlays = with inputs; [
        (
          final: prev:
          let
            inherit (prev.stdenv.hostPlatform) system;
          in
          {
            lib = prev.lib // {
              git-hooks-nix = inputs.git-hooks-nix.lib;
              pyproject-build-systems = inputs.pyproject-build-systems;
              pyproject-nix = inputs.pyproject-nix;
              treefmt-nix = inputs.treefmt-nix.lib;
              uv2nix = inputs.uv2nix.lib;
            };
            inherit (import nixpkgs-master { inherit system; }) opencode;
            firefox-addons = firefox-addons.packages.${system};
            mcp-nixos = mcp-nixos.packages.${system}.default;
          }
        )
        agenix.overlays.default
        niri.overlays.niri
        nvim.overlays.default
        self.overlays.default
        self.overlays.opencode
        self.overlays.zotero-mcp
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
      );
      forEachSystem = f: lib.genAttrs systems (system: f pkgsFor.${system});
      nixosSystem =
        name:
        { system, modules }:
        lib.nixosSystem {
          inherit system;
          modules =
            with inputs;
            [
              {
                # Make sure to avoid evaluation of nixpkgs
                _module.args.pkgs = lib.mkForce pkgsFor.${system};

                # Comsumed by ./nixos/_overlays-compat.nix
                nix.nixPath = [ "nixos-config=${self.outPath}" ];
                nixpkgs.overlays = overlays;

                home-manager.sharedModules = [
                  agenix.homeManagerModules.default
                ];
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
        pkgs:
        lib.mapAttrs' (
          name: _:
          lib.nameValuePair (lib.removeSuffix ".nix" name) (import ./shells/${name} { inherit pkgs; })
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
