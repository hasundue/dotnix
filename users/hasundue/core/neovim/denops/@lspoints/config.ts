import { Denops } from "https://deno.land/x/lspoints@v0.0.4/deps/denops.ts";
import {
  BaseExtension,
  Lspoints,
} from "https://deno.land/x/lspoints@v0.0.4/interface.ts";

export class Extension extends BaseExtension {
  override initialize(_denops: Denops, lspoints: Lspoints) {
    lspoints.settings.patch({
      startOptions: {
        denols: {
          cmd: ["deno", "lsp"],
          initializationOptions: {
            enable: true,
            lint: true,
            unstable: true,
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
            inlayHints: {
              enumMemberValues: {
                enabled: true,
              },
              functionLikeReturnTypes: {
                enabled: true,
              },
              parameterNames: {
                enabled: "all",
              },
              parameterTypes: {
                enabled: true,
              },
              variableTypes: {
                enabled: true,
              },
              propertyDeclarationTypes: {
                enabled: true,
              },
              enabled: "on",
            },
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
