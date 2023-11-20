{
  description = "hasundue's Nix flake";

  inputs = {
    neovim = {
      url = "./core/neovim";
    };
    vim = {
      url = "./core/vim";
    };
  };

  outputs = { neovim, vim, ... }: {
    neovim-plugins = neovim.plugins;
    vim-plugins = vim.plugins;
  };
}
