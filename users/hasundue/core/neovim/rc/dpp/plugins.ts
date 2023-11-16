import type { Plugin } from "./lib/x/dpp_vim.ts";
import { List, Group } from "./lib/loader.ts";

export const PLUGINS = List(
  // Bootstrap
  ...Group({ lazy: false, rtp: "" }, [
    {
      repo: "Shougo/dpp.vim",
    },
    {
      repo: "Shougo/dpp-ext-lazy",
      depends: ["dpp.vim"],
    },
  ]),
  // Extensions for dpp
  ...Group({ depends: ["dpp.vim"], on_source: ["dpp.vim"] }, [
    {
      repo: "Shougo/dpp-ext-local",
    },
  ]),
  // Merged into bootstrap
  ...Group({ lazy: false, merged: true }, [
    {
      repo: "rebelot/kanagawa.nvim",
    },
  ]),
  // Loaded immediately after startup
  ...Group({ on_event: ["VimEnter"] }, [
    {
      repo: "vim-denops/denops.vim",
    },
    {
      repo: "Shougo/ddu.vim",
      depends: ["denops.vim"],
    },
  ]),
  // Loaded after reading any file
  ...Group({ on_event: ["BufRead"] }, [
    {
      repo: "nvim-treesitter/nvim-treesitter",
    },
    {
      repo: "kuuote/lspoints",
    },
  ]),
  // Extensions for lspoints
  ...Group({ depends: ["lspoints"], on_source: ["lspoints"] }, [
    {
      repo: "Warashi/lspoints-hover",
    },
  ]),
  // Loaded when cursor moved or hold for a while
  ...Group({ on_event: ["CursorMoved", "CursorHold"] }, [
    {
      repo: "machakann/vim-sandwich",
    },
  ]),
  // loaded when entreing insert mode
  ...Group({ on_event: ["InsertEnter"] }, [
    {
      repo: "github/copilot.vim",
    },
  ]),
) satisfies Plugin[];
