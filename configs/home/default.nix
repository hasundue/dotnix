{ pkgs, config, ... }:
{
  home = {
    packages = with pkgs; [
      ketch
      deno
      nodejs
      julia-bin
      python3
      tree
    ];
    stateVersion = "26.05";
    username = "hasundue";
  };
  imports = [
    ./agenix
    ./fish.nix
    ./git.nix
    ./ketch.nix
    ./syncthing.nix
    ./gh.nix
    ./lazygit.nix
    ./mcp.nix
    ./neovim.nix
    ./nix.nix
    ./pi
    ./television.nix
    ./worktrunk.nix
  ];
  programs = {
    rpiv-sync = {
      enable = true;
      remote = "git@github.com:hasundue/rpiv.git";
      projects = {
        dotnix = {
          # storePath defaults to "dotnix" (from attr key)
          # worktreeGlob defaults to "dotnix*" (derived from primaryWorktreePath at runtime)
          primaryWorktreePath = "${config.home.homeDirectory}/dotnix";
        };
        rpiv-mono = {
          # storePath defaults to "rpiv-mono" (from attr key)
          # worktreeGlob stays null (standalone, no worktrees)
          primaryWorktreePath = "${config.home.homeDirectory}/rpiv-mono";
        };
      };
    };
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
