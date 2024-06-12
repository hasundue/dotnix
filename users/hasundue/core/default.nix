{ pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./git.nix
    ./neovim
    ./xdg.nix
  ];

  home = {
    username = "hasundue";
    stateVersion = "24.05";
    packages = (with pkgs; [
      fd
      jq
      openssl
      ripgrep
      unzip
    ]);
    shellAliases = {
      la = "ls --all";
      ll = "ls -l";
    };
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
