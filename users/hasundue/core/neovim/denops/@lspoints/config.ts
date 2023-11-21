import { dirname, join } from "../lib/std.ts";
import { Denops, fn } from "../lib/denops.ts";
import { BaseExtension, Lspoints } from "../lib/lspoints.ts";

export class Extension extends BaseExtension {
  override async initialize(denops: Denops, lspoints: Lspoints) {
    const importMap = await findFileUp(
      ["deno.json", "deno.jsonc"],
      await fn.getcwd(denops),
    );
    lspoints.settings.patch({
      startOptions: {
        denols: {
          cmd: ["deno", "lsp", "--unstable"],
          initializationOptions: {
            enable: true,
            importMap: importMap,
            suggest: {
              autoImports: true,
              completeFunctionCalls: true,
              names: true,
              paths: true,
              imports: {
                autoDiscover: true,
                hosts: {
                  "https://deno.land": true,
                },
              },
            },
            lint: true,
            unstable: true,
          },
        },
        luals: {
          cmd: ["lua-language-server"],
          params: {
            settings: {
              Lua: {
                diagnostics: {
                  globals: ["vim"],
                },
              },
            },
          },
        },
        nil: {
          cmd: ["nil"],
        },
      },
    });
  }
}

/**
 * Recursively searches for a file with the specified name in parent directories
 * starting from the given entrypoint directory.
 *
 * @param file - The name(s) of the file(s) to search for.
 * @param dir - The starting directory.
 * @returns The first file path found or undefined if no file was found.
 */
async function findFileUp(file: string | string[], dir = Deno.cwd()) {
  for (;;) {
    for await (const dirEntry of Deno.readDir(dir)) {
      if ([file].flat().includes(dirEntry.name)) {
        return join(dir, dirEntry.name);
      }
    }
    const newDir = dirname(dir);
    if (newDir === dir) {
      // reached the system root
      return undefined;
    }
    dir = newDir;
  }
}
