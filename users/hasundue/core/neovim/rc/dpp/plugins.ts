import { deepMerge } from "https://deno.land/std@0.206.0/collections/deep_merge.ts";
import { mapValues } from "https://deno.land/std@0.206.0/collections/map_values.ts";
import type { ReadonlyDeep } from "npm:type-fest@4.7.1";
import type { Plugin } from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";

type PluginConfig = Partial<ReadonlyDeep<Plugin>>;
type PluginRecord = Readonly<Record<string, PluginConfig>>;

function Group<C extends PluginConfig, R extends PluginRecord>(
  spec: C,
  record: R,
) {
  return mapValues(
    record,
    (it) => deepMerge(it, spec, { arrays: "merge" }),
  ) as { [K in keyof R]: C & R[K] };
}

const DPP_BOOTSTRAP = Group(
  { lazy: false, rtp: "" },
  {
    "dpp": {
      repo: "Shougo/dpp.vim",
      depends: ["denops"],
    },
    "dpp-ext-lazy": {
      repo: "Shougo/dpp-ext-lazy",
      depends: ["dpp"],
    },
  },
);

const DPP_EXTS = Group(
  { depends: ["dpp"], on_source: ["dpp"] },
  {
    "dpp-ext-local": { repo: "Shougo/dpp-ext-local" },
  },
);

const MERGED = Group(
  { lazy: false, merged: true },
  {
    "kanagawa": {
      repo: "rebelot/kanagawa.nvim",
      hook_add: "KanagawaCompile",
    },
  },
);

const ON_ENTER = Group(
  { on_event: ["VimEnter"] },
  {
    "denops": {
      repo: "vim-denops/denops.vim",
    },
    "ddu": {
      repo: "Shougo/ddu.vim",
      depends: ["denops"],
    },
  },
);

const DDU_EXTS = Group(
  { depends: ["ddu"], on_source: ["ddu"] },
  {
    // "ddu-ui-ff": { repo: "Shougo/ddu-ui-ff" },
    // "ddu-kind-file": { repo: "Shougo/ddu-kind-file" },
    // "ddu-source-buffer": { repo: "shun/ddu-source-buffer" },
  },
);

const ON_READ = Group(
  { on_event: ["BufRead"] },
  {
    "nvim-treesitter": {
      repo: "nvim-treesitter/nvim-treesitter",
    },
    "lspoints": {
      repo: "kuuote/lspoints.nvim",
    },
  },
);

const ON_MOVE = Group(
  { on_event: ["CursorMoved", "CursorHold"] },
  {
    "vim-sandwich": {
      repo: "machakann/vim-sandwich",
    },
  },
);

const ON_INSERT = Group(
  { on_event: ["InsertEnter"] },
  {
    "copilot": {
      repo: "github/copilot.vim",
    },
  },
);

export const PLUGINS = {
  // Loaded on startup
  ...DPP_BOOTSTRAP,
  ...MERGED,

  // Loaded on events
  ...ON_ENTER,
  ...ON_READ,
  ...ON_MOVE,
  ...ON_INSERT,

  // plugin extensions
  ...DPP_EXTS,
  ...DDU_EXTS,
};

PLUGINS["dpp"];
