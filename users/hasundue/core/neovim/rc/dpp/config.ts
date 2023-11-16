import { walk } from "./lib/std/fs.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Denops,
  Dpp,
  Plugin,
} from "./lib/x/dpp_vim.ts";
import { $CONFIG, $DATA } from "./lib/env.ts";
import { PLUGINS } from "./plugins.ts";

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

    const plugins = PLUGINS.map((it) => ({
      ...it,
      path: `${$DATA}/plugins/${it.name}`,
    }));

    // Create a state with dpp-ext-lazy
    const makeStateResult = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult;

    // Create a list of files to check
    const checkFiles = await Array.fromAsync(walk($CONFIG + "/rc"))
      .then((entries) => entries.map((entry) => entry.path));

    return {
      checkFiles,
      plugins: makeStateResult.plugins,
      stateLines: makeStateResult.stateLines,
    } satisfies ConfigReturn;
  }
}
