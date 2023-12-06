{
  description = "hasundue's Neovim configuration";

  inputs = {
    "dpp.vim" = { url = "github:Shougo/dpp.vim"; flake = false; };
    "dpp-ext-lazy" = { url = "github:Shougo/dpp-ext-lazy"; flake = false; };
    "kanagawa.nvim" = { url = "github:rebelot/kanagawa.nvim"; flake = false; };
    "denops.vim" = { url = "github:vim-denops/denops.vim"; flake = false; };
    "gitsigns.nvim" = { url = "github:lewis6991/gitsigns.nvim"; flake = false; };
    "nvim-treesitter" = { url = "github:nvim-treesitter/nvim-treesitter"; flake = false; };
    "nvim-lspconfig" = { url = "github:neovim/nvim-lspconfig"; flake = false; };
    "lsp_signature.nvim" = { url = "github:ray-x/lsp_signature.nvim"; flake = false; };
    "vim-sandwich" = { url = "github:machakann/vim-sandwich"; flake = false; };
    "copilot.vim" = { url = "github:github/copilot.vim"; flake = false; };
    "ddc.vim" = { url = "github:Shougo/ddc.vim"; flake = false; };
    "ddc-file" = { url = "github:LumaKernel/ddc-file"; flake = false; };
    "ddc-cmdline" = { url = "github:Shougo/ddc-cmdline"; flake = false; };
    "ddc-cmdline-history" = { url = "github:Shougo/ddc-cmdline-history"; flake = false; };
    "ddc-nvim-lsp" = { url = "github:Shougo/ddc-nvim-lsp"; flake = false; };
    "ddc-ui-pum" = { url = "github:Shougo/ddc-ui-pum"; flake = false; };
    "pum.vim" = { url = "github:Shougo/pum.vim"; flake = false; };
    "ddc-fuzzy" = { url = "github:tani/ddc-fuzzy"; flake = false; };
    "ddu.vim" = { url = "github:Shougo/ddu.vim"; flake = false; };
    "ddu-commands.vim" = { url = "github:Shougo/ddu-commands.vim"; flake = false; };
    "ddu-filter-zf" = { url = "github:hasundue/ddu-filter-zf"; flake = false; };
    "ddu-source-mr" = { url = "github:kuuote/ddu-source-mr"; flake = false; };
    "ddu-source-file_external" = { url = "github:matsui54/ddu-source-file_external"; flake = false; };
    "ddu-source-help" = { url = "github:matsui54/ddu-source-help"; flake = false; };
    "ddu-ui-ff" = { url = "github:Shougo/ddu-ui-ff"; flake = false; };
    "ddu-kind-file" = { url = "github:Shougo/ddu-kind-file"; flake = false; };
    "ddu-source-rg" = { url = "github:shun/ddu-source-rg"; flake = false; };
    "ddu-source-buffer" = { url = "github:shun/ddu-source-buffer"; flake = false; };
    "ddu-source-lsp" = { url = "github:uga-rosa/ddu-source-lsp"; flake = false; };
    "vim-floaterm" = { url = "github:voldikss/vim-floaterm"; flake = false; };
    "mr.vim" = { url = "github:lambdalisue/mr.vim"; flake = false; };
    "markdown-preview.nvim" = { url = "github:iamcco/markdown-preview.nvim"; flake = false; };
  };

  outputs = inputs: {
    neovim-plugins = inputs;
  };
}
