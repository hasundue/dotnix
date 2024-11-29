{ pkgs, lib, ... } @ args:

lib.mapAttrs (name: path: pkgs.mkShell ((import path) args)) rec {
  deno = ./deno.nix;
  nix = ./nix.nix;
  default = nix;
}
