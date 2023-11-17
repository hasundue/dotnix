import type { Plugin } from "./lib/x/dpp_vim.ts";
import { ClosedGroup, Group } from "./lib/groups.ts";
import { $CONFIG } from "./lib/env.ts";

const rc = $CONFIG + "/rc";

export const PLUGINS = ClosedGroup(
  ...Group({ frozen: true, local: true }, [
    // Bootstrap
    ...Group({ lazy: false, rtp: "" }, [
      {
        repo: "Shougo/dpp.vim",
      },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp"],
      },
    ]),
    // Merged into bootstrap
    ...Group({ lazy: false }, [
      {
        repo: "rebelot/kanagawa.nvim",
        hooks_file: `${rc}/kanagawa.lua`,
      },
    ]),
    // Loaded immediately after startup
    ...Group({ on_event: ["VimEnter"] }, [
      {
        repo: "vim-denops/denops.vim",
      },
      {
        repo: "Shougo/ddu.vim",
        depends: ["denops"],
      },
    ]),
    // Loaded when reading any file
    ...Group({ on_event: ["BufRead"] }, [
      {
        repo: "nvim-treesitter/nvim-treesitter",
      },
      {
        repo: "kuuote/lspoints",
        hooks_file: `${rc}/lspoints.lua`,
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
    ...Group({ on_event: ["CmdLineEnter", "InsertEnter"] }, [
      {
        repo: "github/copilot.vim",
      },
      {
        repo: "Shougo/ddc.vim",
        depends: ["denops", "pum"],
        hooks_file: `${rc}/ddc.vim`,
      },
    ]),
    // ddc dependencies and extensions
    ...Group({ on_source: ["ddc"] }, [
      { repo: "Shougo/ddc-nvim-lsp" },
      { repo: "Shougo/ddc-ui-pum" },
      { repo: "Shougo/pum.vim" },
      { repo: "tani/ddc-fuzzy" },
    ]),
  ]),
) satisfies Plugin[];
