{ config, lib, pkgs, system, neovim-plugins, ... }:

with lib;

{
  users.users.hasundue = {
    createHome = true;
    description = "Shun Ueda";
    group = "hasundue";
    extraGroups = [ "wheel" ]
      ++ optionals config.networking.networkmanager.enable [ "networkmanager" ]
      ++ optionals config.programs.sway.enable [ "audio" "input" "video" ]
      ++ optionals config.virtualisation.docker.enable [ "docker" ];
    isNormalUser = true;
    shell = pkgs.fish;
  };

  users.groups.hasundue = { };

  home-manager = {
    extraSpecialArgs = {
      neovim-plugins = neovim-plugins.packages.${system};
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
}
