{ pkgs, ... }:

{
  imports = [
    ./fish.nix
    ./git.nix
    ./neovim.nix
    ./xdg.nix
  ];

  home = {
    packages = (with pkgs; [
      asciinema
      asciinema-agg
      bat
      dust
      fastfetch
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
