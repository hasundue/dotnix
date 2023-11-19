import { walk } from "./lib/std/fs.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Denops,
  Dpp,
  Plugin,
} from "./lib/x/dpp_vim.ts";
import { $CACHE, $CONFIG, $DATA } from "./lib/env.ts";
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

    const plugins = PLUGINS.map((it) => {
      const data = `${$DATA}/plugins/${it.name}`;
      const cache = `${$CACHE}/${it.name}`;
      /*
      if (it.build) {
        try {
          Deno.mkdirSync(cache);
        } catch (e) {
          console.log(e);
        }
        new Deno.Command("cp", {
          args: ["-rf", `${data}/*`, cache],
        }).outputSync();
        const [command, ...args] = it.build.split(" ");
        new Deno.Command(command, {
          args,
          cwd: cache,
          stdout: "inherit",
          stderr: "inherit",
        }).outputSync();
      }
      */
      return {
        ...it,
        path: it.build ? cache : data,
      };
    });

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
