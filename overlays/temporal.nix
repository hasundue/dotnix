sources: _: prev:
let
  inherit (prev.stdenv.hostPlatform) system;
  overridePackage = name: nixpkgs: nixpkgs.legacyPackages.${system}.${name};
in
prev.lib.mapAttrs overridePackage sources
