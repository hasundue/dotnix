{ pkgs, lib, ... } @ args:

let
  mkScript = alias: command:
    pkgs.writeShellScriptBin alias ''
      exec ${command} "$@"
    '';
  mkShell =
    { aliases ? { }
    , nativeBuildInputs ? [ ]
    , packages ? [ ]
    , shellHook ? ""
    ,
    }:
    pkgs.mkShell {
      inherit nativeBuildInputs shellHook;
      packages = packages ++ (lib.mapAttrsToList mkScript aliases);
    };
in
lib.mapAttrs (name: path: mkShell ((import path) args)) rec {
  deno = ./deno.nix;
  ebiten = ./ebiten.nix;
  nix = ./nix.nix;
  default = nix;
}
