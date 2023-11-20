import {
  BaseConfig,
  ConfigArguments,
  Plugin,
} from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";
import { PLUGINS } from "./plugins.ts";
import { $XDG_DATA_HOME } from "https://esm.sh/gh/hasundue/dpp-helper/mod.ts";

interface LazyMakeStateResult {
  plugins: Plugin[];
  stateLines: string[];
}

export class Config extends BaseConfig {
  override async config(args: ConfigArguments) {
    const [context, options] = await args.contextBuilder.get(args.denops);

    const plugins = PLUGINS.map((plugin) => {
      return {
        ...plugin,
        path: `${$XDG_DATA_HOME}/vim/plugins/${plugin.name}`,
      };
    });

    const state = await args.dpp.extAction(
      args.denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult;

    return {
      plugins: state.plugins,
      stateLines: state.stateLines,
    };
  }
}
