{ pkgs, lib, ... } @ args:

let
  mkScript = alias: command:
    pkgs.writeShellScriptBin alias command;

  mkShell =
    { aliases ? { }
    , packages ? [ ]
    ,
    }:
    pkgs.mkShell {
      packages = packages ++ (lib.mapAttrsToList mkScript aliases);
    };
in
lib.mapAttrs (name: path: mkShell ((import path) args)) rec {
  deno = ./deno.nix;
  nix = ./nix.nix;
  default = nix;
}
