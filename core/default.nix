{ pkgs, system, schemes, stylix, ... }:

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
        schemes
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
    base16Scheme = "${schemes}/base16/kanagawa.yaml";
    polarity = "dark";
  };
}
