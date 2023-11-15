{
  description = "hasundue's Nix flake";

  inputs = {
    neovim = {
      url = "./core/neovim";
    };
  };

  outputs = { neovim, ... }: {
    neovim-plugins = neovim.plugins;
  };
}
