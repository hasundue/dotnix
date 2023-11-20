{
  description = "hasundue's Neovim plugins (auto-generated)";

  inputs = {
    "dpp.vim" = { url = "github:Shougo/dpp.vim"; flake = false; };
    "dpp-ext-lazy" = { url = "github:Shougo/dpp-ext-lazy"; flake = false; };
    "denops.vim" = { url = "github:vim-denops/denops.vim"; flake = false; };
    "vim-floaterm" = { url = "github:voldikss/vim-floaterm"; flake = false; };
  };

  outputs = inputs: {
    plugins = inputs;
  };
}