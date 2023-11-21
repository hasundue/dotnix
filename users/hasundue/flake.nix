{
  description = "hasundue's subflake";

  inputs = {
    neovim = {
      url = "./core/neovim";
    };
  };

  outputs = { neovim, ... }: {
    neovim-plugins = neovim.plugins;
  };
}
