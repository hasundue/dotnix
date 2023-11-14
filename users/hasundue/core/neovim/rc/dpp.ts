import { deepMerge } from "https://deno.land/std@0.206.0/collections/deep_merge.ts";
import { associateBy } from "https://deno.land/std@0.206.0/collections/associate_by.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Dpp,
  Plugin,
} from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";
import { Denops, fn } from "https://deno.land/x/dpp_vim@v0.0.7/deps.ts";

type Toml = {
  plugins: Plugin[];
};

type LazyMakeStateResult = {
  plugins: Plugin[];
  stateLines: string[];
};

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }) {
    const [context, options] = await args.contextBuilder.get(args.denops);

    const plugins = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "local",
      "local",
      {
        directory: "~/.local/share/nvim/plugins",
        options: {
          frozen: true,
          merged: false,
        },
      },
    ) as Plugin[];

    const record = associateBy(plugins, (plugin) => plugin.name);

    const dpp_toml = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "toml",
      "load",
      {
        path: "~/.config/nvim/rc/dpp.toml",
        options: {
          lazy: false,
        },
      },
    ) as Toml;

    const dpp_record = associateBy(dpp_toml.plugins, (plugin) => plugin.name);

    const merged = deepMerge(record, dpp_record);

    const result = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins: Object.values(merged) },
    ) as LazyMakeStateResult;

    return {
      plugins: result.plugins,
      stateLines: result.stateLines,
    } as ConfigReturn;
  }
}
