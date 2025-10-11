{ pkgs, ... }:

{
  home = {
    username = "hasundue";
    stateVersion = "25.05";

    packages = with pkgs; [
      google-cloud-sdk
      jq
      ngrok
      tree
    ];
  };

  imports = [
    ./agenix.nix
    ./claude-code
    ./fish.nix
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./neovim.nix
    ./nix.nix
  ];

  programs = {
    direnv = {
      enable = true;
      config = {
        silent = true;
        global = {
          warn-timeout = 0; # It often takes a while to re-evaluate a flake
        };
      };
      nix-direnv.enable = true;
    };
    fd.enable = true;
    zellij.enable = true;
  };
}
