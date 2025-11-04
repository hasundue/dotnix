let
  pkgs = import <nixpkgs> {
    overlays = import <nixpkgs-overlays>;
  };
  neovim = pkgs.nvim.dev.extend (
    with pkgs.nvim.exts;
    [
      nix
    ]
  );
in
pkgs.mkShell {
  packages = with pkgs; [
    neovim
    just
    pre-commit
  ];
}
