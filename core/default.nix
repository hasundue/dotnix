{ pkgs, system, pkgs-master, base16-schemes, stylix, ... }:

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
        base16-schemes
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
    base16Scheme = "${base16-schemes}/kanagawa.yaml";
    homeManagerIntegration.autoImport = false;
  };
}
