{ config, lib, pkgs, system, base16-schemes, neovim-nightly, stylix, hasundue-neovim, ... }: 

with lib;

{
  users.users.hasundue = {
    createHome = true;
    description = "Shun Ueda";
    group = "hasundue";
    extraGroups = [ "wheel" ]
      ++ optionals config.networking.networkmanager.enable [ "networkmanager" ]
      ++ optionals config.programs.sway.enable [ "input" "video" ]
      ++ optionals config.sound.enable [ "audio" ]
      ++ optionals config.virtualisation.docker.enable [ "docker" ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  users.groups.hasundue = {};

  home-manager = {
    extraSpecialArgs = { 
      inherit
        base16-schemes
        neovim-nightly
        stylix;
      neovim-plugins = hasundue-neovim.packages.${system};
    };
    users.hasundue = {
      imports = [
        ./core
        ./dev
      ] ++ optionals config.programs.sway.enable [
        ./graphical
        ./graphical/sway.nix
      ];
      home.username = config.users.users.hasundue.name;
    };
  };

  nixpkgs = {
    overlays = [
      neovim-nightly.overlay
    ];
  };
}
