import type { Plugin } from "./lib/x/dpp_vim.ts";
import { ClosedGroup, Group } from "./lib/groups.ts";
import { $CONFIG } from "./lib/env.ts";

const rc = $CONFIG + "/rc";

export const PLUGINS = ClosedGroup(
  // Bootstrap
  ...Group({ lazy: false, rtp: "" }, [
    {
      repo: "~/dpp.vim",
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
      lua_add: "require('rc.kanagawa')",
    },
  ]),
  // Loaded immediately after startup
  ...Group({ on_event: ["CursorHold"] }, [
    {
      repo: "vim-denops/denops.vim",
    },
  ]),
  // Loaded when reading any file
  ...Group({ on_event: ["BufRead"] }, [
    {
      repo: "nvim-treesitter/nvim-treesitter",
    },
    {
      repo: "kuuote/lspoints",
      depends: ["denops"],
      lua_source: "require('rc.lspoints')",
    },
  ]),
  // Extensions for lspoints
  ...Group({ on_source: ["lspoints"] }, [
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
  // ddu and ddu-commands
  {
    repo: "Shougo/ddu.vim",
    depends: ["denops"],
    on_source: ["ddu-commands"],
    hooks_file: `${rc}/ddu.vim`,
  },
  {
    repo: "Shougo/ddu-commands.vim",
    on_cmd: ["Ddu"],
  },
  // ddu extensions
  ...Group({ on_source: ["ddu"] }, [
    {
      repo: "hasundue/ddu-filter-zf",
      build: "deno task build",
    },
    {
      repo: "kuuote/ddu-source-mr",
      depends: ["mr"],
    },
    { repo: "matsui54/ddu-source-file_external" },
    { repo: "matsui54/ddu-source-help" },
    {
      repo: "Shougo/ddu-ui-ff",
      hooks_file: `${rc}/ddu/ui-ff.vim`,
    },
    { repo: "Shougo/ddu-kind-file" },
    { repo: "shun/ddu-source-rg" },
    { repo: "shun/ddu-source-buffer" },
  ]),
  // miscelaneous
  {
    repo: "lambdalisue/mr.vim",
    on_source: ["ddu-source-mr"],
  },
) satisfies Plugin[];
