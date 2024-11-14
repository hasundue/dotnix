{ pkgs, system, stylix, ... }:

{
  imports = [
    ./nixos.nix
    ./nix.nix
  ];

  environment = {
    pathsToLink = [
      "/share/bash"
      "/share/fish"
    ];
    systemPackages = with pkgs; [
      vim
    ];
  };

  home-manager = {
    extraSpecialArgs = {
      inherit
        stylix
        system;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
  };

  programs = {
    fish.enable = true;
  };

  stylix = {
    enable = true;
    base16Scheme = "${pkgs.base16-schemes}/share/themes/kanagawa.yaml";
    polarity = "dark";
  };
}
