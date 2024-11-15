{ neovim-plugins, ... }:

{
  home-manager = {
    extraSpecialArgs = {
      inherit neovim-plugins;
    };
    users.hasundue = {
      imports = [
        ./deno.nix
        ./gh.nix
        ./neovim.nix
        ./nix.nix
      ];
      programs = {
        direnv = {
          enable = true;
          config = {
            silent = true;
          };
        };
      };
    };
  };

  virtualisation.docker.enable = true;
}
