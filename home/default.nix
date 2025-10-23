{ pkgs, ... }:

{
  home = {
    username = "hasundue";
    stateVersion = "25.05";

    packages = with pkgs; [
      act
      google-cloud-sdk
      jq
      just
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
    ./opencode
    ./television.nix
  ];

  programs = {
    direnv = {
      enable = true;
      config = {
        global = {
          warn_timeout = "0s"; # It often takes a while to re-evaluate a flake
        };
      };
      nix-direnv.enable = true;
      silent = true;
    };
    fd.enable = true;
    ripgrep.enable = true;
    zellij.enable = true;
  };
}
