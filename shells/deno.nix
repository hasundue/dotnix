{ pkgs, ... }:
pkgs.mkShellNoCC {
  packages = with pkgs; [ deno ];
}
