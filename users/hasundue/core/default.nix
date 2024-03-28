{ schemes, pkgs, stylix, ... }:

{
  imports = [
    stylix.homeManagerModules.stylix

    ./fish.nix
    ./git.nix
    ./neovim
    ./xdg.nix
  ];

  home = {
    username = "hasundue";
    stateVersion = "23.11";
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

  stylix = {
    base16Scheme = "${schemes}/base16/kanagawa.yaml";
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
