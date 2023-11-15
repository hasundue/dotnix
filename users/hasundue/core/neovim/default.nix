{ lib, pkgs, neovim-plugins, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    withNodeJs = false;
    withPython3 = false;
    withRuby = false;

    vimdiffAlias = true;
    vimAlias = true;
    viAlias = true;

    plugins = with pkgs.vimPlugins.nvim-treesitter-parsers; [
      bash
      c
      cmake
      comment
      cpp
      css
      csv
      diff
      fish
      git_config
      git_rebase
      gitattributes
      gitcommit
      go
      graphql
      haskell
      html
      ini
      javascript
      jq
      jsdoc
      json
      jsonc
      lua
      luadoc
      make
      markdown
      markdown_inline
      mermaid
      nix
      python
      regex
      ron
      ruby
      rust
      scheme
      scss
      ssh_config
      svelte
      toml
      tsx
      typescript
      vim
      vimdoc
      xml
      yaml
      zig
    ];
  };

  programs.git.extraConfig.core.editor = "nvim";

  home.shellAliases = {
    nv = "nvim";
  };

  xdg.configFile = {
    "nvim/denops".source = ./denops;
    "nvim/init.lua".source = ./init.lua;
    "nvim/lua".source = ./lua;
    "nvim/rc".source = ./rc;
  };

  xdg.dataFile = lib.mapAttrs'
    (name: value: lib.nameValuePair
      ("nvim/plugins/" + name)
      { source = value; }
    )
    neovim-plugins;
}
