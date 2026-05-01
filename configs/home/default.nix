{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      julia-bin
      tree
    ];
    stateVersion = "26.05";
    username = "hasundue";
  };
  imports = [
    ./agenix
    ./copilot.nix
    ./fish.nix
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./mcp.nix
    ./neovim.nix
    ./nix.nix
    ./opencode
    ./television.nix
  ];
  programs = {
    mcp.enable = true;
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
    jq.enable = true;
    ripgrep.enable = true;
    zellij.enable = true;
  };
}
