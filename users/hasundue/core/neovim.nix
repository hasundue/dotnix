{ config, lib, pkgs, neovim-plugins, ... }:

let
  treesitter-parsers = with pkgs.vimPlugins.nvim-treesitter-parsers; [
    bash
    c # replace the bundled one
    diff
    gitcommit
    go
    graphql
    javascript
    jsdoc
    json
    jsonc
    lua # replace the bundled one
    luadoc
    make
    markdown # replace the bundled one
    markdown_inline
    mermaid
    nix
    python
    regex
    ron
    rust
    scheme
    tsx
    typescript
    vim # replace the bundled one
    vimdoc # replace the bundled one
    yaml
    zig
  ];
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      lua-language-server
      nodePackages.typescript-language-server
      nodePackages.yarn # for makrdown-preview.nvim
      nil
      nixpkgs-fmt
      rust-analyzer
      rustfmt
      zls
    ];

    plugins = with pkgs.vimPlugins; [
      nvim-treesitter
    ] ++ treesitter-parsers;

    vimdiffAlias = false;
    vimAlias = false;
    viAlias = false;

    withNodeJs = false;
    withPython3 = false;
    withRuby = false;
  };

  programs.git.extraConfig.core.editor = "nvim";

  home =
    let
      nvim = lib.getExe config.programs.neovim.finalPackage;
    in
    {
      activation.neovimDppMakeState = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
        $DRY_RUN_CMD ${nvim} -l ~/.config/nvim/lua/hook/clear_dpp_state.lua
      '';
      shellAliases = rec {
        nvim = "nvim --noplugin";
        nv = "${nvim}";
      };
    };

  xdg.configFile = {
    "nvim".source = ./dotlua;
  };

  xdg.dataFile = lib.mapAttrs'
    (name: package: lib.nameValuePair
      ("nvim/plugins/" + name)
      { source = package; }
    )
    neovim-plugins;
}
