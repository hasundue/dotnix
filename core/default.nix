{ pkgs, system, pkgs-master, schemes, stylix, ... }:

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
      vim
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit
        schemes
        pkgs-master
        stylix
        system;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs = {
    fish.enable = true;
    zsh.enable = true;
  };

  stylix = {
    base16Scheme = "${schemes}/base16/kanagawa.yaml";
    homeManagerIntegration.autoImport = false;
  };
}
