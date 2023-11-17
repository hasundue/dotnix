import { basename } from "./std/path.ts";
import type { AutocmdEvent } from "./x/denops_std.ts";
import type { Plugin } from "./x/dpp_vim.ts";

export type RepoSpec<
  Owner extends string = string,
  Name extends string = string,
  Extension extends string = never,
> = `${Owner}/${Name}` | `${Owner}/${Name}.${Extension}`;

export type RepoName<R = RepoSpec> = R extends
  `${infer _Owner}/${infer Name}.${infer _Extension}` ? Name
  : R extends `${infer _Owner}/${infer Name}` ? Name
  : never;

// TODO: Do not hardcode this
type InheritedConfig = Omit<
  Plugin,
  "name" | "repo" | "depends" | "on_source" | "on_event"
>;

export type Config<
  RepoRef extends RepoName = RepoName,
> = Partial<InheritedConfig> & {
  depends?: RepoRef[];
  directory?: string;
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
    // TODO: Do not override but merge
    (it) => ({ ...it, ...descriptor }),
  );
}

export type Spec<
  Repo extends RepoSpec = RepoSpec,
  RepoRef extends RepoName = RepoName,
> = Init<Repo, RepoRef> & {
  name: RepoName<Repo>;
};

export type ClosedGroup<
  Repo extends RepoSpec = RepoSpec,
> = {
  [R in Repo]: Spec<R, RepoName<Repo>>;
}[Repo][];

export function ClosedGroup<
  Repo extends RepoSpec = RepoSpec,
>(
  ...plugins: Init<Repo, RepoName<Repo>>[]
): ClosedGroup<Repo> {
  return plugins.map(
    (it) => ({ ...it, name: toName(it.repo) }),
  ) satisfies Plugin[] as ClosedGroup<Repo>; // we need a cast to type `name`
}

function toName(from: RepoSpec): RepoName {
  return basename(from).split(".")[0];
}
