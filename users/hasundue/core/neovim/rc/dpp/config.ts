import { walk } from "./lib/std.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Denops,
  Dpp,
  Plugin,
} from "./lib/dpp_vim.ts";
import {
  $XDG_CACHE_HOME,
  $XDG_CONFIG_HOME,
  $XDG_DATA_HOME,
} from "./helper/lib/env.ts";
import { PLUGINS } from "./plugins.ts";

type LazyMakeStateResult = {
  plugins: Plugin[];
  stateLines: string[];
};

const $CACHE = $XDG_CACHE_HOME + "/dpp/repos/github.com";
const $CONFIG = $XDG_CONFIG_HOME + "/nvim";
const $DATA = $XDG_DATA_HOME + "/nvim";

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
      const cache = `${$CACHE}/${it.repo}`;
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
