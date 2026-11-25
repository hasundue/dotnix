{
  pkgs,
  config,
  ...
}:
{
  home = {
    packages = with pkgs; [
      ketch
      deno
      nodejs
      julia-bin
      tree
      mdroll
    ];
    stateVersion = "26.05";
    username = "hasundue";
  };
  imports = [
    ./agenix
    ./delta.nix
    ./fish.nix
    ./git.nix
    ./ketch.nix
    ./syncthing.nix
    ./gh.nix
    ./herdr
    ./lazygit.nix
    ./mcp.nix
    ./neovim.nix
    ./nix.nix
    ./pi
    ./television.nix
    ./tmux.nix
    ./worktrunk
    ./zellij
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
  };
}
