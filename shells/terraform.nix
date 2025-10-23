{ pkgs, ... }:

pkgs.mkShell {
  packages = with pkgs; [
    terraform
  ];
}
