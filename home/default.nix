{ pkgs, ... }:

{
  home = {
    username = "hasundue";
    stateVersion = "25.05";

    packages = with pkgs; [
      act
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
    ./opencode
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
      stdlib = ''
        nix_direnv_manual_reload
      '';
    };
    fd.enable = true;
    zellij.enable = true;
  };
}
