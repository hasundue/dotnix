{ pkgs, base16-schemes, ... }:

{
  imports = [
    ./nixos.nix
    ./nix.nix
  ];

  environment = {
    pathsToLink = [
      "/share/bash"
      "/share/fish"
      "/share/zsh"
    ];
    systemPackages = with pkgs; [
      neovim
      vim
    ];
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  nixpkgs = {
    config.allowUnfree = true;
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
  };

  stylix = {
    base16Scheme = "${base16-schemes}/kanagawa.yaml";
    homeManagerIntegration.autoImport = false;
  };
}
