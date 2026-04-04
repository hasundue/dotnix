{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      github-copilot-cli
      julia-bin
      lsof
      tree
    ];
    stateVersion = "26.05";
    username = "hasundue";
  };
  imports = [
    ./agenix
    ./fish.nix
    ./git.nix
    ./gh.nix
    ./lazygit.nix
    ./mcp
    ./neovim.nix
    ./nix.nix
    ./television.nix
    ./zed.nix
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
    jq.enable = true;
    ripgrep.enable = true;
    zellij.enable = true;
  };
}
