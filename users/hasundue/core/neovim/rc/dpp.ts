import { assertInstanceOf } from "https://deno.land/std@0.206.0/assert/assert_instance_of.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Dpp,
  Plugin,
} from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";
import { Denops, fn } from "https://deno.land/x/dpp_vim@v0.0.7/deps.ts";

type LazyMakeStateResult = {
  plugins: Plugin[];
  stateLines: string[];
};

const HOOK_FILE_NAMES = {
  hook_add: "hook_add.vim",
  hook_source: "hook_source.vim",
  lua_add: "hook_add.lua",
  lua_source: "hook_source.lua",
} as const;

const HOOK_FILE_ENTRIES = Object.entries(HOOK_FILE_NAMES);

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }) {
    const { denops, dpp } = args;

    const [context, options] = await args.contextBuilder.get(denops);

    const $CONFIG = await denops.call("stdpath", "config");
    const $DATA = await denops.call("stdpath", "data");

    // Load all plugins installed by Nix
    const plugins = await dpp.extAction(
      denops,
      context,
      options,
      "local",
      "local",
      {
        directory: $DATA + "/plugins",
        options: {
          frozen: true,
          merged: false,
        },
      },
    ) as Plugin[];

    // Configure each plugin
    for (const plugin of plugins) {
      // dpp-exts to be loaded when dpp is sourced
      if (plugin.name.startsWith("dpp-ext-")) {
        Object.assign(plugin, { on_source: "dpp" });
      }
      // plugin-specific hooks
      for (const [key, file] of HOOK_FILE_ENTRIES) {
        try {
          const content = await Deno.readTextFile(
            $CONFIG + "/rc/" + plugin.name + "/" + file,
          );
          Object.assign(plugin, { [key]: content });
        } catch (e) {
          assertInstanceOf(e, Deno.errors.NotFound);
        }
      }
    }

    const result = await dpp.extAction(
      denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult;

    return {
      plugins: result.plugins,
      stateLines: result.stateLines,
    } satisfies ConfigReturn;
  }
}
