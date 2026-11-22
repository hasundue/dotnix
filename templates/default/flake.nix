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
      inherit (nixpkgs) lib;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      packages = lib.genAttrs systems (
        system:
        import nixpkgs {
          inherit system;
        }
      );
      forEachSystem = f: lib.genAttrs systems (s: f packages.${s});
      perSystem = forEachSystem (
        pkgs:
        let
          inherit (pkgs.stdenv.hostPlatform) system;
          treefmt = treefmt-nix.lib.mkWrapper pkgs {
            programs = {
              nixfmt.enable = true;
              oxfmt.enable = true;
            };
          };
          git-hooks = git-hooks-nix.lib.${system}.run {
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
          inherit pkgs treefmt;
          shellHook = git-hooks.shellHook;
          configFile = git-hooks.config.configFile;
        }
      );
    in
    {
      devShells = lib.mapAttrs (_: p: {
        default = p.pkgs.mkShell {
          packages = with p.pkgs; [
            nil
            oxfmt
            treefmt
          ];
          shellHook = p.shellHook;
        };
      }) perSystem;
      formatter = lib.mapAttrs (_: p: p.treefmt) perSystem;
      packages = lib.mapAttrs (_: p: { pre-commit-config = p.configFile; }) perSystem;
    };
}
