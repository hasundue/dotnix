import type { Plugin } from "./lib/dpp_vim.ts";
import { $XDG_CONFIG_HOME, ClosedGroup, Group } from "./lib/dpp_helper.ts";

const rc = $XDG_CONFIG_HOME + "/nvim/rc";

const readTextFile = (path: string) =>
  Deno.readTextFile(new URL(path, import.meta.url));

export const PLUGINS = ClosedGroup(
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
      lua_source: "require('rc.treesitter')",
    },
    {
      repo: "kuuote/lspoints",
      depends: ["denops.vim"],
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
      hook_add: await readTextFile("../copilot.vim"),
    },
    {
      repo: "Shougo/ddc.vim",
      depends: ["denops.vim", "pum.vim"],
      hooks_file: `${rc}/ddc.vim`,
    },
  ]),
  // ddc dependencies and extensions
  ...Group({ on_source: ["ddc.vim"] }, [
    { repo: "LumaKernel/ddc-file" },
    { repo: "Shougo/ddc-cmdline" },
    { repo: "Shougo/ddc-cmdline-history" },
    { repo: "Shougo/ddc-nvim-lsp" },
    { repo: "Shougo/ddc-ui-pum" },
    { repo: "Shougo/pum.vim" },
    { repo: "tani/ddc-fuzzy" },
  ]),
  // ddu and ddu-commands
  {
    repo: "Shougo/ddu.vim",
    depends: ["denops.vim"],
    on_source: ["ddu-commands.vim"],
    hooks_file: `${rc}/ddu.vim`,
  },
  {
    repo: "Shougo/ddu-commands.vim",
    on_cmd: ["Ddu"],
  },
  // ddu extensions
  ...Group({ on_source: ["ddu.vim"] }, [
    {
      repo: "hasundue/ddu-filter-zf",
      build: "deno task build",
    },
    {
      repo: "kuuote/ddu-source-mr",
      depends: ["mr.vim"],
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
  // floaterm
  {
    repo: "voldikss/vim-floaterm",
    on_cmd: ["FloatermNew", "FloatermToggle"],
    lua_add: "require('rc.floaterm.keymap')",
    lua_source: "require('rc.terminal')\nrequire('rc.floaterm.config')",
  },
  // miscelaneous
  {
    repo: "lambdalisue/mr.vim",
    on_source: ["ddu-source-mr"],
  },
) satisfies Plugin[];
