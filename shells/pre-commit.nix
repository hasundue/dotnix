{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [ pre-commit ];
}
