{
  description = "hasundue's Neovim plugins (auto-generated)";

  inputs = {
    dpp-ext-lazy = { url = "github:Shougo/dpp-ext-lazy"; flake = false; };
    kanagawa = { url = "github:rebelot/kanagawa.nvim"; flake = false; };
    denops = { url = "github:vim-denops/denops.vim"; flake = false; };
    nvim-treesitter = { url = "github:nvim-treesitter/nvim-treesitter"; flake = false; };
    lspoints = { url = "github:kuuote/lspoints"; flake = false; };
    lspoints-hover = { url = "github:Warashi/lspoints-hover"; flake = false; };
    vim-sandwich = { url = "github:machakann/vim-sandwich"; flake = false; };
    copilot = { url = "github:github/copilot.vim"; flake = false; };
    ddc = { url = "github:Shougo/ddc.vim"; flake = false; };
    ddc-nvim-lsp = { url = "github:Shougo/ddc-nvim-lsp"; flake = false; };
    ddc-ui-pum = { url = "github:Shougo/ddc-ui-pum"; flake = false; };
    pum = { url = "github:Shougo/pum.vim"; flake = false; };
    ddc-fuzzy = { url = "github:tani/ddc-fuzzy"; flake = false; };
    ddu = { url = "github:Shougo/ddu.vim"; flake = false; };
    ddu-commands = { url = "github:Shougo/ddu-commands.vim"; flake = false; };
    ddu-filter-zf = { url = "github:hasundue/ddu-filter-zf"; flake = false; };
    ddu-source-mr = { url = "github:kuuote/ddu-source-mr"; flake = false; };
    ddu-source-file_external = { url = "github:matsui54/ddu-source-file_external"; flake = false; };
    ddu-source-help = { url = "github:matsui54/ddu-source-help"; flake = false; };
    ddu-ui-ff = { url = "github:Shougo/ddu-ui-ff"; flake = false; };
    ddu-kind-file = { url = "github:Shougo/ddu-kind-file"; flake = false; };
    ddu-source-rg = { url = "github:shun/ddu-source-rg"; flake = false; };
    ddu-source-buffer = { url = "github:shun/ddu-source-buffer"; flake = false; };
    mr = { url = "github:lambdalisue/mr.vim"; flake = false; };
  };

  outputs = inputs: {
    plugins = inputs;
  };
}
