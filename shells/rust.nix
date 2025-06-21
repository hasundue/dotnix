{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    cargo-cross
    rustup
  ];
}
