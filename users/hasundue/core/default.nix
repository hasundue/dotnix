{ base16-schemes, pkgs, stylix, ... }:

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
    stateVersion = "23.05";
    packages = (with pkgs; [ 
      fd
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
    base16Scheme = "${base16-schemes}/kanagawa.yaml";
  };

  xdg.configFile."nixpkgs/config.nix".text = "{ allowUnfree = true; }";
}
