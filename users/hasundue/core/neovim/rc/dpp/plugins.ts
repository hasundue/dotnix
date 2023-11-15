import { basename } from "https://deno.land/std@0.206.0/path/basename.ts";
import { deepMerge } from "https://deno.land/std@0.206.0/collections/deep_merge.ts";
import { Plugin } from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";
import type { AutocmdEvent } from "https://deno.land/x/denops_std@v5.0.2/autocmd/mod.ts";

export type RepoSpec<
  Owner extends string = string,
  Name extends string = string,
> = `${Owner}/${Name}`;

export type RepoName<R = RepoSpec> = R extends
  RepoSpec<infer _Owner, infer Name> ? Name
  : never;

export type Config<
  RepoRef extends RepoName = RepoName,
> = {
  depends?: RepoRef[];
  lazy?: boolean;
  merged?: boolean;
  on_source?: RepoRef[];
  on_event?: AutocmdEvent[];
  rtp?: string;
};

export type Init<
  Repo extends RepoSpec = RepoSpec,
  RepoRef extends RepoName = RepoName,
> = Config<RepoRef> & {
  repo: Repo;
};

export function Group<
  Repo extends RepoSpec = RepoSpec,
  RepoRef extends RepoName = never,
>(
  config: Config<RepoRef>,
  list: Init<Repo, RepoRef>[],
): Init<Repo, RepoRef>[] {
  return list.map(
    (it) => deepMerge(it, config, { arrays: "merge" }),
    // FIXME: deepMerge argues that `repo` is missing
  ) as Init<Repo, RepoRef>[];
}

export type Spec<
  Repo extends RepoSpec = RepoSpec,
  RepoRef extends RepoName = RepoName,
> = Init<Repo, RepoRef> & {
  name: RepoName<Repo>;
};

export type List<
  Repo extends RepoSpec = RepoSpec,
> = {
  [R in Repo]: Spec<R, RepoName<Repo>>;
}[Repo][];

export function createList<
  Repo extends RepoSpec,
>(init: Init<Repo, RepoName<Repo>>[]): List<Repo> {
  return init.map(
    (it) => ({
      ...it,
      name: basename(it.repo),
    }),
  ) as List<Repo>;
}

export const PLUGINS = createList([
  // Bootstrap
  ...Group(
    { lazy: false, rtp: "" },
    [
      { repo: "Shougo/dpp.vim" },
      {
        repo: "Shougo/dpp-ext-lazy",
        depends: ["dpp.vim"],
      },
    ],
  ),

  // Extensions for dpp
  ...Group(
    { depends: ["dpp.vim"], on_source: ["dpp.vim"] },
    [
      { repo: "Shougo/dpp-ext-local" },
    ],
  ),

  // Merged into bootstrap
  ...Group(
    { lazy: false, merged: true },
    [
      { repo: "rebelot/kanagawa.nvim" },
    ],
  ),

  // Loaded immediately after startup
  ...Group(
    { on_event: ["VimEnter"] },
    [
      {
        repo: "vim-denops/denops.vim",
      },
      {
        repo: "Shougo/ddu.vim",
        depends: ["denops.vim"],
      },
    ],
  ),

  // Loaded after reading any file
  ...Group(
    { on_event: ["BufRead"] },
    [
      { repo: "nvim-treesitter/nvim-treesitter" },
      { repo: "kuuote/lspoints.nvim" },
    ],
  ),

  // Loaded when cursor moved or hold for a while
  ...Group(
    { on_event: ["CursorMoved", "CursorHold"] },
    [
      { repo: "machakann/vim-sandwich" },
    ],
  ),

  // loaded when entreing insert mode
  ...Group(
    { on_event: ["InsertEnter"] },
    [
      { repo: "github/copilot.vim" },
    ],
  ),
]) satisfies Plugin[];
