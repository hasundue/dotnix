{
  description = "hasundue's Neovim plugins";

  inputs = {
    # denops.vim
    denops = { url = "github:vim-denops/denops.vim"; flake = false; };

    # plugin manager
    dpp = { url = "github:Shougo/dpp.vim"; flake = false; };
    dpp-ext-lazy = { url = "github:Shougo/dpp-ext-lazy"; flake = false; };
    dpp-ext-local = { url = "github:Shougo/dpp-ext-local"; flake = false; };

    # UI
    kanagawa = { url = "github:rebelot/kanagawa.nvim"; flake = false; };

    # basic
    vim-sandwich = { url = "github:machakann/vim-sandwich"; flake = false; };

    # LSP
    lspoints = { url = "github:kuuote/lspoints"; flake = false; };
    lspoints-hover = { url = "github:Warashi/lspoints-hover"; flake = false; };

    # Treesitter
    nvim-treesitter = { url = "github:nvim-treesitter/nvim-treesitter"; flake = false; };

    # AI
    copilot = { url = "github:github/copilot.vim"; flake = false; };
  };

  outputs = { nixpkgs, ... } @ inputs: {
    repos = nixpkgs.lib.filterAttrs
      (name: value: name != "nixpkgs" && name != "_type" && name != "self")
      inputs;
  };
}
