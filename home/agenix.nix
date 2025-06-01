{ config, pkgs, lib, ... }:

{
  age = {
    identityPaths = [ "~/.ssh/id_ed25519" ];
    secrets = {
      # api-keys = {
      #   file = ../secrets/api-keys.age;
      # };
    };
    # secretsDir = "${config.home.homeDirectory}/.agenix/agenix";
    # secretsMountPoint = "${config.home.homeDirectory}/.agenix/agenix.d";
  };

  home.packages = with pkgs; [
    agenix
  ];

  # home.activation.agenix = lib.hm.dag.entryAnywhere config.systemd.user.services.agenix.Service.ExecStart;
}
