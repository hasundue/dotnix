{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      act
      google-cloud-sdk
      jq
      just
      julia-bin
      ngrok
      tree
    ];
    stateVersion = "25.05";
    username = "hasundue";
  };
  imports = [
    ./agenix
    ./claude-code
    ./fish.nix
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./mcp
    ./neovim.nix
    ./nix.nix
    ./opencode
    ./television.nix
  ];
  programs = {
    btop.enable = true;
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
