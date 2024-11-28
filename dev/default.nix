{ neovim-flake, ... }:

{
  home-manager = {
    extraSpecialArgs = {
      inherit neovim-flake;
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
          nix-direnv.enable = true;
        };
      };
    };
  };
  virtualisation.docker.enable = true;
}
