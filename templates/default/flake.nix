{
  description = "A Nix flake for a standard development environment";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks-nix,
      treefmt-nix,
    }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forEachSystem =
        f:
        nixpkgs.lib.genAttrs systems (
          system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
              config.allowUnfree = false;
            };
            lib = nixpkgs.lib // {
              git-hooks-nix = git-hooks-nix.lib;
              treefmt-nix = treefmt-nix.lib;
            };
          }
        );
    in
    {
      devShells = forEachSystem (
        {
          pkgs,
          lib,
          system,
        }:
        let
          treefmt = lib.treefmt-nix.mkWrapper pkgs {
            programs.nixfmt = {
              enable = true;
            };
          };

          git-hooks = lib.git-hooks-nix.${system}.run {
            src = ./.;
            hooks = {
              treefmt = {
                enable = true;
                package = treefmt;
              };
            };
          };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              treefmt
              # Add your development dependencies here
            ];
            shellHook = git-hooks.shellHook;
          };
        }
      );

      packages = forEachSystem (
        { pkgs, ... }:
        {
          default = pkgs.hello; # Replace with your package
        }
      );
    };
}
