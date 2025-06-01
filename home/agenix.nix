{ config, pkgs, lib, ... }:

let
  h = config.home.homeDirectory;

  secrets = lib.mapAttrs'
    (name: value: {
      name = lib.removeSuffix ".age" name;
      value.file = ./secrets/${name};
    })
    (import ./secrets/secrets.nix);
in
{
  age = {
    inherit secrets;
    identityPaths = [ "${h}/.ssh/id_ed25519" ];
    secretsDir = "${h}/.agenix/secrets";
    secretsMountPoint = "${h}/.agenix/secrets.d";
  };

  home.packages = with pkgs; [ agenix ];
}
