import { basename } from "./std/path.ts";
import type { AutocmdEvent } from "./x/denops_std.ts";
import type { Plugin } from "./x/dpp_vim.ts";

export type RepoSpec<
  Owner extends string = string,
  Name extends string = string,
> = `${Owner}/${Name}`;

export type RepoName<R = RepoSpec> = R extends
  RepoSpec<infer _Owner, infer Name> ? Name : never;

type InheritedConfig = Omit<
  Plugin,
  "name" | "repo" | "depends" | "on_source" | "on_event"
>;

export type Config<
  RepoRef extends RepoName = RepoName,
> = Partial<InheritedConfig> & {
  depends?: RepoRef[];
  on_source?: RepoRef[];
  on_event?: AutocmdEvent[];
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
  descriptor: Config<RepoRef>,
  plugins: Init<Repo, RepoRef>[],
): Init<Repo, RepoRef>[] {
  return plugins.map(
    (it) => ({ ...it, ...descriptor }),
  );
}

export type Spec<
  Repo extends RepoSpec = RepoSpec,
  RepoRef extends RepoName = RepoName,
> = Init<Repo, RepoRef> & {
  name: RepoName<Repo>;
};

export type ClosedSet<
  Repo extends RepoSpec,
> = {
  [R in Repo]: Spec<R, RepoName<Repo>>;
}[Repo][];

export function ClosedSet<
  Repo extends RepoSpec,
>(
  ...plugins: Init<Repo, RepoName<Repo>>[]
): ClosedSet<Repo> {
  return plugins.map(
    (it) => ({
      ...it,
      name: basename(it.repo),
    }),
  ) as ClosedSet<Repo>; // we need to cast here for `name`
}
