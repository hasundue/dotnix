local util = require("lspconfig.util")

require("core.lsp").setup("denols", {
  cmd = { "deno", "lsp" },
  root_dir = util.root_pattern("deno.lock", "deno.json", "deno.jsonc", "denops"),
  settings = {
    deno = {
      enable = true,
      unstable = true,
    },
    typescript = {
      inlayHints = {
        enabled = "on",
        functionLikeReturnTypes = { enabled = true },
        parameterTypes = { enabled = true },
        variableTypes = { enabled = true },
      },
    },
  },
  single_file_support = true,
})
