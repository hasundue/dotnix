{
  description = "hasundue's Neovim plugins (auto-generated)";

  inputs = {
    dpp = { url = "github:Shougo/dpp.vim"; flake = false; };
    dpp-ext-lazy = { url = "github:Shougo/dpp-ext-lazy"; flake = false; };
    kanagawa = { url = "github:rebelot/kanagawa.nvim"; flake = false; };
    denops = { url = "github:vim-denops/denops.vim"; flake = false; };
    ddu = { url = "github:Shougo/ddu.vim"; flake = false; };
    nvim-treesitter = { url = "github:nvim-treesitter/nvim-treesitter"; flake = false; };
    lspoints = { url = "github:kuuote/lspoints"; flake = false; };
    lspoints-hover = { url = "github:Warashi/lspoints-hover"; flake = false; };
    vim-sandwich = { url = "github:machakann/vim-sandwich"; flake = false; };
    copilot = { url = "github:github/copilot.vim"; flake = false; };
  };

  outputs = { nixpkgs, ... } @ inputs: {
    plugins = nixpkgs.lib.filterAttrs
      (name: value: name != "nixpkgs" && name != "_type" && name != "self")
      inputs;
  };
}
