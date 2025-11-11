{
  pkgs,
  treefmt-nix,
  git-hooks-nix,
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  treefmt = treefmt-nix.lib.mkWrapper pkgs {
    programs.nixfmt = {
      enable = true;
    };
  };
  git-hooks = git-hooks-nix.lib.${system}.run {
    src = ../.;
    hooks = {
      treefmt = {
        enable = true;
        package = treefmt;
      };
    };
  };
in
pkgs.mkShellNoCC {
  packages = with pkgs; [
    nil
    nixd
    nixfmt
    treefmt
  ];
  shellHook = git-hooks.shellHook;
}
