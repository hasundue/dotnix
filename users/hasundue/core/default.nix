{ pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./git.nix
    ./neovim
    ./xdg.nix
  ];

  home = {
    packages = (with pkgs; [
      bat
      dust
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

    stateVersion = "24.05";

    username = "hasundue";
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
