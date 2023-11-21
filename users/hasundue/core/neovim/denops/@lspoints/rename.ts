// Ref: https://github.com/uga-rosa/dotfiles/blob/main/nvim/denops/%40lspoints/rename.ts
import { BaseExtension, Lspoints } from "../lib/lspoints.ts";
import { Denops, lambda, vim } from "../lib/denops.ts";
import {
  applyWorkspaceEdit,
  LSP,
  makePositionParams,
  OffsetEncoding,
} from "../lib/lsp.ts";
import { assert, is } from "../lib/unknownutil.ts";

export class Extension extends BaseExtension {
  initialize(denops: Denops, lspoints: Lspoints) {
    lspoints.defineCommands("rename", {
      execute: async () => {
        const clients = lspoints.getClients(await vim.bufnr(denops))
          .filter((c) => c.serverCapabilities.hoverProvider !== undefined);
        if (clients.length !== 1) {
          return;
        }
        const offsetEncoding = clients[0]?.serverCapabilities
          .positionEncoding as OffsetEncoding;
        const positionParams = await makePositionParams(
          denops,
          0,
          0,
          offsetEncoding,
        );

        const inputParams = {
          prompt: "Rename: ",
          default: "",
        };

        try {
          const result = await lspoints.request(
            clients[0].name,
            "textDocument/prepareRename",
            positionParams,
          ) as
            | LSP.Range
            | { range: LSP.Range; placeholder: string }
            | { defaultBehavior: boolean }
            | null;

          if (result === null) {
            await denops.call(
              "luaeval",
              `vim.notify("No symbol under cursor")`,
            );
            return;
          } else if ("placeholder" in result) {
            inputParams.default = result.placeholder;
          }
        } catch {
          // throw
        }

        const id = lambda.register(denops, async (input: unknown) => {
          assert(input, is.String);
          const result = await lspoints.request(
            clients[0].name,
            "textDocument/rename",
            {
              ...positionParams,
              newName: input,
            },
          ) as LSP.WorkspaceEdit | null;
          if (result !== null) {
            await applyWorkspaceEdit(denops, result, offsetEncoding);
          }
        });

        await denops.call(
          "luaeval",
          `vim.ui.input(_A, function(input) vim.fn["denops#notify"]("${denops.name}", "${id}", { input }) end)`,
          inputParams,
        );
      },
    });
  }
}
