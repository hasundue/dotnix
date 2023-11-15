import { assertInstanceOf } from "https://deno.land/std@0.206.0/assert/assert_instance_of.ts";
import { walk } from "https://deno.land/std@0.206.0/fs/walk.ts";
import {
  BaseConfig,
  ConfigReturn,
  ContextBuilder,
  Dpp,
  Plugin,
} from "https://deno.land/x/dpp_vim@v0.0.7/types.ts";
import { Denops } from "https://deno.land/x/dpp_vim@v0.0.7/deps.ts";
import { HOOK_FILE_ENTRIES } from "./hooks.ts";

type LazyMakeStateResult = {
  plugins: Plugin[];
  stateLines: string[];
};

const FILETYPES_LSP_ENABLED = [
  "lua",
  "nix",
  "typescript",
] as const;

const PLUGIN_CONFIG_MAP = {
  copilot: {
    on_event: "CursorHold",
  },
  dpp: {
    rtp: "",
  },
  "dpp-ext-lazy": {
    rtp: "",
  },
  kanagawa: {
    lazy: false,
  },
  lspoints: {
    depends: "denops",
    on_ft: FILETYPES_LSP_ENABLED,
  },
  "lspoints-hover": {
    on_source: "lspoints",
  },
} as const;

export class Config extends BaseConfig {
  override async config(args: {
    denops: Denops;
    contextBuilder: ContextBuilder;
    basePath: string;
    dpp: Dpp;
  }) {
    const { denops, dpp } = args;

    const [context, options] = await args.contextBuilder.get(denops);

    const $CONFIG = await denops.call("stdpath", "config") as string;
    const $DATA = await denops.call("stdpath", "data") as string;

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
        Object.assign(plugin, { depends: "dpp", on_source: "dpp" });
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
      // plugin-specific config
      if (plugin.name in PLUGIN_CONFIG_MAP) {
        // @ts-ignore: TS7053
        Object.assign(plugin, PLUGIN_CONFIG_MAP[plugin.name]);
      }
    }

    // Create a state with dpp-ext-lazy
    const makeStateResult = await dpp.extAction(
      denops,
      context,
      options,
      "lazy",
      "makeState",
      { plugins },
    ) as LazyMakeStateResult;

    // Create a list of files to check
    // TODO: use Array.fromAsync when it's available
    const checkFiles: string[] = [];
    for await (const entry of walk($CONFIG + "/rc")) {
      if (entry.isFile) {
        checkFiles.push(entry.path);
      }
    }

    return {
      checkFiles,
      plugins: makeStateResult.plugins,
      stateLines: makeStateResult.stateLines,
    } satisfies ConfigReturn;
  }
}
