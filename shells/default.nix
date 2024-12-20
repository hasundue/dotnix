{ pkgs, lib, ... } @ args:

let
  mkScript = alias: command:
    pkgs.writeShellScriptBin alias ''
      exec ${command} "$@"
    '';
  mkShell =
    { aliases ? { }
    , packages ? [ ]
    ,
    }:
    pkgs.mkShellNoCC {
      packages = packages ++ (lib.mapAttrsToList mkScript aliases);
    };
in
lib.mapAttrs (name: path: mkShell ((import path) args)) rec {
  deno = ./deno.nix;
  nix = ./nix.nix;
  default = nix;
}
