{ pkgs, ... }:
{
  home = {
    packages = with pkgs; [
      julia-bin
      tree
    ];
    stateVersion = "25.11";
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
